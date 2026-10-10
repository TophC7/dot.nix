import type { GuildTextBasedChannel, Message } from "discord.js";
import { limits } from "../limits";
import { discordEmoji, extractTrailingEmojis } from "./emoji";

export const allowedMentions = { parse: [] as [], repliedUser: false };

export class ReplyStream {
  private chunks = [""];
  private messages: Message[] = [];
  private written: string[] = [];
  private writes: Promise<void> = Promise.resolve();
  private writeError: unknown;
  private closed = false;
  private hasText = false;
  private lastWriteAt = 0;
  private editTimer: NodeJS.Timeout | undefined;
  private typingTimer: NodeJS.Timeout;
  private noticeTimer: NodeJS.Timeout;

  constructor(private channel: GuildTextBasedChannel, private replyTo?: Message) {
    const typing = () => { void channel.sendTyping().catch(() => {}); };
    typing();
    this.typingTimer = setInterval(typing, limits.typingIntervalMs);
    this.noticeTimer = setTimeout(() => {
      this.enqueue(async () => {
        if (!this.closed && !this.hasText) {
          await this.write(0, "⏳ Waiting for the model — it's busy with another request…");
        }
      });
    }, limits.queueNoticeMs);
  }

  push(delta: string): void {
    if (this.closed || !delta) return;
    const sanitized = delta.replace(/[—–]/g, "-");
    const tail = this.chunks.pop()! + sanitized;
    this.chunks.push(...splitMessage(tail, limits.splitAt));
    if (!this.chunks.length) this.chunks.push("");
    if (!this.hasText) {
      if (!delta.trim()) return;
      this.hasText = true;
    }
    clearTimeout(this.noticeTimer);
    if (this.editTimer === undefined) {
      this.editTimer = setTimeout(() => {
        this.editTimer = undefined;
        this.enqueue(() => this.flush());
      }, Math.max(0, limits.editIntervalMs - (Date.now() - this.lastWriteAt)));
    }
  }

  private enqueue(run: () => Promise<void>): void {
    this.writes = this.writes.then(run).catch((error: unknown) => {
      this.writeError ??= error;
    });
  }

  private async write(index: number, content: string): Promise<void> {
    if (!content.trim()) return;
    const converted = discordEmoji(content, this.channel.guild);
    // Conversion lengthens text after splitting at 1900; keep the original if it exceeds Discord's limit.
    if (converted.length <= 2000) content = converted;
    if (this.written[index] === content) return;
    const existing = this.messages[index];
    if (existing) {
      const wait = limits.editIntervalMs - (Date.now() - this.lastWriteAt);
      if (wait > 0) await Bun.sleep(wait);
      this.lastWriteAt = Date.now();
      await existing.edit({ content, allowedMentions });
    } else {
      this.lastWriteAt = Date.now();
      this.messages[index] = await this.channel.send({
        content,
        allowedMentions,
        ...(index === 0 && this.replyTo ? {
          reply: { messageReference: this.replyTo.id, failIfNotExists: false },
        } : {}),
      });
    }
    this.written[index] = content;
  }

  private async flush(): Promise<void> {
    // Snapshot once: incoming deltas never mutate an in-flight Discord write.
    const chunks = [...this.chunks];
    let index = 0;
    for (const content of chunks) {
      if (content.trim()) await this.write(index++, content);
    }
  }

  private stop(): void {
    this.closed = true;
    clearTimeout(this.editTimer);
    this.editTimer = undefined;
    clearTimeout(this.noticeTimer);
    clearInterval(this.typingTimer);
  }

  async finish(footer: string[]): Promise<void> {
    this.stop();
    const last = this.chunks.pop() ?? "";
    const converted = discordEmoji(last, this.channel.guild);
    const trailing = extractTrailingEmojis(converted);
    const footerText = footer.length ? `\n\n${footer.join("\n")}` : "";
    const combined = `${trailing ? trailing.body : converted}${footerText}`;
    if (combined.trim()) this.chunks.push(...splitMessage(combined, limits.splitAt));
    if (trailing) this.chunks.push(trailing.emojis);
    if (!this.chunks.some((chunk) => chunk.trim())) {
      await this.cancel();
      return;
    }
    this.enqueue(() => this.flush());
    await this.writes;
    if (this.writeError !== undefined) throw this.writeError;
  }

  // Only used before substantive model output, so at most the ⏳ notice is removed.
  async cancel(): Promise<void> {
    this.stop();
    await this.writes;
    await Promise.all(this.messages.map((message) => message.delete().catch(() => {})));
  }

  async fail(text: string): Promise<void> {
    // Keep every generated chunk, including output not yet sent to Discord.
    const tail = this.chunks.pop()!;
    this.chunks.push(...splitMessage(tail ? `${tail}\n\n${text}` : text, limits.splitAt));
    await this.finish([]);
  }
}

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

