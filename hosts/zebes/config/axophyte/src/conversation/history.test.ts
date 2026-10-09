import { describe, expect, test } from "bun:test";
import { groupTurns, relevant } from "./history";
import type { HistoryMessage } from "./history";

function message(id: string, fields: Partial<HistoryMessage> = {}): HistoryMessage {
  return {
    id,
    authorId: "human",
    authorName: "Human",
    authorHandle: "human",
    authorIsBot: false,
    webhookId: null,
    system: false,
    createdAt: 0,
    reactions: [],
    content: "Hello",
    attachments: [],
    replyTo: null,
    ...fields,
  };
}

const assistant = { authorId: "axophyte", authorIsBot: true, authorName: "Axophyte" };

describe("conversation memory", () => {
  test("filters statuses, other bots, webhooks and system messages, not human warnings", () => {
    const history = [
      message("1"),
      message("2", { ...assistant, content: "An answer" }),
      message("3", { ...assistant, content: "⚠️ Server unavailable" }),
      message("5", { ...assistant, content: "⏳ Waiting" }),
      message("6", { authorId: "other-bot", authorIsBot: true }),
      message("7", { webhookId: "webhook" }),
      message("8", { system: true }),
      message("9", { content: "⚠️ Please be careful" }),
    ];
    expect(relevant(history, "axophyte").map((m) => m.id)).toEqual(["1", "2", "9"]);
  });

  test("consecutive human messages share a turn and consecutive answers attach to it", () => {
    const history = [
      message("1"),
      message("2", { authorId: "another-human" }),
      message("3", assistant),
      message("4", assistant),
      message("5"),
      message("6", { authorId: "another-human" }),
    ];
    const turns = groupTurns(history, "axophyte");
    expect(turns.map((turn) => turn.messages.map((m) => m.id))).toEqual([
      ["1", "2", "3", "4"],
      ["5", "6"],
    ]);
    expect(turns.at(-1)?.messages.map((m) => m.id)).toEqual(["5", "6"]);
  });
});
