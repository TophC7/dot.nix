import type { GuildTextBasedChannel } from "discord.js";
import { label } from "./history";
import type { HistoryMessage, Turn } from "./history";
import type { ChatMessage, ChatPart } from "../llm/protocol";
import type { Source } from "./load";
import { SOUL } from "../soul";

const SUMMARIZER = "You maintain the memory of a Discord conversation. Merge the existing memory and the new transcript into one updated memory: a concise bullet list (at most 400 words) of participants and their preferences, facts established, decisions, open questions, important URLs, and descriptions of images that were discussed. Write only the bullet list.";

export function systemPrompt(input: { source: Source; summary: string; people: string }): ChatMessage {
  const { source, summary, people } = input;
  const where = source.forum ? "a Discord forum post" : `#${source.channel.name}`;
  const sections = [
    SOUL,
    `You are in ${where}. Today is ${new Date().toISOString().slice(0, 10)}.`,
    summary && `## Earlier in this conversation (summary; may be incomplete)\n${summary}`,
    people,
  ];
  return { role: "system", content: sections.filter(Boolean).join("\n\n") };
}

export function summaryRequest(summary: string, folded: Turn[], botId: string): ChatMessage[] {
  return [
    { role: "system", content: SUMMARIZER },
    { role: "user", content: `Existing memory:\n${summary || "(none)"}\n\nNew transcript:\n${summaryTranscript(folded, botId)}` },
  ];
}

/** `previousId`: the message rendered just before; a reply to it needs no quote. */
export function speakerLine(message: HistoryMessage, botId: string, previousId?: string): string {
  if (message.authorId === botId) return `Axophyte: ${message.content}`;
  const quote = message.replyTo && message.replyTo.id !== previousId && message.replyTo.excerpt ? ` "${message.replyTo.excerpt}"` : "";
  const reply = message.replyTo ? ` → replying to ${message.replyTo.label}${quote}` : "";
  return `${message.ref ? `[${message.ref}] ` : ""}${label(message.authorName, message.authorHandle)}${reply}: ${message.content}`;
}

// Axophyte's own messages stay unlabeled so the model never learns to emit labels.
export function render(turns: Turn[], channel: GuildTextBasedChannel, botId: string, images: Map<string, string>): ChatMessage[] {
  const messages: ChatMessage[] = [];
  let previousId: string | undefined;
  for (const turn of turns) {
    for (const message of turn.messages) {
      const before = previousId;
      previousId = message.id;
      if (message.authorId === botId) {
        const previous = messages.at(-1);
        if (previous?.role === "assistant") previous.content = `${previous.content ?? ""}\n${message.content}`;
        else messages.push({ role: "assistant", content: message.content });
        continue;
      }
      let text = `${message.id === channel.id ? `[Forum post title: ${channel.name}]\n` : ""}${speakerLine(message, botId, before)}`;
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

function summaryTranscript(turns: Turn[], botId: string): string {
  return turns.flatMap((turn) => turn.messages.map((message) =>
    `${speakerLine(message, botId)}${message.attachments.map((attachment) => `\n[${attachment.contentType?.startsWith("image/") ? "image" : "attachment"}: ${attachment.name}]`).join("")}`,
  )).join("\n");
}
