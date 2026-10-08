import { describe, expect, test } from "bun:test";
import { isConversationMessage, splitMessage } from "./discord-text";

describe("Discord message splitting", () => {
  test("long paragraphs stay within limit and preserve all non-separator text", () => {
    const text = Array.from({ length: 12 }, (_, n) => `Paragraph ${n}: ${"a useful sentence. ".repeat(100)}`).join("\n\n");
    const chunks = splitMessage(text, 1900);
    expect(chunks.length).toBeGreaterThan(1);
    expect(chunks.every((chunk) => chunk.length > 0 && chunk.length <= 1900)).toBe(true);
    expect(chunks.join(" ").replace(/\s+/g, " ").trim()).toBe(text.replace(/\s+/g, " ").trim());
  });

  test("prefers paragraph, then line, then space boundaries", () => {
    expect(splitMessage("alpha\n\nbeta gamma delta", 16)).toEqual(["alpha", "beta gamma delta"]);
    expect(splitMessage("alpha\nbeta gamma delta", 16)).toEqual(["alpha", "beta gamma delta"]);
    expect(splitMessage("alpha beta gamma", 10)).toEqual(["alpha beta", "gamma"]);
  });

  test("hard-splits 5000 characters into three chunks without data loss", () => {
    const text = "x".repeat(5000);
    const chunks = splitMessage(text, 1900);
    expect(chunks.map((chunk) => chunk.length)).toEqual([1900, 1900, 1200]);
    expect(chunks.join("")).toBe(text);
  });

  test("handles empty text and cut-point separators without empty chunks", () => {
    expect(splitMessage("", 10)).toEqual([]);
    expect(splitMessage("12345\n\n67890", 5)).toEqual(["12345", "67890"]);
    expect(splitMessage("\n\nabcdef", 3)).toEqual(["abc", "def"]);
    expect(splitMessage("unchanged\n", 20)).toEqual(["unchanged\n"]);
    expect(() => splitMessage("text", 0)).toThrow(RangeError);
  });
});

describe("conversation message gating", () => {
  const message = {
    guildId: "guild",
    channelId: "thread",
    id: "message",
    parentId: "forum",
    isThread: true,
    authorIsBot: false,
    webhookId: null,
    type: 0,
  };

  test("accepts human default messages and replies inside configured forum", () => {
    expect(isConversationMessage(message, "guild", "forum")).toBe(true);
    expect(isConversationMessage({ ...message, type: 19 }, "guild", "forum")).toBe(true);
  });

  test("rejects bots, webhooks, other channels, starters and system messages", () => {
    const rejected = [
      { authorIsBot: true },
      { webhookId: "webhook" },
      { guildId: "other-guild" },
      { guildId: null },
      { parentId: "other-forum" },
      { parentId: null },
      { isThread: false },
      { id: "thread" },
      { type: 7 },
    ];
    for (const fields of rejected) {
      expect(isConversationMessage({ ...message, ...fields }, "guild", "forum")).toBe(false);
    }
  });
});
