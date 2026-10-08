export function splitMessage(text: string, limit: number): string[] {
  if (!Number.isInteger(limit) || limit < 1) {
    throw new RangeError("message limit must be a positive integer");
  }
  const chunks: string[] = [];
  while (text.length > limit) {
    let cut = text.lastIndexOf("\n\n", limit);
    if (cut < 0) cut = text.lastIndexOf("\n", limit);
    if (cut < 0) cut = text.lastIndexOf(" ", limit);
    if (cut >= 0) {
      const chunk = text.slice(0, cut).trimEnd();
      if (chunk) chunks.push(chunk);
      text = text.slice(cut).trimStart();
    } else {
      chunks.push(text.slice(0, limit));
      text = text.slice(limit);
    }
  }
  if (text) chunks.push(text);
  return chunks;
}

export function isConversationMessage(
  m: {
    guildId: string | null;
    channelId: string;
    id: string;
    parentId: string | null;
    isThread: boolean;
    authorIsBot: boolean;
    webhookId: string | null;
    type: number;
  },
  guildId: string,
  forumId: string,
): boolean {
  return (
    m.guildId === guildId &&
    m.isThread &&
    m.parentId === forumId &&
    !m.authorIsBot &&
    m.webhookId === null &&
    (m.type === 0 || m.type === 19) &&
    m.id !== m.channelId
  );
}
