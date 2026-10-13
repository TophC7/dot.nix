import type { Media } from "../media/media";

export type HistoryMessage = {
  id: string;
  authorId: string;
  authorName: string;
  authorHandle: string;
  authorIsBot: boolean;
  webhookId: string | null;
  system: boolean;
  createdAt: number;
  reactions: { emoji: string; count: number; me: boolean }[];
  content: string;
  media: Media[];
  replyTo: { id: string; label: string; excerpt: string } | null;
  /** Short tag ([m1]) assigned by load to each trigger message, for tools to name their source. */
  ref?: string;
};

export type Speaker = { name: string; handle: string };


export function label(name: string, handle: string): string {
  return `${name} (@${handle})`;
}

export type Turn = HistoryMessage[];

export function tagged(latest: HistoryMessage[], raw: string): HistoryMessage | string {
  const key = raw.trim().replace(/^\[|\]$/g, "").trim();
  return latest.find((message) => message.ref === key)
    ?? `message must be one of: ${latest.flatMap((message) => message.ref ? [message.ref] : []).join(", ")}`;
}

const STATUS_PREFIXES = ["⚠️", "⏳"];

export function relevant(history: HistoryMessage[], botId: string): HistoryMessage[] {
  return history.filter((message) => {
    if (message.system || message.webhookId !== null) return false;
    if (message.authorId === botId) {
      return !STATUS_PREFIXES.some((prefix) => message.content.startsWith(prefix));
    }
    return !message.authorIsBot;
  });
}

export function groupTurns(history: HistoryMessage[], botId: string): Turn[] {
  const turns: Turn[] = [];
  let previousIsAssistant = false;
  for (const message of history) {
    const isAssistant = message.authorId === botId;
    if (!turns.length || (!isAssistant && previousIsAssistant)) {
      turns.push([]);
    }
    turns.at(-1)!.push(message);
    previousIsAssistant = isAssistant;
  }
  return turns;
}

// The messages that triggered this turn render last, as the current turn, even
// when a later reply (an earlier burst's answer) was posted after them.
export function pendingHistory(history: HistoryMessage[], botId: string, pending: Set<string>): HistoryMessage[] {
  const filtered = relevant(history, botId);
  return [...filtered.filter((message) => !pending.has(message.id)), ...filtered.filter((message) => pending.has(message.id))];
}
