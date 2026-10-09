import type { Guild, GuildEmoji } from "discord.js";
import { limits } from "../limits";
import type { ChatMessage } from "../llm/protocol";
import type { Scheduler } from "../schedule";
import type { EmojiNote, Store } from "./store";

/** The model sees the emoji itself when it loaded; otherwise it judges from the name alone. */
export function describerMessages(name: string, image: string | null): ChatMessage[] {
  const text = `This is a custom Discord emoji named :${name}:. In one short line (under 15 words), say what it shows and, from ${image ? "the picture and " : ""}the name, what people probably use it for. Write only that line.`;
  return [{ role: "user", content: image ? [{ type: "text", text }, { type: "image_url", image_url: { url: image } }] : text }];
}

type PendingDescription = { emoji: GuildEmoji; name: string };

/** Event-driven descriptions share the model queue, with only one command queued at a time. */
export class EmojiDescriptions {
  private readonly pending = new Map<string, PendingDescription>();
  private scheduled = false;

  constructor(
    private readonly store: Store,
    private readonly scheduler: Pick<Scheduler, "command">,
    private readonly describe: (emoji: GuildEmoji) => Promise<string>,
    private readonly ready: (guildId: string) => boolean,
  ) {}

  /** Call once per ready guild, after fetching its authoritative emoji cache. */
  seed(guild: Guild): void {
    if (!this.ready(guild.id)) return;
    const notes = this.store.emojiNotes(guild.id);
    const known = notes.all();
    for (const id of known.keys()) {
      if (!guild.emojis.cache.has(id)) notes.delete(id);
    }
    for (const emoji of guild.emojis.cache.values()) this.add(emoji, known.get(emoji.id));
    this.schedule();
  }

  enqueue(emoji: GuildEmoji): void {
    if (!this.ready(emoji.guild.id)) return;
    this.add(emoji, this.store.emojiNotes(emoji.guild.id).all().get(emoji.id));
    this.schedule();
  }

  delete(emoji: GuildEmoji): void {
    if (!this.ready(emoji.guild.id)) return;
    this.pending.delete(emoji.id);
    this.store.emojiNotes(emoji.guild.id).delete(emoji.id);
  }

  private add(emoji: GuildEmoji, note: EmojiNote | undefined): void {
    if (emoji.available && emoji.name && (!note || (!note.byAdmin && note.name !== emoji.name))) {
      this.pending.set(emoji.id, { emoji, name: emoji.name });
    } else {
      this.pending.delete(emoji.id);
    }
  }

  private current(entry: PendingDescription): GuildEmoji | undefined {
    const { emoji, name } = entry;
    if (!this.ready(emoji.guild.id) || this.pending.get(emoji.id) !== entry) return;
    const current = emoji.guild.emojis.cache.get(emoji.id);
    return current?.available && current.name === name ? current : undefined;
  }

  private schedule(): void {
    if (this.scheduled) return;
    const entry = this.pending.values().next().value;
    if (!entry) return;
    this.scheduled = true;
    void this.scheduler.command(async () => {
      try {
        const emoji = this.current(entry);
        if (!emoji) return;
        const description = await this.describe(emoji);
        // Delete/rename events invalidate the entry even if inference was already running.
        if (this.current(entry)) {
          this.store.emojiNotes(emoji.guild.id).set(emoji.id, { name: entry.name, description, byAdmin: false });
        }
      } catch (error) {
        console.error(`emoji ${entry.emoji.id} :${entry.name}: description failed`, error);
      }
    }).finally(() => {
      // An update during inference leaves a newer entry for the next command.
      if (this.pending.get(entry.emoji.id) === entry) this.pending.delete(entry.emoji.id);
      this.scheduled = false;
      this.schedule();
    });
  }
}

export function parseDescription(text: string): string | null {
  const line = text.trim().split("\n")[0]!.trim().replace(/^["']|["']$/g, "").trim();
  return line ? line.slice(0, limits.emojiNoteChars) : null;
}
