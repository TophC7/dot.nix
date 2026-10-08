import { expect, test } from "bun:test";
import { limits } from "../limits";
import type { ChatMessage } from "../llm/protocol";
import { ModelError, modelSession, promptBudget } from "../llm/model";
import type { ModelChoice } from "../llm/model";
import { groupTurns, pendingHistory } from "./history";
import type { HistoryMessage, Turn } from "./history";
import { CompactionError, prepareContext, safeFoldCuts } from "./compaction";
import type { Memory } from "../memory/store";

const large: ModelChoice = { id: "large", autoload: false, contextSize: 131072 };
const small: ModelChoice = { id: "small", autoload: false, contextSize: 65536 };
const tools = [{ type: "function", function: { name: "web_search" } }];
const extra: ChatMessage[] = [
  { role: "user", content: "Search requested this turn" },
  { role: "assistant", content: null, tool_calls: [{ id: "search", type: "function", function: { name: "web_search", arguments: "{}" } }] },
  { role: "tool", tool_call_id: "search", content: "Current search result; keep this URL https://example.com" },
];

function turn(id: number, size: number): Turn {
  return { messages: [{
    id: String(id), authorId: "human", authorName: "Human", authorHandle: "human", authorIsBot: false,
    webhookId: null, system: false, content: `turn-${id}: ${"x".repeat(size)}`, attachments: [], replyTo: null,
  }] };
}

// Deterministic token units exercise budgets; no server, environment, or source inspection.
function tokenUnits(messages: ChatMessage[], schema?: unknown[], multiplier = 1) {
  return Math.ceil(messages.reduce((total, message) => total + (typeof message.content === "string" ? message.content.length : 0), 0) * multiplier) + (schema ? 1000 : 0);
}

function conversation() {
  const prior: Memory = { summary: "- prior memory", summaryUntil: "0" };
  let persisted = prior;
  const writes: Memory[] = [];
  const requests: ChatMessage[][] = [];
  const turns = [turn(1, 30000), turn(2, 30000), turn(3, 30000), turn(4, 30000), turn(5, 100)];
  return {
    prior, writes, requests, persisted: () => persisted,
    input: {
      choice: small, memory: prior, turns, tools,
      prompt: (summary: string, retained: Turn[]): ChatMessage[] => [
        { role: "system", content: summary },
        ...retained.flatMap((entry) => entry.messages.map((message): ChatMessage => ({ role: "user", content: message.content }))),
        ...extra,
      ],
      summaryPrompt: (summary: string, folded: Turn[]): ChatMessage[] => [
        { role: "system", content: "Summarize" },
        { role: "user", content: `${summary}\n${folded.flatMap((entry) => entry.messages.map((message) => message.content)).join("\n")}` },
      ],
      count: async (messages: ChatMessage[], schema?: unknown[]) => tokenUnits(messages, schema, 1.1),
      complete: async (messages: ChatMessage[]) => {
        requests.push(messages);
        expect(tokenUnits(messages, undefined, 1.1)).toBeLessThanOrEqual(promptBudget(small.contextSize, limits.summaryMaxTokens));
        expect(persisted).toBe(prior);
        const [memory, ...transcript] = (messages[1]!.content as string).split("\n");
        return `${memory}; ${[...transcript.join("\n").matchAll(/turn-\d+/g)].map((match) => match[0]).join("; ")}`;
      },
      save: (memory: Memory) => { persisted = memory; writes.push(memory); },
    },
  };
}

test("a smaller-model retry re-prepares with its tokenizer, batches memory, and retains current tools", async () => {
  const fixture = conversation();
  let selections = 0;
  const session = await modelSession(async () => ++selections === 1 ? large : small);
  const seen: string[] = [];
  const prepared = await session.call(async (choice) => {
    seen.push(choice.id);
    const result = await prepareContext({
      ...fixture.input, choice,
      count: async (messages, schema) => tokenUnits(messages, schema, choice.id === "large" ? 1 : 1.1),
    });
    if (choice.id === "large") {
      expect(result.compacted).toBe(false);
      expect(fixture.writes).toHaveLength(0);
      throw new ModelError("not_loaded", "switched before generation");
    }
    return result;
  });
  expect(seen).toEqual(["large", "small"]);
  expect(selections).toBe(2);
  expect(fixture.requests).toHaveLength(4);
  expect(fixture.writes).toEqual([prepared.memory!]);
  expect(prepared.memory!.summaryUntil).toBe("4");
  for (const id of [1, 2, 3, 4]) expect(prepared.memory!.summary).toContain(`turn-${id}`);
  expect(prepared.turns).toEqual([fixture.input.turns[4]!]);
  expect(prepared.messages.slice(-extra.length)).toEqual(extra);
  expect(prepared.promptTokens).toBe(tokenUnits(prepared.messages, tools, 1.1));
  expect(prepared.promptTokens).toBeLessThanOrEqual(promptBudget(small.contextSize));
  await expect(session.call(async () => { throw new ModelError("not_loaded", "second switch"); })).rejects.toBeInstanceOf(ModelError);
  expect(selections).toBe(2);
});

test("batch failure or invalid rebuilt prompt never commits any partial memory", async () => {
  for (const failure of ["empty", "oversized", "model", "rebuilt"] as const) {
    const fixture = conversation();
    let batches = 0;
    await expect(prepareContext({
      ...fixture.input,
      complete: async (messages) => {
        batches++;
        if (batches === 2) {
          if (failure === "empty") return " ";
          if (failure === "oversized") return "x".repeat(limits.maxSummaryChars + 1);
          if (failure === "model") throw new ModelError("not_loaded", "switched during summary");
        }
        return fixture.input.complete(messages);
      },
      count: async (messages, schema) => failure === "rebuilt" && batches === 4 && schema
        ? promptBudget(small.contextSize) + 1
        : fixture.input.count(messages, schema),
    })).rejects.toBeInstanceOf(failure === "model" ? ModelError : CompactionError);
    expect(fixture.writes).toHaveLength(0);
    expect(fixture.persisted()).toBe(fixture.prior);
  }
});

test("unsummarizable older turn and unsafe pending-human boundary leave memory intact", async () => {
  for (const turns of [[turn(1, 60000), turn(2, 100)], [turn(6, 60000), turn(5, 100)]]) {
    const fixture = conversation();
    await expect(prepareContext({ ...fixture.input, turns })).rejects.toBeInstanceOf(CompactionError);
    expect(fixture.requests).toHaveLength(0);
    expect(fixture.writes).toHaveLength(0);
    expect(fixture.persisted()).toBe(fixture.prior);
  }
});

test("current-turn boundary includes tools and reserves answer output exactly", async () => {
  const fixture = conversation();
  const budget = promptBudget(small.contextSize);
  // Empty summary, fixed current-tool content, and tool schema all consume context.
  const overhead = tokenUnits(fixture.input.prompt("", [turn(1, 0)]), tools);
  const atLimit = turn(1, budget - overhead);
  const prepared = await prepareContext({
    ...fixture.input, memory: null, turns: [atLimit],
    count: async (messages, schema) => tokenUnits(messages, schema),
  });
  expect(prepared.promptTokens).toBe(budget);
  await expect(prepareContext({
    ...fixture.input, memory: null, turns: [turn(1, budget - overhead + 1)],
    count: async (messages, schema) => tokenUnits(messages, schema),
  })).rejects.toMatchObject({ kind: "too_long" });
  expect(fixture.writes).toHaveLength(0);
});

test("not-loaded during summary retries whole preparation without committing a batch", async () => {
  const fixture = conversation();
  const turns = [...fixture.input.turns.slice(0, 4), turn(5, 30000), turn(6, 100)];
  let picks = 0;
  const session = await modelSession(async () => ++picks === 1 ? large : small);
  const result = await session.call(async (choice) => prepareContext({
    ...fixture.input, choice, turns,
    count: async (messages, schema) => tokenUnits(messages, schema),
    complete: async (messages) => {
      if (choice.id === "large") {
        expect(fixture.writes).toHaveLength(0);
        throw new ModelError("not_loaded", "switched while summarizing");
      }
      return fixture.input.complete(messages);
    },
  }));
  expect(picks).toBe(2);
  expect(fixture.requests).toHaveLength(5);
  expect(fixture.writes).toEqual([result.memory!]);
  expect(result.memory!.summaryUntil).toBe("5");
  expect(result.turns).toEqual([turns.at(-1)!]);
  expect(result.messages.slice(-extra.length)).toEqual(extra);
});

function message(id: string, bot = false): HistoryMessage {
  return {
    id, authorId: bot ? "bot" : "human", authorName: bot ? "Axophyte" : "Human", authorHandle: "human",
    authorIsBot: bot, webhookId: null, system: false, content: `message ${id}`, attachments: [], replyTo: null,
  };
}

// A trigger posted before a later reply (a streaming answer, a /search) is still this turn's question.
test("triggers become the current turn even when a reply was posted after them", () => {
  const history = [message("1"), message("2", true), message("3"), message("4"), message("5", true)];
  const prepared = pendingHistory(history, "bot", new Set(["4"]));
  expect(prepared.map((entry) => entry.id)).toEqual(["1", "2", "3", "5", "4"]);
  const turns = groupTurns(prepared, "bot");
  expect(turns.at(-1)!.messages.map((entry) => entry.id)).toEqual(["4"]);
  // Folding through the newer reply at 5 would erase the pending human at 4.
  expect(safeFoldCuts(turns)).toEqual([1]);
});
