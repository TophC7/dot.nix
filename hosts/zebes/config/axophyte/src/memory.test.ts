import { describe, expect, test } from "bun:test";
import { groupTurns, lastIsAssistant, relevant, type HistoryMessage } from "./memory";

function message(id: string, fields: Partial<HistoryMessage> = {}): HistoryMessage {
  return {
    id,
    authorId: "human",
    authorName: "Human",
    authorIsBot: false,
    webhookId: null,
    system: false,
    content: "Hello",
    attachments: [],
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

  test("ignored messages never create boundaries", () => {
    const history = [
      message("1"),
      message("2", { ...assistant, content: "⏳ Waiting" }),
      message("3", { authorId: "other-bot", authorIsBot: true }),
      message("4"),
      message("5", assistant),
    ];
    expect(groupTurns(history, "axophyte")[0]?.messages.map((m) => m.id)).toEqual([
      "1", "4", "5",
    ]);
  });

  test("lastIsAssistant uses last relevant message, including empty history", () => {
    expect(lastIsAssistant([], "axophyte")).toBe(false);
    expect(lastIsAssistant([message("1")], "axophyte")).toBe(false);
    expect(lastIsAssistant([message("1"), message("2", assistant)], "axophyte")).toBe(true);
    expect(
      lastIsAssistant([
        message("1", assistant),
        message("2", { ...assistant, content: "⏳ Waiting" }),
      ], "axophyte"),
    ).toBe(true);
    expect(lastIsAssistant([message("1", assistant), message("2")], "axophyte")).toBe(false);
    expect(groupTurns([], "axophyte")).toEqual([]);
  });
});
