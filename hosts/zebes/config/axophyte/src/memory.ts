export type HistoryMessage = {
  id: string;
  authorId: string;
  authorName: string;
  authorIsBot: boolean;
  webhookId: string | null;
  system: boolean;
  content: string;
  attachments: { id: string; name: string; contentType: string | null }[];
};

export type ChatPart =
  | { type: "text"; text: string }
  | { type: "image_url"; image_url: { url: string } };

export type ToolCall = {
  id: string;
  type: "function";
  function: { name: string; arguments: string };
};

export type ChatMessage =
  | { role: "system" | "user"; content: string | ChatPart[] }
  | { role: "assistant"; content: string | null; tool_calls?: ToolCall[] }
  | { role: "tool"; tool_call_id: string; content: string };

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
  for (const message of relevant(history, botId)) {
    const isAssistant = message.authorId === botId;
    if (!turns.length || (!isAssistant && previousIsAssistant)) {
      turns.push({ messages: [] });
    }
    turns[turns.length - 1]!.messages.push(message);
    previousIsAssistant = isAssistant;
  }
  return turns;
}

export function lastIsAssistant(history: HistoryMessage[], botId: string): boolean {
  return relevant(history, botId).at(-1)?.authorId === botId;
}
