import { MessageReferenceType } from "discord.js";
import type { GuildTextBasedChannel, Message as DiscordMessage } from "discord.js";
import { abortWait, throwIfAborted } from "../abort";
import { limits } from "../limits";
import { groupTurns, label, pendingHistory } from "./history";
import type { HistoryMessage, Speaker, Turn } from "./history";
import { mediaOf } from "../media/media";
import type { Seen } from "../media/media";
import { seeMedia } from "../media/see";
import type { Memory, Store } from "../memory/store";
import { cleanText } from "../discord/visibility";

type Message = DiscordMessage<true>;

/** `triggers` are the IDs of the messages this turn answers. */
export type Source = { channel: GuildTextBasedChannel; forum: boolean; thread: boolean; triggers: Set<string> };

type Loaded = {
  memory: Memory | null;
  save(memory: Memory): void;
  turns: Turn[];
  seen: Map<string, Seen>;
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
    content: [
      cleanText(message.content, message.channel),
      ...[...message.messageSnapshots.values()].filter((s) => s.content)
        .map((s) => `[forwarded message] ${cleanText(s.content!, message.channel)}`),
    ].filter(Boolean).join("\n"),
    media: mediaOf(message),
    replyTo: target ? {
      id: target.id,
      label: target.author.id === message.client.user.id ? "Axophyte" : label(target.member?.displayName ?? target.author.displayName, target.author.username),
      excerpt: excerpt(cleanText(target.content, message.channel), 100),
    } : null,
  };
}

// Newest first, back to `after`. Token budget, not message count, decides what fits: compaction
// folds anything older into the summary, so nothing past `after` may be skipped.
// ponytail: refetches every unsummarized message each turn (one request per 100); cache if long chatty threads get slow.
async function fetchHistory(channel: GuildTextBasedChannel, after: string, limit: number, signal?: AbortSignal): Promise<Message[]> {
  const messages: Message[] = [];
  let before: string | undefined;
  while (messages.length < limit) {
    throwIfAborted(signal);
    const page = await abortWait(channel.messages.fetch({ limit: Math.min(100, limit - messages.length), before }), signal);
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
  return messages.sort(byId);
}

// The triggers, recent messages before them (stale ones dropped), and the reply
// chains the triggers point into, which may be older; same channel only.
async function channelHistory(channel: GuildTextBasedChannel, triggers: Set<string>, signal?: AbortSignal): Promise<Message[]> {
  const anchors = (await abortWait(Promise.all([...triggers].map((id) => channel.messages.fetch(id).catch(() => null))), signal))
    .filter((message) => message !== null)
    .sort(byId);
  const found = new Map(anchors.map((message) => [message.id, message]));
  const cutoff = (anchors[0]?.createdTimestamp ?? Date.now()) - limits.channelContextMaxAgeMs;
  throwIfAborted(signal);
  const recent = await abortWait(channel.messages.fetch({ limit: limits.channelContextMessages, before: anchors.at(-1)?.id }), signal);
  for (const [id, message] of recent) if (message.createdTimestamp >= cutoff) found.set(id, message);
  let extra = 0;
  for (const start of anchors) {
    let current = start;
    while (extra < limits.replyChainDepth && current.reference && current.reference.type !== MessageReferenceType.Forward
      && current.reference.channelId === channel.id && current.reference.messageId) {
      const known = found.get(current.reference.messageId);
      if (known) { current = known; continue; }
      throwIfAborted(signal);
      const parent = await abortWait(current.fetchReference().catch(() => null), signal);
      if (!parent) break;
      found.set(parent.id, parent);
      extra++;
      current = parent;
    }
  }
  return [...found.values()].sort(byId);
}

export async function load(source: Source, store: Store, whisperModel: string, signal?: AbortSignal): Promise<Loaded | null> {
  throwIfAborted(signal);
  const channel = source.channel;
  const botId = channel.client.user.id;
  const pending = source.triggers;
  let originals: Message[];
  let memory: Memory | null = null;
  const persistent = source.forum || source.thread;
  if (persistent) {
    memory = store.get(channel.id);
    let after = memory?.summaryUntil ?? (BigInt(channel.id) - 1n).toString();
    const limit = memory ? Infinity : limits.firstLoadMessages;
    originals = await fetchHistory(channel, after, limit, signal);
    // A brand-new post's starter message can lag behind its ThreadCreate event.
    if (pending.size && !originals.some((message) => pending.has(message.id))) {
      await abortWait(Bun.sleep(1500), signal);
      originals = await fetchHistory(channel, after, limit, signal);
    }
    throwIfAborted(signal);
    if (!memory) {
      // The conversation starts here: at most firstLoadMessages back, then everything since is kept.
      if (originals.length === limit) after = (BigInt(originals[0]!.id) - 1n).toString();
      memory = { summary: "", summaryUntil: after };
      store.save(channel.id, memory);
    }
    if (channel.isThread()) {
      const starter = await abortWait(channel.fetchStarterMessage().catch(() => null), signal);
      if (starter && BigInt(starter.id) > BigInt(after) && !originals.some((message) => message.id === starter.id)) {
        originals.push(starter);
        originals.sort(byId);
      }
    }
  } else {
    originals = await channelHistory(channel, pending, signal);
  }
  const history = pendingHistory(originals.map(asHistory), botId, pending);
  const latest = history.filter((message) => pending.has(message.id) && message.authorId !== botId);
  latest.forEach((message, index) => { message.ref = `m${index + 1}`; });
  if (latest.length === 0) return null;
  const turns = groupTurns(history, botId);
  const seen = await seeMedia(history, botId, whisperModel, signal);
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
    seen,
    memory,
    save: persistent ? (updated) => store.save(channel.id, updated) : () => {},
    latest,
    people,
    replyTo: originals.find((message) => message.id === latest.at(-1)?.id),
  };
}



