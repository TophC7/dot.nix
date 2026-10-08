import { limits } from "../limits";
import type { ChatMessage } from "../llm/protocol";
import { ModelError, promptBudget } from "../llm/model";
import type { ModelChoice } from "../llm/model";
import type { Turn } from "./history";
import type { Memory } from "../memory/store";

export class CompactionError extends Error {}


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
  if (promptTokens <= budget) return { memory, turns, messages, promptTokens, compacted: false };
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
    compacted: true,
  };
}

// summary_until is a Discord snowflake, not a logical-history position. Folding
// a newer assistant past an older pending human would discard that human on fetch.
export function safeFoldCuts(turns: Turn[]): number[] {
  const suffixMinimum: bigint[] = [];
  let minimum: bigint | undefined;
  for (let index = turns.length - 1; index >= 0; index--) {
    for (const message of turns[index]!.messages) {
      const id = BigInt(message.id);
      if (minimum === undefined || id < minimum) minimum = id;
    }
    suffixMinimum[index] = minimum!;
  }
  const cuts: number[] = [];
  let maximum: bigint | undefined;
  for (let index = 0; index < turns.length - 1; index++) {
    for (const message of turns[index]!.messages) {
      const id = BigInt(message.id);
      if (maximum === undefined || id > maximum) maximum = id;
    }
    if (maximum !== undefined && maximum < suffixMinimum[index + 1]!) cuts.push(index + 1);
  }
  return cuts;
}
