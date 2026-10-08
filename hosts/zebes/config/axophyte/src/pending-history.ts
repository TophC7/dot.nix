import { relevant, type HistoryMessage, type Turn } from "./memory";

// A human can arrive after our snapshot but before our Discord reply. Keep that
// unanswered input after the reply in model history, once only, as the current turn.
export function pendingHistory(history: HistoryMessage[], botId: string, answeredThrough?: string): HistoryMessage[] {
  const filtered = relevant(history, botId);
  if (answeredThrough === undefined) return filtered;
  const answered: HistoryMessage[] = [];
  const pending: HistoryMessage[] = [];
  for (const message of filtered) {
    if (message.authorId !== botId && BigInt(message.id) > BigInt(answeredThrough)) pending.push(message);
    else answered.push(message);
  }
  return [...answered, ...pending];
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
