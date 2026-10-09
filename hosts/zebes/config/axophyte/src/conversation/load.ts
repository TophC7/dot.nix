import { MessageReferenceType } from "discord.js";
import type { GuildTextBasedChannel, Message as DiscordMessage } from "discord.js";
import { limits } from "../limits";
import { groupTurns, label, pendingHistory } from "./history";
import type { HistoryMessage, Speaker, Turn } from "./history";
import { imagesFor } from "./images";
import type { Memory, Store } from "../memory/store";
import { cleanText } from "../discord/visibility";

type Message = DiscordMessage<true>;

/** `triggers` are the IDs of the messages this turn answers; empty for /search. */
export type Source = { channel: GuildTextBasedChannel; forum: boolean; triggers: Set<string> };

export type Loaded = {
  memory: Memory | null;
  save(memory: Memory): void;
  turns: Turn[];
  images: Map<string, string>;
  /** Trigger messages, in order: the only messages whose authors' notes may be written. */
  latest: HistoryMessage[];
  /** Everyone whose notes load: rendered authors plus people they mention. */
  people: Map<string, Speaker>;
  replyTo?: Message;
};

export const byId = (a: { id: string }, b: { id: string }) => a.id === b.id ? 0 : BigInt(a.id) < BigInt(b.id) ? -1 : 1;

export function excerpt(text: string, max: number): string {
  const flat = text.replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max)}…` : flat;
}

// Cross-channel references are never rendered, so replies cannot leak other channels.
export function asHistory(message: Message): HistoryMessage {
  const reference = message.reference;
  // Older payloads omit the reference type; only forwards are excluded.
  const target = reference && reference.type !== MessageReferenceType.Forward && reference.channelId === message.channelId && reference.messageId
    ? message.channel.messages.cache.get(reference.messageId)
    : undefined;
  return {
    id: message.id,
    authorId: message.author.id,
    authorName: message.member?.displayName ?? message.author.displayName,
    authorHandle: message.author.username,
    authorIsBot: message.author.bot,
    webhookId: message.webhookId,
    system: message.system,
    createdAt: message.createdTimestamp,
    reactions: [...message.reactions.cache.values()].map((reaction) => ({
      emoji: reaction.emoji.id ? `:${reaction.emoji.name}:` : reaction.emoji.name ?? "",
      count: reaction.count,
      me: reaction.me,
    })),
    content: cleanText(message.content, message.channel),
    attachments: [...message.attachments.values()].map((attachment) => ({
      id: attachment.id, name: attachment.name, contentType: attachment.contentType,
    })),
    replyTo: target ? {
      id: target.id,
      label: target.author.id === message.client.user.id ? "Axophyte" : label(target.member?.displayName ?? target.author.displayName, target.author.username),
      excerpt: excerpt(cleanText(target.content, message.channel), 100),
    } : null,
  };
}

async function fetchHistory(channel: GuildTextBasedChannel, after: string): Promise<Message[]> {
  const messages: Message[] = [];
  let before: string | undefined;
  while (messages.length < limits.maxHistoryMessages) {
    const page = await channel.messages.fetch({ limit: Math.min(100, limits.maxHistoryMessages - messages.length), before });
    if (!page.size) break;
    const batch = [...page.values()].sort((a, b) => byId(b, a));
    let reachedBoundary = false;
    for (const message of batch) {
      if (BigInt(message.id) <= BigInt(after)) { reachedBoundary = true; break; }
      messages.push(message);
    }
    if (reachedBoundary) break;
    before = batch.at(-1)!.id;
  }
  if (messages.length === limits.maxHistoryMessages) console.warn(`history cap reached for ${channel.id}`);
  return messages.sort(byId);
}

// The triggers, recent messages before them (stale ones dropped), and the reply
// chains the triggers point into, which may be older; same channel only.
async function channelHistory(channel: GuildTextBasedChannel, triggers: Set<string>): Promise<Message[]> {
  const anchors = (await Promise.all([...triggers].map((id) => channel.messages.fetch(id).catch(() => null))))
    .filter((message) => message !== null)
    .sort(byId);
  const found = new Map(anchors.map((message) => [message.id, message]));
  const cutoff = (anchors[0]?.createdTimestamp ?? Date.now()) - limits.channelContextMaxAgeMs;
  const recent = await channel.messages.fetch({ limit: limits.channelContextMessages, before: anchors.at(-1)?.id });
  for (const [id, message] of recent) if (message.createdTimestamp >= cutoff) found.set(id, message);
  let extra = 0;
  for (const start of anchors) {
    let current = start;
    while (extra < limits.replyChainDepth && current.reference && current.reference.type !== MessageReferenceType.Forward
      && current.reference.channelId === channel.id && current.reference.messageId) {
      const known = found.get(current.reference.messageId);
      if (known) { current = known; continue; }
      const parent = await current.fetchReference().catch(() => null);
      if (!parent) break;
      found.set(parent.id, parent);
      extra++;
      current = parent;
    }
  }
  return [...found.values()].sort(byId);
}

export async function load(source: Source, store: Store, forced: boolean): Promise<Loaded | null> {
  const channel = source.channel;
  const botId = channel.client.user.id;
  const pending = source.triggers;
  let originals: Message[];
  let memory: Memory | null = null;
  if (source.forum) {
    memory = store.get(channel.id);
    const after = memory?.summaryUntil ?? (BigInt(channel.id) - 1n).toString();
    originals = await fetchHistory(channel, after);
    // A brand-new post's starter message can lag behind its ThreadCreate event.
    if (pending.size && !originals.some((message) => pending.has(message.id))) {
      await Bun.sleep(1500);
      originals = await fetchHistory(channel, after);
    }
  } else {
    originals = await channelHistory(channel, pending);
  }
  const history = pendingHistory(originals.map(asHistory), botId, pending);
  const latest = history.filter((message) => pending.has(message.id) && message.authorId !== botId);
  latest.forEach((message, index) => { message.ref = `m${index + 1}`; });
  if (!forced && latest.length === 0) return null;
  const turns = groupTurns(history, botId);
  const images = await imagesFor(history, originals, botId);
  const people = new Map<string, Speaker>();
  for (const message of history) {
    if (message.authorId !== botId) people.set(message.authorId, { name: message.authorName, handle: message.authorHandle });
  }
  const rendered = new Set(history.map((message) => message.id));
  for (const message of originals) {
    if (!rendered.has(message.id)) continue;
    for (const [id, user] of message.mentions.users) {
      if (user.bot || people.has(id)) continue;
      people.set(id, { name: message.mentions.members?.get(id)?.displayName ?? user.displayName, handle: user.username });
    }
  }
  return {
    turns,
    images,
    memory,
    save: source.forum ? (updated) => store.save(channel.id, updated) : () => {},
    latest,
    people,
    replyTo: forced ? undefined : originals.find((message) => message.id === latest.at(-1)?.id),
  };
}



