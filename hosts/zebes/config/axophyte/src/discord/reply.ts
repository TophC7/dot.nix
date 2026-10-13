import type { GuildTextBasedChannel, Message } from "discord.js";
import { discordEmoji, extractTrailingEmojis } from "./emoji";

export const EDIT_INTERVAL_MS = 1200;
export const TYPING_INTERVAL_MS = 8000;
/** Silence before the reply slot shows what Axophyte is doing. */
export const STATUS_NOTICE_MS = 15_000;
export const SPLIT_AT = 1900;

export const allowedMentions = { parse: [] as [], repliedUser: false };

export type ReplyFile = { attachment: Buffer; name: string };

/** Posted after the notice delay in a channel whose turn waits behind other model work; call the result to remove it. */
export function waitNotice(channel: GuildTextBasedChannel): () => void {
  let notice: Promise<Message | null> | undefined;
  const timer = setTimeout(() => {
    notice = channel.send({ content: "-# ⏳ busy with something else, I'll get to this soon…", allowedMentions }).catch(() => null);
  }, STATUS_NOTICE_MS);
  return () => {
    clearTimeout(timer);
    void notice?.then((message) => message?.delete().catch(() => {}));
  };
}

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
  private statusText = "";
  private noticeShown = false;
  private pendingPreview: ReplyFile | undefined;
  private previewShown = false;

  constructor(private channel: GuildTextBasedChannel, private replyTo?: Message) {
    const typing = () => { void channel.sendTyping().catch(() => {}); };
    typing();
    this.typingTimer = setInterval(typing, TYPING_INTERVAL_MS);
    this.noticeTimer = setTimeout(() => this.enqueue(() => this.showNotice()), STATUS_NOTICE_MS);
  }

  /** Sets what the reply is doing; shown as subtext once the notice delay has passed without text. */
  status(text: string): void {
    if (this.closed || this.hasText) return;
    this.statusText = text.replace(/\s+/g, " ").trim(); // subtext (-#) only covers one line
    if (this.noticeShown) this.enqueue(() => this.showNotice());
  }

  /** Like status, plus an image shown with the notice until text or the final files replace it. */
  preview(text: string, file: ReplyFile): void {
    if (this.closed || this.hasText) return;
    this.pendingPreview = file;
    this.status(text);
  }

  private async showNotice(): Promise<void> {
    if (this.closed || this.hasText || !this.statusText) return;
    const files = this.pendingPreview ? [this.pendingPreview] : undefined;
    await this.write(0, `-# ${this.statusText}`, files ? { files } : undefined);
    if (files) {
      this.previewShown = true;
      this.pendingPreview = undefined;
    }
    this.noticeShown = true;
  }

  push(delta: string): void {
    if (this.closed || !delta) return;
    const sanitized = delta.replace(/[—–]/g, "-");
    const tail = this.chunks.pop()! + sanitized;
    this.chunks.push(...splitMessage(tail, SPLIT_AT));
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
      }, Math.max(0, EDIT_INTERVAL_MS - (Date.now() - this.lastWriteAt)));
    }
  }

  private enqueue(run: () => Promise<void>): void {
    this.writes = this.writes.then(run).catch((error: unknown) => {
      this.writeError ??= error;
    });
  }

  private async write(index: number, content: string, attach?: { files?: ReplyFile[]; clear?: boolean }): Promise<void> {
    if (!content.trim()) return;
    const converted = discordEmoji(content, this.channel.guild);
    // Conversion lengthens text after splitting at 1900; keep the original if it exceeds Discord's limit.
    if (converted.length <= 2000) content = converted;
    if (!attach && this.written[index] === content) return;
    // Files replace a message's attachments; an empty list removes them.
    const extras = attach?.files ? { files: attach.files } : attach?.clear ? { attachments: [] } : {};
    const existing = this.messages[index];
    if (existing) {
      const wait = EDIT_INTERVAL_MS - (Date.now() - this.lastWriteAt);
      if (wait > 0) await Bun.sleep(wait);
      this.lastWriteAt = Date.now();
      await existing.edit({ content, allowedMentions, ...extras });
    } else {
      this.lastWriteAt = Date.now();
      this.messages[index] = await this.channel.send({
        content,
        allowedMentions,
        ...extras,
        ...(index === 0 && this.replyTo ? {
          reply: { messageReference: this.replyTo.id, failIfNotExists: false },
        } : {}),
      });
    }
    this.written[index] = content;
  }

  private async flush(files?: ReplyFile[], filesAt = 0): Promise<void> {
    // Snapshot once: incoming deltas never mutate an in-flight Discord write.
    const chunks = [...this.chunks].filter((chunk) => chunk.trim());
    for (const [index, content] of chunks.entries()) {
      const clear = index === 0 && this.previewShown;
      if (clear) this.previewShown = false;
      await this.write(index, content, files && index === filesAt ? { files } : clear ? { clear } : undefined);
    }
  }

  private stop(): void {
    this.closed = true;
    clearTimeout(this.editTimer);
    this.editTimer = undefined;
    clearTimeout(this.noticeTimer);
    clearInterval(this.typingTimer);
  }

  async finish(footer: string[], files: ReplyFile[] = []): Promise<void> {
    this.stop();
    const last = this.chunks.pop() ?? "";
    const converted = discordEmoji(last, this.channel.guild);
    const trailing = extractTrailingEmojis(converted);
    const footerText = footer.length ? `\n\n${footer.join("\n")}` : "";
    const combined = `${trailing ? trailing.body : converted}${footerText}`;
    if (combined.trim()) this.chunks.push(...splitMessage(combined, SPLIT_AT));
    // Files go with the body and footer, not a trailing emoji-only message.
    const filesAt = Math.max(0, this.chunks.filter((chunk) => chunk.trim()).length - 1);
    if (trailing) this.chunks.push(trailing.emojis);
    if (!this.chunks.some((chunk) => chunk.trim())) {
      await this.cancel();
      return;
    }
    this.enqueue(() => this.flush(files.length ? files : undefined, filesAt));
    await this.writes;
    if (this.writeError !== undefined) throw this.writeError;
  }

  // Only used before substantive model output, so at most the status notice is removed.
  async cancel(): Promise<void> {
    this.stop();
    await this.writes;
    await Promise.all(this.messages.map((message) => message.delete().catch(() => {})));
  }

  async fail(text: string, files: ReplyFile[] = []): Promise<void> {
    // Keep every generated chunk, including output not yet sent to Discord.
    const tail = this.chunks.pop()!;
    this.chunks.push(...splitMessage(tail ? `${tail}\n\n${text}` : text, SPLIT_AT));
    await this.finish([], files);
  }
}

export function splitMessage(text: string, limit: number): string[] {
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

