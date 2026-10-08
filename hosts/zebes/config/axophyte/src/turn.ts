import { ChannelType } from "discord.js";
import { config } from "./config";
import { load } from "./conversation/load";
import type { Source } from "./conversation/load";
import { render, summaryRequest, systemPrompt } from "./conversation/prompt";
import { ReplyStream } from "./discord/reply";
import { limits } from "./limits";
import { complete, countTokens, requestModel, streamChat } from "./llm/llama";
import type { ChatMessage, ToolCall } from "./llm/protocol";
import { ModelError, TurnAborted, modelSession } from "./llm/model";
import type { ModelSession } from "./llm/model";
import { CompactionError, prepareContext } from "./conversation/compaction";
import { noteTools, peopleSection, prunePerson } from "./memory/people";
import { serverTools } from "./tools/server";
import type { People, Store } from "./memory/store";
import { runToolCall, toolError } from "./tools/tool";
import type { Tool } from "./tools/tool";
import { isPublic } from "./discord/visibility";
import { openUrlTool, webSearchTool } from "./tools/web";

const webSearch = webSearchTool(config.tavilyKey);
const webTools: Tool[] = [webSearch, openUrlTool(config.tavilyKey)];

export type TurnOptions = {
  forcedSearch?: { query: string; requester: string };
  signal: AbortSignal;
  /** Called on the first model output or memory write; after that a turn is never aborted. */
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
      ...webTools,
      ...(serverSearch ? serverTools(channel, store, new Set(loaded.turns.flatMap((turn) => turn.messages.map((message) => message.id)))) : []),
      ...(memoryEnabled ? noteTools(serverPeople, loaded.latest, (id) => { touched.add(id); opts.onCommit?.(); }) : []),
    ];
    const people = peopleSection(serverPeople, loaded.people);
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
          prompt: (summary, retained) => [systemPrompt({ source, summary, people }), ...render(retained, channel, botId, loaded.images), ...extra],
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
          if (delta && !hadOutput) {
            hadOutput = true;
            opts.onCommit?.();
          }
          reply!.push(delta);
        }, opts.signal);
      });
      if (!result.toolCalls.length) {
        if (!result.content.trim()) {
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
      for (const call of result.toolCalls) {
        if (round < limits.maxToolRounds) await runCall(call, tools);
        else extra.push({ role: "tool", tool_call_id: call.id, content: toolError("no more tool calls for this answer; reply now with what you have").content });
      }
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
