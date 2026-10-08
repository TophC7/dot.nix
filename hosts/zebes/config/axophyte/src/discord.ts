import { Client, GatewayIntentBits, type GuildTextBasedChannel, type Message } from "discord.js";
import { splitMessage } from "./discord-text";
import { limits } from "./limits";

const allowedMentions = { parse: [] as [], repliedUser: false };

export function createClient(): Client {
  return new Client({
    intents: [
      GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent,
      GatewayIntentBits.GuildMembers, GatewayIntentBits.GuildMessageTyping,
    ],
    allowedMentions,
  });
}

export class ReplyStream {
  private chunks = [""];
  private messages: Message[] = [];
  private written: string[] = [];
  private writes: Promise<void> = Promise.resolve();
  private writeError: unknown;
  private closed = false;
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
        if (!this.closed && !this.chunks.some(Boolean)) {
          await this.write(0, "⏳ Waiting for the model — it's busy with another request…");
        }
      });
    }, limits.queueNoticeMs);
  }

  push(delta: string): void {
    if (this.closed || !delta) return;
    const tail = this.chunks.pop()! + delta;
    this.chunks.push(...splitMessage(tail, limits.splitAt));
    if (!this.chunks.length) this.chunks.push("");
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
    if (!content || this.written[index] === content) return;
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
    for (let index = 0; index < chunks.length; index++) {
      await this.write(index, chunks[index]!);
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
    if (footer.length) {
      const text = footer.join("\n");
      const tail = this.chunks.at(-1)!;
      const combined = tail ? `${tail}\n\n${text}` : text;
      if (combined.length <= 2000) this.chunks[this.chunks.length - 1] = combined;
      else this.chunks.push(...splitMessage(text, limits.splitAt));
    }
    this.enqueue(() => this.flush());
    await this.writes;
    if (this.writeError !== undefined) throw this.writeError;
  }

  // Only used before any model output, so at most the ⏳ notice is removed.
  async cancel(): Promise<void> {
    this.stop();
    await this.writes;
    await Promise.all(this.messages.map((message) => message.delete().catch(() => {})));
  }

  async fail(text: string): Promise<void> {
    // Keep every generated chunk, including output not yet sent to Discord.
    if (!this.closed) this.push(this.chunks.some(Boolean) ? `\n\n${text}` : text);
    else {
      const tail = this.chunks.pop()!;
      this.chunks.push(...splitMessage(tail ? `${tail}\n\n${text}` : text, limits.splitAt));
    }
    await this.finish([]);
  }
}
