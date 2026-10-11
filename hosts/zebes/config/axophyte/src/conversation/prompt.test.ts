import { describe, expect, test } from "bun:test";
import { ChannelType, type Guild, type GuildTextBasedChannel } from "discord.js";
import { render, systemPrompt } from "./prompt";
import type { HistoryMessage, Turn } from "./history";

function mockChannel(fields: {
  name: string;
  isThread: boolean;
  parent?: { name: string; type: ChannelType } | null;
}): GuildTextBasedChannel {
  const guild = {
    client: { application: { emojis: { cache: new Map() } } },
    emojis: { cache: new Map() },
  } as unknown as Guild;
  return {
    id: "channel-1",
    name: fields.name,
    guild,
    isThread: () => fields.isThread,
    parent: fields.parent ?? null,
  } as unknown as GuildTextBasedChannel;
}

describe("prompt location format", () => {
  test("distinguishes forum posts, threads, and text channels", () => {
    const forumChannel = mockChannel({ name: "my-post", isThread: true });
    const forumPrompt = systemPrompt({
      source: { channel: forumChannel, forum: true, thread: false, triggers: new Set() },
      summary: "",
      people: "",
      emojiNotes: new Map(),
    });
    expect(forumPrompt.content).toContain("You are in a Discord forum post.");

    const threadChannel = mockChannel({
      name: "axo-help",
      isThread: true,
      parent: { name: "general", type: ChannelType.GuildText },
    });
    const threadPrompt = systemPrompt({
      source: { channel: threadChannel, forum: false, thread: true, triggers: new Set() },
      summary: "",
      people: "",
      emojiNotes: new Map(),
    });
    expect(threadPrompt.content).toContain('You are in a Discord thread ("axo-help") in #general.');

    const regularChannel = mockChannel({ name: "general", isThread: false });
    const regularPrompt = systemPrompt({
      source: { channel: regularChannel, forum: false, thread: false, triggers: new Set() },
      summary: "",
      people: "",
      emojiNotes: new Map(),
    });
    expect(regularPrompt.content).toContain("You are in #general.");
  });

  test("renders thread starter title correctly", () => {
    const threadChannel = mockChannel({
      name: "axo-help",
      isThread: true,
      parent: { name: "general", type: ChannelType.GuildText },
    });
    const turns: Turn[] = [
      {
        messages: [
          {
            id: "channel-1", // starter message matches channel id
            authorId: "user-1",
            authorName: "User",
            authorHandle: "user",
            authorIsBot: false,
            webhookId: null,
            system: false,
            createdAt: 1000,
            reactions: [],
            content: "Can you help?",
            attachments: [],
            replyTo: null,
          } as HistoryMessage,
        ],
      },
    ];
    const messages = render(turns, threadChannel, "bot-1", new Map());
    expect(messages[0]?.content).toContain("[Thread title: axo-help]");
  });
});
