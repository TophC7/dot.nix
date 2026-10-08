export type HistoryMessage = {
  id: string;
  authorId: string;
  authorName: string;
  authorHandle: string;
  authorIsBot: boolean;
  webhookId: string | null;
  system: boolean;
  content: string;
  attachments: { id: string; name: string; contentType: string | null }[];
  replyTo: { id: string; label: string; excerpt: string } | null;
  /** Short tag ([m1]) on the turn's trigger messages, so memory writes name their source message. */
  ref?: string;
};

export type Speaker = { name: string; handle: string };


export function label(name: string, handle: string): string {
  return `${name} (@${handle})`;
}

export type Turn = { messages: HistoryMessage[] };

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
      turns.push({ messages: [] });
    }
    turns[turns.length - 1]!.messages.push(message);
    previousIsAssistant = isAssistant;
  }
  return turns;
}

// The messages that triggered this turn render last, as the current turn, even
// when a later reply (an earlier burst's answer, a /search) was posted after them.
export function pendingHistory(history: HistoryMessage[], botId: string, pending: Set<string>): HistoryMessage[] {
  const filtered = relevant(history, botId);
  return [...filtered.filter((message) => !pending.has(message.id)), ...filtered.filter((message) => pending.has(message.id))];
}
