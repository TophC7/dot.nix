import { expect, test } from "bun:test";
import { groupTurns, type HistoryMessage } from "./memory";
import { pendingHistory, safeFoldCuts } from "./pending-history";

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
