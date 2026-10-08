import { expect, test } from "bun:test";
import { groupTurns, lastIsAssistant, type HistoryMessage } from "./memory";
import { pendingHistory, safeFoldCuts } from "./pending-history";

function message(id: string, bot = false): HistoryMessage {
  return {
    id, authorId: bot ? "bot" : "human", authorName: bot ? "Axophyte" : "Human",
    authorIsBot: bot, webhookId: null, system: false, content: `message ${id}`, attachments: [],
  };
}

test("a human arriving during generation becomes the next current turn, not an answered message", () => {
  const history = [message("1"), message("2", true), message("3"), message("4"), message("5", true)];
  // The reply at 5 used a snapshot ending at 3, not the human arriving at 4.
  const prepared = pendingHistory(history, "bot", "3");
  expect(prepared.map((entry) => entry.id)).toEqual(["1", "2", "3", "5", "4"]);
  expect(new Set(prepared.map((entry) => entry.id)).size).toBe(history.length);
  expect(lastIsAssistant(prepared, "bot")).toBe(false);
  const turns = groupTurns(prepared, "bot");
  expect(turns.at(-1)!.messages.map((entry) => entry.id)).toEqual(["4"]);
  // Folding through the newer reply at 5 would erase the pending human at 4.
  expect(safeFoldCuts(turns)).toEqual([1]);
  const cutoff = turns[0]!.messages.at(-1)!.id;
  expect(BigInt(cutoff)).toBeLessThan(4n);
});

test("pending humans remain one turn and cannot be crossed by a summary checkpoint", () => {
  const history = [message("10"), message("11"), message("12"), message("13", true)];
  const prepared = pendingHistory(history, "bot", "10");
  const turns = groupTurns(prepared, "bot");
  expect(turns.at(-1)!.messages.map((entry) => entry.id)).toEqual(["11", "12"]);
  expect(safeFoldCuts(turns)).toEqual([]);
  // Only a successfully completed later answer advances the supplied watermark.
  const answered = pendingHistory([...history, message("14", true)], "bot", "12");
  expect(lastIsAssistant(answered, "bot")).toBe(true);
  expect(answered.map((entry) => entry.id)).toEqual(["10", "11", "12", "13", "14"]);
});

test("without an in-process watermark existing answered history is not replayed", () => {
  const history = [message("10"), message("11"), message("12", true)];
  const prepared = pendingHistory(history, "bot");
  expect(prepared).toEqual(history);
  expect(lastIsAssistant(prepared, "bot")).toBe(true);
});
