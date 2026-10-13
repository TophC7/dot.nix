import { afterEach, describe, expect, test, jest } from "bun:test";
import { Collection } from "discord.js";
import type { Message, GuildTextBasedChannel } from "discord.js";
import { EDIT_INTERVAL_MS, ReplyStream, splitMessage, STATUS_NOTICE_MS, TYPING_INTERVAL_MS } from "./reply";

afterEach(() => { jest.useRealTimers(); });

test("stream failure drains serialized writes without losing buffered chunks or pinging", async () => {
  jest.useFakeTimers();
  const sent: { content: string; allowedMentions: unknown; reply?: unknown }[] = [];
  let active = 0;
  let maximumActive = 0;
  const opened = Promise.withResolvers<void>();
  const release = Promise.withResolvers<void>();
  const thread = {
    guild: { client: { application: null }, emojis: { cache: new Collection() } },
    async sendTyping() {},
    async send(options: { content: string; allowedMentions: unknown; reply?: unknown }) {
      active++;
      maximumActive = Math.max(maximumActive, active);
      if (!sent.length) { opened.resolve(); await release.promise; }
      const entry = { ...options };
      sent.push(entry);
      active--;
      return {
        async edit(update: { content: string; allowedMentions: unknown }) {
          active++;
          maximumActive = Math.max(maximumActive, active);
          await Promise.resolve();
          Object.assign(entry, update);
          active--;
        },
      };
    },
  } as unknown as GuildTextBasedChannel;
  const stream = new ReplyStream(thread, { id: "original" } as Message);
  stream.push("first");
  jest.advanceTimersByTime(1);
  await opened.promise;
  stream.push("x".repeat(4500));
  const failed = stream.fail("⚠️ Response interrupted.");
  jest.setSystemTime(Date.now() + EDIT_INTERVAL_MS);
  release.resolve();
  await failed;
  expect(maximumActive).toBe(1);
  expect(sent.every((message) => message.content.length <= 1900)).toBe(true);
  expect(sent.map((message) => message.content).join("")).toBe(`first${"x".repeat(4500)}\n\n⚠️ Response interrupted.`);
  expect(sent[0]!.reply).toEqual({ messageReference: "original", failIfNotExists: false });
  expect(sent.slice(1).every((message) => message.reply === undefined)).toBe(true);
  expect(sent.every((message) => JSON.stringify(message.allowedMentions) === '{"parse":[],"repliedUser":false}')).toBe(true);
});

test("stream write rejection finishes and clears timers", async () => {
  jest.useFakeTimers();
  let attempts = 0;
  const thread = {
    guild: { client: { application: null }, emojis: { cache: new Collection() } },
    async sendTyping() {},
    async send() { attempts++; throw new Error("Discord unavailable"); },
  } as unknown as GuildTextBasedChannel;
  const stream = new ReplyStream(thread);
  stream.push("answer");
  await expect(stream.finish([])).rejects.toThrow("Discord unavailable");
  stream.push("ignored after finish");
  jest.advanceTimersByTime(STATUS_NOTICE_MS + TYPING_INTERVAL_MS);
  expect(attempts).toBe(1);
});

test("stream finish normalizes text and splits Axophyte's own trailing emoji into second message", async () => {
  const sent: string[] = [];
  const own = new Collection();
  own.set("101", {
    id: "101",
    name: "weyyy",
    available: true,
    toString: () => "<:weyyy:101>",
  });
  const thread = {
    guild: { client: { application: { emojis: { cache: own } } }, emojis: { cache: new Collection() } },
    async sendTyping() {},
    async send(options: { content: string }) { sent.push(options.content); return { id: String(sent.length), edit: async () => {} }; },
  } as unknown as GuildTextBasedChannel;
  const stream = new ReplyStream(thread);
  stream.push("court is open — live – right now :weyyy");
  await stream.finish([]);
  expect(sent).toEqual(["court is open - live - right now", "<:weyyy:101>"]);
});

// A regression leaves the draft image on a reply, or drops the finished drawing (or parks it on the emoji message).
test("text replacing a draft preview clears it, and final files land with the footer", async () => {
  jest.useFakeTimers();
  type Write = { index: number; content: string; files?: unknown; attachments?: unknown };
  const writes: Write[] = [];
  const noticeSent = Promise.withResolvers<void>();
  let sends = 0;
  const thread = {
    guild: { client: { application: null }, emojis: { cache: new Collection() } },
    async sendTyping() {},
    async send(options: Omit<Write, "index">) {
      const index = sends++;
      writes.push({ index, ...options });
      noticeSent.resolve();
      return { async edit(update: Omit<Write, "index">) { writes.push({ index, ...update }); } };
    },
  } as unknown as GuildTextBasedChannel;
  const draft = { attachment: Buffer.from("draft"), name: "draft.png" };
  const png = { attachment: Buffer.from("png"), name: "art.png" };
  const stream = new ReplyStream(thread);
  stream.preview("touching it up…", draft);
  jest.advanceTimersByTime(STATUS_NOTICE_MS);
  await noticeSent.promise;
  expect(writes[0]).toMatchObject({ index: 0, content: "-# touching it up…", files: [draft] });
  jest.setSystemTime(Date.now() + EDIT_INTERVAL_MS);
  stream.push(`${"a".repeat(2500)} <:weyyy:101>`);
  await stream.finish(["-# f"], [png]);
  const text = writes.filter((write) => write.index === 0 && !write.content.startsWith("-#"));
  expect(text).toHaveLength(1);
  expect(text[0]!.attachments).toEqual([]);
  expect(text[0]!.files).toBeUndefined();
  const footer = writes.find((write) => write.content.endsWith("-# f"))!;
  expect(footer.index).toBe(1);
  expect(footer.files).toEqual([png]);
  const emoji = writes.at(-1)!;
  expect(emoji).toMatchObject({ index: 2, content: "<:weyyy:101>" });
  expect(emoji.files).toBeUndefined();
});

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
  });
});

