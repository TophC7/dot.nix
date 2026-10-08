import { relevant, type HistoryMessage, type Turn } from "./memory";

// The messages that triggered this turn render last, as the current turn, even
// when a later reply (an earlier burst's answer, a /search) was posted after them.
export function pendingHistory(history: HistoryMessage[], botId: string, pending: Set<string>): HistoryMessage[] {
  const filtered = relevant(history, botId);
  return [...filtered.filter((message) => !pending.has(message.id)), ...filtered.filter((message) => pending.has(message.id))];
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
