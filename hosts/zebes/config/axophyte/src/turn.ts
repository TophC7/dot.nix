import { ChannelType } from "discord.js";
import { throwIfAborted, TurnAborted } from "./abort";
import { config } from "./config";
import { load } from "./conversation/load";
import type { Source } from "./conversation/load";
import { render, summaryRequest, systemPrompt } from "./conversation/prompt";
import { ReplyStream } from "./discord/reply";
import type { ReplyFile } from "./discord/reply";
import { currentModel } from "./llm/client";
import type { ChatMessage, ToolCall } from "./llm/protocol";
import { MAX_OUTPUT_TOKENS, ModelError, modelSession } from "./llm/model";
import type { ModelSession } from "./llm/model";
import { CompactionError, prepareContext, SUMMARY_MAX_TOKENS } from "./conversation/compaction";
import { emojiNotesFor } from "./memory/emoji";
import { peopleSection } from "./memory/people";
import { noteTools } from "./tools/notes";
import { serverTools } from "./tools/server";
import { drawTool } from "./tools/draw";
import type { Store } from "./memory/store";
import { runToolCall, toolError } from "./tools/tool";
import type { Tool } from "./tools/tool";
import { isPublic } from "./discord/visibility";
import { openUrlTool, webSearchTool } from "./tools/web";
import { reactTool } from "./tools/react";
import { selfInfoTool } from "./tools/self";

const MAX_TOOL_ROUNDS = 6;
/** Rounds after MAX_TOOL_ROUNDS whose tool calls are refused, prompting a plain answer. */
const ANSWER_RETRIES = 2;
const ART_MAX_TOKENS = 8192;

const webTools: Tool[] = [webSearchTool(config.tavilyKey), openUrlTool(config.tavilyKey)];
/** Tools whose results the model never needs to read before replying. */
const ACTIONS: Record<string, true> = { react: true, remember: true, revise: true };
/** Status notices for the reply slot, shown after STATUS_NOTICE_MS without text. */
const THINKING = "💭 thinking…";
const COMPACTING = "🗜️ catching up on older messages…";

type TurnOptions = {
  signal: AbortSignal;
  /** Called on the first model output, memory write, or reaction; after that a turn is never aborted. */
  onCommit(): void;
};

const MODEL_FAILURES: Record<ModelError["kind"], string> = {
  unavailable: "⚠️ The selected model is unavailable right now. Try again in a bit or ask an admin to check its credentials.",
  not_loaded: "⚠️ The model server is unreachable right now. Try again in a bit.",
  timeout: "⚠️ The model took too long to respond. Try again later.",
  too_long: "⚠️ That message (with its attachments) is too large for my context. Try shorter text or fewer/smaller attachments.",
};

function failure(error: unknown): { kind: string; text: string } {
  if (error instanceof CompactionError) {
    return { kind: "compaction", text: "⚠️ I couldn't compact this conversation's memory. Start a new post for a new conversation." };
  }
  if (error instanceof ModelError) return { kind: error.kind, text: MODEL_FAILURES[error.kind] };
  return { kind: "internal", text: "⚠️ I couldn't finish this response. Try again later." };
}

/** Returns user IDs whose notes changed, for pruning after the reply. */
export async function runTurn(store: Store, source: Source, opts: TurnOptions): Promise<string[]> {
  const channel = source.channel;
  // Every inference operation in this turn uses this snapshot, even after a /model switch.
  const model = currentModel();
  const { signal, onCommit } = opts;
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
  /** Finished tool attachments; kept even when the turn fails afterwards. */
  const files: ReplyFile[] = [];
  const fail = (text: string) => reply!.fail(hadOutput ? "⚠️ Response interrupted." : text, files);
  try {
    throwIfAborted(signal);
    // ponytail: one typing pulse (~10 s) covers media prep; ReplyStream keeps it up afterwards.
    void channel.sendTyping().catch(() => {});
    const loaded = await load(source, store, config.whisperModel, signal);
    if (!loaded) return [];
    const botId = channel.client.user.id;
    // Private threads have no exact audience (moderators can open them), so no cross-channel reads.
    const serverSearch = channel.type !== ChannelType.PrivateThread;
    // Memory is learned only where every member can read it, so it can load anywhere in this server.
    const memoryEnabled = isPublic(channel);
    const serverPeople = store.people(channel.guildId);
    const tools = [
      selfInfoTool(model),
      ...webTools,
      ...(serverSearch ? serverTools(channel, store, new Set(loaded.turns.flat().map((message) => message.id))) : []),
      ...(memoryEnabled ? noteTools(serverPeople, loaded.latest, (id) => { touched.add(id); onCommit(); }) : []),
      reactTool(channel, loaded.latest, onCommit, (reply) => { reactions++; replyAfterReaction ||= reply; }),
      drawTool({
        channelId: channel.id,
        fontsDir: config.svgFonts,
        supportsImages: model.supportsImages,
        complete: (messages) => session!.call(() => model.complete({ messages, max_tokens: ART_MAX_TOKENS }, signal)),
        onCommit,
        preview: (text, file) => reply?.preview(text, file),
      }),
    ];
    const people = peopleSection(serverPeople, loaded.people);
    const emojiNotes = emojiNotesFor(store, channel.guildId);
    session = await modelSession(() => model.requestModel(signal));
    let memory = loaded.memory;
    let turns = loaded.turns;
    const extra: ChatMessage[] = [];
    const footer: string[] = [];
    const runCall = async (call: ToolCall) => {
      const result = await runToolCall(call, tools, used, signal, (text) => reply!.status(text));
      if (result.footer) footer.push(result.footer);
      if (result.files) files.push(...result.files);
      extra.push({ role: "tool", tool_call_id: call.id, content: result.content });
    };
    let compacted = false;
    reply = new ReplyStream(channel, loaded.replyTo);
    // The same tools every round: a tool missing from the schema (or tool_choice "none") gets
    // "called" as plain text the parser can't catch. Budgets and the round limit are enforced
    // with tool errors the model reads, so it answers from what it already found.
    const schemas = tools.map((tool) => tool.schema);
    for (let round = 0; ; round++) {
      reply.status(THINKING);
      const result = await session.call(async (choice) => {
        // Preparation, compaction, and generation share one choice and one retry.
        const prepared = await prepareContext({
          choice, memory, turns, tools: schemas,
          prompt: (summary, retained) => {
            const now = Date.now();
            return [systemPrompt({ source, summary, people, emojiNotes }, now), ...render(retained, channel, botId, loaded.seen, now), ...extra];
          },
          summaryPrompt: (summary, folded) => summaryRequest(summary, folded, botId),
          count: (messages, actualTools) => model.countTokens({ messages, tools: actualTools }, signal),
          complete: (messages) => {
            reply!.status(COMPACTING);
            return model.complete({ messages, max_tokens: SUMMARY_MAX_TOKENS }, signal);
          },
          save: loaded.save,
        });
        memory = prepared.memory;
        turns = prepared.turns;
        compacted ||= prepared.compacted;
        promptTokens = prepared.promptTokens;
        if (prepared.compacted) reply!.status(THINKING);
        return model.streamChat({ messages: prepared.messages, tools: schemas, max_tokens: MAX_OUTPUT_TOKENS }, (delta) => {
          if (!hadOutput && delta.trim()) {
            hadOutput = true;
            onCommit();
          }
          reply!.push(delta);
        }, signal);
      });
      if (!result.toolCalls.length) {
        if (!result.content.trim() && !reactions && !files.length) {
          await fail(result.finishReason === "length"
            ? "⚠️ I ran out of output tokens before answering. Try a narrower question."
            : "⚠️ The model returned no answer. Try again later.");
          return [...touched];
        }
        break;
      }
      if (round >= MAX_TOOL_ROUNDS + ANSWER_RETRIES) {
        await fail("⚠️ The model did not finish its answer. Try a narrower question.");
        return [...touched];
      }
      extra.push({ role: "assistant", content: result.content || null, tool_calls: result.toolCalls, nativeAssistant: result.nativeAssistant });
      const reactionsBefore = reactions;
      replyAfterReaction = false;
      for (const call of result.toolCalls) {
        if (round < MAX_TOOL_ROUNDS) await runCall(call);
        else extra.push({ role: "tool", tool_call_id: call.id, content: toolError("no more tool calls for this answer; reply now with what you have").content });
      }
      // An actions-only round that already wrote text, or reacted as its whole reply, ends the turn:
      // another round only makes the model repeat itself or pad with a lone ".". Lookups are always read first.
      const replied = !!result.content.trim() || (reactions > reactionsBefore && !replyAfterReaction);
      if (replied && result.toolCalls.every((call) => ACTIONS[call.function.name])) break;
    }
    if (compacted) footer.push("-# 🗜️ Older messages were summarized into memory.");
    await reply.finish(footer, files);
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
    console.info(`turn ${channel.id} model=${session ? model.id : "none"} prompt=${promptTokens} tools=${tools} ms=${Date.now() - started}`);
  }
  return [...touched];
}
