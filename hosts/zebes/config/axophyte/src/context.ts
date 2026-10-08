import {
  MessageReferenceType,
  type AnyThreadChannel,
  type GuildTextBasedChannel,
  type Message as DiscordMessage,
} from "discord.js";
import { loadImage } from "./images";
import { limits } from "./limits";
import { label, type ChatMessage, type ChatPart, type HistoryMessage, type Turn } from "./memory";
import { pendingHistory } from "./pending-history";
import type { Speaker } from "./people";
import type { Memory, Store } from "./store";
import { cleanText } from "./visibility";

type Message = DiscordMessage<true>;

/** `triggers` are the IDs of the messages this turn answers; empty for /search. */
export type Source =
  | { kind: "forum"; thread: AnyThreadChannel; triggers: Set<string> }
  | { kind: "channel"; channel: GuildTextBasedChannel; triggers: Set<string> };

export type Loaded = {
  key: string;
  channel: GuildTextBasedChannel;
  where: string;
  originals: Message[];
  history: HistoryMessage[];
  memory: Memory | null;
  save(memory: Memory): void;
  /** Trigger messages, in order: the only messages whose authors' notes may be written. */
  latest: HistoryMessage[];
  /** Everyone whose notes load: rendered authors plus people they mention. */
  people: Map<string, Speaker>;
  replyTo?: Message;
  answer: boolean;
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
    content: cleanText(message.content, message.channel),
    attachments: [...message.attachments.values()].map((attachment) => ({
      id: attachment.id, name: attachment.name ?? attachment.id, contentType: attachment.contentType,
    })),
    replyTo: target ? {
      label: target.author.id === message.client.user.id ? "Axophyte" : label(target.member?.displayName ?? target.author.displayName, target.author.username),
      excerpt: excerpt(cleanText(target.content, message.channel), 100),
    } : null,
  };
}

export function speakerLine(message: HistoryMessage, botId: string): string {
  if (message.authorId === botId) return `Axophyte: ${message.content}`;
  const reply = message.replyTo ? ` → replying to ${message.replyTo.label} "${message.replyTo.excerpt}"` : "";
  return `${message.ref ? `[${message.ref}] ` : ""}${label(message.authorName, message.authorHandle)}${reply}: ${message.content}`;
}

async function fetchHistory(thread: AnyThreadChannel, after: string): Promise<Message[]> {
  const messages: Message[] = [];
  let before: string | undefined;
  while (messages.length < limits.maxHistoryMessages) {
    const page = await thread.messages.fetch({ limit: Math.min(100, limits.maxHistoryMessages - messages.length), before });
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
  if (messages.length === limits.maxHistoryMessages) console.warn(`history cap reached for ${thread.id}`);
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

export async function load(source: Source, store: Store, forced: boolean): Promise<Loaded> {
  const channel = source.kind === "forum" ? source.thread : source.channel;
  const botId = channel.client.user.id;
  const key = channel.id;
  const pending = source.triggers;
  let originals: Message[];
  let memory: Memory | null = null;
  if (source.kind === "forum") {
    const thread = source.thread;
    memory = store.get(thread.id);
    const after = memory?.summaryUntil ?? (BigInt(thread.id) - 1n).toString();
    originals = await fetchHistory(thread, after);
    // A brand-new post's starter message can lag behind its ThreadCreate event.
    if (pending.size && !originals.some((message) => pending.has(message.id))) {
      await Bun.sleep(1500);
      originals = await fetchHistory(thread, after);
    }
  } else {
    originals = await channelHistory(channel, pending);
  }
  const history = pendingHistory(originals.map(asHistory), botId, pending);
  const latest = history.filter((message) => pending.has(message.id) && message.authorId !== botId);
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
    key,
    channel,
    where: source.kind === "forum" ? "a Discord forum post" : `the Discord channel #${channel.name}`,
    originals,
    history,
    memory,
    save: source.kind === "forum" ? (updated) => store.save(key, updated) : () => {},
    latest,
    people,
    replyTo: forced ? undefined : originals.find((message) => message.id === latest.at(-1)?.id),
    answer: forced || latest.length > 0,
  };
}

export async function imagesFor(history: HistoryMessage[], originals: Message[], botId: string): Promise<Map<string, string>> {
  const images = new Map<string, string>();
  const byMessage = new Map(originals.map((message) => [message.id, message]));
  let attempted = 0;
  for (const message of [...history].reverse()) {
    if (message.authorId === botId) continue;
    for (const attachment of [...(byMessage.get(message.id)?.attachments.values() ?? [])].reverse()) {
      if (!attachment.contentType?.startsWith("image/")) continue;
      if (attempted++ >= limits.maxImagesPerRequest) return images;
      try {
        const image = await loadImage({
          id: attachment.id, url: attachment.url, proxyURL: attachment.proxyURL,
          contentType: attachment.contentType, size: attachment.size,
          width: attachment.width, height: attachment.height, name: attachment.name ?? attachment.id,
        });
        if (image) images.set(attachment.id, image);
      } catch { /* Unavailable attachments are represented in the transcript, never fatal. */ }
    }
  }
  return images;
}

// Axophyte's own messages stay unlabeled so the model never learns to emit labels.
export function render(turns: Turn[], channel: GuildTextBasedChannel, botId: string, images: Map<string, string>): ChatMessage[] {
  const messages: ChatMessage[] = [];
  for (const turn of turns) {
    for (const message of turn.messages) {
      if (message.authorId === botId) {
        const previous = messages.at(-1);
        if (previous?.role === "assistant") previous.content = `${previous.content ?? ""}\n${message.content}`;
        else messages.push({ role: "assistant", content: message.content });
        continue;
      }
      let text = `${message.id === channel.id ? `[Forum post title: ${channel.name}]\n` : ""}${speakerLine(message, botId)}`;
      const parts: ChatPart[] = [];
      for (const attachment of message.attachments) {
        const image = images.get(attachment.id);
        if (image) parts.push({ type: "image_url", image_url: { url: image } });
        else text += `\n${attachment.contentType?.startsWith("image/") ? `[image: ${attachment.name} — not shown]` : `[attachment: ${attachment.name} — unsupported]`}`;
      }
      messages.push({ role: "user", content: parts.length ? [{ type: "text", text }, ...parts] : text });
    }
  }
  return messages;
}

export function summaryTranscript(turns: Turn[], botId: string): string {
  return turns.flatMap((turn) => turn.messages.map((message) =>
    `${speakerLine(message, botId)}${message.attachments.map((attachment) => `\n[${attachment.contentType?.startsWith("image/") ? "image" : "attachment"}: ${attachment.name}]`).join("")}`,
  )).join("\n");
}
