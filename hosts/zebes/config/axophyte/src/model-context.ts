import { limits, promptBudget } from "./limits";
import type { ChatMessage, Turn } from "./memory";
import { safeFoldCuts } from "./pending-history";
import type { Memory } from "./store";

export class ModelError extends Error {
  constructor(public kind: "not_loaded" | "too_long" | "unavailable" | "timeout", message: string) {
    super(message);
    this.name = "ModelError";
  }
}

export type ModelChoice = { id: string; autoload: boolean; contextSize: number };
export type ModelSession = {
  choice: ModelChoice;
  call<T>(operation: (choice: ModelChoice) => Promise<T>): Promise<T>;
};
export class CompactionError extends Error {}

// One retry covers selection, preparation, summarizing, and generation together.
export async function modelSession(pick: () => Promise<ModelChoice>): Promise<ModelSession> {
  let retried = false;
  let choice: ModelChoice;
  try { choice = await pick(); }
  catch (error) {
    if (!(error instanceof ModelError) || error.kind !== "not_loaded") throw error;
    retried = true;
    choice = await pick();
  }
  const session: ModelSession = {
    choice,
    async call<T>(operation: (choice: ModelChoice) => Promise<T>): Promise<T> {
      try { return await operation(session.choice); }
      catch (error) {
        if (!(error instanceof ModelError) || error.kind !== "not_loaded" || retried) throw error;
        retried = true;
        session.choice = await pick();
        return operation(session.choice);
      }
    },
  };
  return session;
}

// Discord rendering and model I/O stay outside this transactional memory operation.
export async function prepareContext(input: {
  choice: ModelChoice;
  memory: Memory | null;
  turns: Turn[];
  tools?: unknown[];
  prompt: (summary: string, turns: Turn[]) => ChatMessage[];
  summaryPrompt: (summary: string, turns: Turn[]) => ChatMessage[];
  count: (messages: ChatMessage[], tools?: unknown[]) => Promise<number>;
  complete: (messages: ChatMessage[]) => Promise<string>;
  save: (memory: Memory) => void;
}) {
  const { choice, memory, turns, tools, prompt, summaryPrompt, count, complete, save } = input;
  const budget = promptBudget(choice.contextSize);
  const messages = prompt(memory?.summary ?? "", turns);
  const promptTokens = await count(messages, tools);
  if (promptTokens <= budget) return { memory, turns, messages, promptTokens, folded: 0 };
  if (await count(prompt("", turns.slice(-1)), tools) > budget) {
    throw new ModelError("too_long", "current turn exceeds model context");
  }

  const cuts = safeFoldCuts(turns);
  if (!cuts.length) throw new CompactionError();
  let cut = cuts.at(-1)!;
  for (const candidate of cuts) {
    if (await count(prompt(memory?.summary ?? "", turns.slice(candidate)), tools) <= budget / 2 - 1536) {
      cut = candidate;
      break;
    }
  }

  const summaryBudget = promptBudget(choice.contextSize, limits.summaryMaxTokens);
  let summary = memory?.summary ?? "";
  let start = 0;
  while (start < cut) {
    let end = cut;
    let request = summaryPrompt(summary, turns.slice(start, end));
    if (await count(request) > summaryBudget) {
      // A smaller replacement model may need several complete-turn batches.
      end = start;
      for (let candidate = start + 1; candidate <= cut; candidate++) {
        const batch = summaryPrompt(summary, turns.slice(start, candidate));
        if (await count(batch) > summaryBudget) break;
        end = candidate;
        request = batch;
      }
      if (end === start) throw new CompactionError();
    }
    summary = (await complete(request)).trim();
    if (!summary || summary.length > limits.maxSummaryChars) throw new CompactionError();
    start = end;
  }

  const remaining = turns.slice(cut);
  const rebuilt = prompt(summary, remaining);
  const rebuiltTokens = await count(rebuilt, tools);
  if (rebuiltTokens > budget) throw new CompactionError();
  const updated = { summary, summaryUntil: turns[cut - 1]!.messages.at(-1)!.id };
  // No batch writes: failed summaries/counts leave the old checkpoint intact.
  save(updated);
  return {
    memory: updated, turns: remaining, messages: rebuilt, promptTokens: rebuiltTokens,
    folded: turns.slice(0, cut).reduce((total, turn) => total + turn.messages.length, 0),
  };
}
