import { ChannelType } from "discord.js";
import { config } from "./config";
import { load } from "./conversation/load";
import type { Source } from "./conversation/load";
import { render, summaryRequest, systemPrompt } from "./conversation/prompt";
import { APP_EMOJI_SCOPE, type UsableEmoji } from "./discord/emoji";
import { ReplyStream } from "./discord/reply";
import { limits } from "./limits";
import { complete, countTokens, requestModel, streamChat } from "./llm/llama";
import type { ChatMessage, ToolCall } from "./llm/protocol";
import { ModelError, TurnAborted, modelSession } from "./llm/model";
import type { ModelSession } from "./llm/model";
import { CompactionError, prepareContext } from "./conversation/compaction";
import { noteTools, peopleSection, prunePerson } from "./memory/people";
import { describerMessages, parseDescription } from "./memory/emoji";
import { serverTools } from "./tools/server";
import type { People, Store } from "./memory/store";
import { loadImage } from "./conversation/images";
import { runToolCall, toolError } from "./tools/tool";
import type { Tool } from "./tools/tool";
import { isPublic } from "./discord/visibility";
import { openUrlTool, webSearchTool } from "./tools/web";
import { reactTool } from "./tools/react";
import { selfInfoTool } from "./tools/self";

const webSearch = webSearchTool(config.tavilyKey);
const webTools: Tool[] = [webSearch, openUrlTool(config.tavilyKey)];
/** Tools whose results the model never needs to read before replying. */
const ACTIONS: Record<string, true> = { react: true, remember: true, revise: true };

export type TurnOptions = {
  forcedSearch?: { query: string; requester: string };
  signal: AbortSignal;
  /** Called on the first model output, memory write, or reaction; after that a turn is never aborted. */
  onCommit?(): void;
};

const MODEL_FAILURES: Record<ModelError["kind"], string> = {
  unavailable: "⚠️ The model server is unreachable right now. Try again in a bit.",
  not_loaded: "⚠️ The model server is unreachable right now. Try again in a bit.",
  timeout: "⚠️ The model took too long to respond. Try again later.",
  too_long: "⚠️ That message (with its images) is too large for my context. Try shorter text or fewer/smaller images.",
};

function failure(error: unknown): { kind: string; text: string } {
  if (error instanceof CompactionError) {
    return { kind: "compaction", text: "⚠️ I couldn't compact this conversation's memory. Start a new post for a new conversation." };
  }
  if (error instanceof ModelError) return { kind: error.kind, text: MODEL_FAILURES[error.kind] };
  return { kind: "internal", text: "⚠️ I couldn't finish this response. Try again later." };
}

export async function pruneNotes(people: People, userId: string): Promise<void> {
  await prunePerson(people, userId, async (messages) => {
    const session = await modelSession(requestModel);
    return session.call((choice) => complete(choice, { messages, max_tokens: 2048 }));
  });
}

export async function describeEmoji(emoji: UsableEmoji): Promise<string> {
  const name = emoji.name!;
  const url = emoji.imageURL({ extension: "png", size: 128 });
  // Animated emoji come back as their first frame; a failed fetch still gets a name-only guess.
  const image = await loadImage({ id: emoji.id, url, proxyURL: url, contentType: "image/png", size: 0, width: 128, height: 128 });
  const session = await modelSession(requestModel);
  const text = await session.call((choice) => complete(choice, { messages: describerMessages(name, image), max_tokens: 200 }));
  const description = parseDescription(text);
  if (!description) throw new Error(`empty description for emoji ${emoji.id}`);
  return description;
}

/** Returns user IDs whose notes changed, for pruning after the reply. */
export async function runTurn(store: Store, source: Source, opts: TurnOptions): Promise<string[]> {
  const channel = source.channel;
  if (channel.isThread() && channel.locked) return [];
  const started = Date.now();
  const used = new Map<string, number>();
  const touched = new Set<string>();
  let reply: ReplyStream | undefined;
  let session: ModelSession | undefined;
  let promptTokens = 0;
  let hadOutput = false;
  let reactions = 0;
  /** Set when a reaction in the current round asked to be followed by a message. */
  let replyAfterReaction = false;
  const fail = (text: string) => reply!.fail(hadOutput ? "⚠️ Response interrupted." : text);
  try {
    const loaded = await load(source, store, !!opts.forcedSearch);
    if (!loaded) return [];
    const botId = channel.client.user.id;
    // Private threads have no exact audience (moderators can open them), so no cross-channel reads.
    const serverSearch = channel.type !== ChannelType.PrivateThread;
    // Memory is learned only where every member can read it, so it can load anywhere in this server.
    const memoryEnabled = isPublic(channel);
    const serverPeople = store.people(channel.guildId);
    const tools = [
      selfInfoTool(() => session!.choice.id),
      ...webTools,
      ...(serverSearch ? serverTools(channel, store, new Set(loaded.turns.flatMap((turn) => turn.messages.map((message) => message.id)))) : []),
      ...(memoryEnabled ? noteTools(serverPeople, loaded.latest, (id) => { touched.add(id); opts.onCommit?.(); }) : []),
      ...(loaded.latest.length ? [reactTool(channel, loaded.latest, () => opts.onCommit?.(), (reply) => { reactions++; replyAfterReaction ||= reply; })] : []),
    ];
    const people = peopleSection(serverPeople, loaded.people);
    // Emoji IDs are global snowflakes, so the two scopes never collide.
    const emojiNotes = new Map([...store.emojiNotes(APP_EMOJI_SCOPE).all(), ...store.emojiNotes(channel.guildId).all()]);
    session = await modelSession(() => requestModel(opts.signal));
    let memory = loaded.memory;
    let turns = loaded.turns;
    const extra: ChatMessage[] = [];
    const footer: string[] = [];
    const runCall = async (call: ToolCall, offered: Tool[]) => {
      const result = await runToolCall(call, offered, used, opts.signal);
      if (result.footer) footer.push(result.footer);
      extra.push({ role: "tool", tool_call_id: call.id, content: result.content });
    };
    if (opts.forcedSearch) {
      const { requester, query } = opts.forcedSearch;
      const call: ToolCall = { id: "forced-search", type: "function", function: { name: "web_search", arguments: JSON.stringify({ query }) } };
      extra.push(
        { role: "user", content: `${requester}: Search the web for "${query}" and answer using the results.` },
        { role: "assistant", content: null, tool_calls: [call] },
      );
      await runCall(call, [webSearch]);
    }
    let compacted = false;
    reply = new ReplyStream(channel, loaded.replyTo);
    if (opts.forcedSearch) reply.push(`🔎 **Search:** ${opts.forcedSearch.query}\n\n`);
    // The same tools every round: a tool missing from the schema (or tool_choice "none") gets
    // "called" as plain text the parser can't catch. Budgets and the round limit are enforced
    // with tool errors the model reads, so it answers from what it already found.
    const schemas = tools.map((tool) => tool.schema);
    for (let round = 0; ; round++) {
      const result = await session.call(async (choice) => {
        // Preparation, compaction, and generation share one choice and one retry.
        const prepared = await prepareContext({
          choice, memory, turns, tools: schemas,
          prompt: (summary, retained) => {
            const now = Date.now();
            return [systemPrompt({ source, summary, people, emojiNotes }, now), ...render(retained, channel, botId, loaded.images, now), ...extra];
          },
          summaryPrompt: (summary, folded) => summaryRequest(summary, folded, botId),
          count: (messages, actualTools) => countTokens(choice, { messages, tools: actualTools }, opts.signal),
          complete: (messages) => complete(choice, {
            messages, max_tokens: limits.summaryMaxTokens,
          }, opts.signal),
          save: loaded.save,
        });
        memory = prepared.memory;
        turns = prepared.turns;
        compacted ||= prepared.compacted;
        promptTokens = prepared.promptTokens;
        return streamChat(choice, { messages: prepared.messages, tools: schemas, max_tokens: limits.maxOutputTokens }, (delta) => {
          if (!hadOutput && delta.trim()) {
            hadOutput = true;
            opts.onCommit?.();
          }
          reply!.push(delta);
        }, opts.signal);
      });
      if (!result.toolCalls.length) {
        if (!result.content.trim() && !reactions) {
          await fail(result.finishReason === "length"
            ? "⚠️ I ran out of output tokens before answering. Try a narrower question."
            : "⚠️ The model returned no answer. Try again later.");
          return [...touched];
        }
        break;
      }
      if (round >= limits.maxToolRounds + limits.answerRetries) {
        await fail("⚠️ The model did not finish its answer. Try a narrower question.");
        return [...touched];
      }
      extra.push({ role: "assistant", content: result.content || null, tool_calls: result.toolCalls });
      const reactionsBefore = reactions;
      replyAfterReaction = false;
      for (const call of result.toolCalls) {
        if (round < limits.maxToolRounds) await runCall(call, tools);
        else extra.push({ role: "tool", tool_call_id: call.id, content: toolError("no more tool calls for this answer; reply now with what you have").content });
      }
      // An actions-only round that already wrote text, or reacted as its whole reply, ends the turn:
      // another round only makes the model repeat itself or pad with a lone ".". Lookups are always read first.
      const replied = !!result.content.trim() || (reactions > reactionsBefore && !replyAfterReaction);
      if (replied && result.toolCalls.every((call) => ACTIONS[call.function.name])) break;
    }
    if (compacted) footer.push("-# 🗜️ Older messages were summarized into memory.");
    await reply.finish(footer);
  } catch (error) {
    if (error instanceof TurnAborted) {
      console.info(`turn ${channel.id} aborted`);
      await reply?.cancel();
      return [...touched];
    }
    const { kind, text } = failure(error);
    console.error(`turn ${channel.id} failed kind=${kind}`);
    try {
      reply ??= new ReplyStream(channel);
      await fail(text);
    } catch { console.error(`turn ${channel.id} Discord write failed`); }
  } finally {
    const tools = [...used].map(([name, count]) => `${name}:${count}`).join(",") || "none";
    console.info(`turn ${channel.id} model=${session?.choice.id ?? "none"} prompt=${promptTokens} tools=${tools} ms=${Date.now() - started}`);
  }
  return [...touched];
}
