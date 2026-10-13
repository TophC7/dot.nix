import type { Collection } from "discord.js";
import type { UsableEmoji } from "../discord/emoji";
import type { ChatMessage } from "../llm/protocol";
import { loadImage } from "../media/download";
import type { Scheduler } from "../schedule";
import type { EmojiNote, Store } from "./store";

/** Longest emoji description, whether the model's or an admin's. */
export const EMOJI_NOTE_CHARS = 200;

/** Notes scope for model descriptions of Axophyte's own emoji, shared by every server; admin meanings stay per server. */
export const APP_EMOJI_SCOPE = "app";

export function emojiScope(emoji: UsableEmoji): string {
  return "guild" in emoji ? emoji.guild.id : APP_EMOJI_SCOPE;
}

/** Server scope last: its admins' meanings for Axophyte's own emoji override the shared descriptions. */
export function emojiNotesFor(store: Store, guildId: string): Map<string, EmojiNote> {
  return new Map([...store.emojiNotes(APP_EMOJI_SCOPE).all(), ...store.emojiNotes(guildId).all()]);
}

/** The model sees the emoji itself when it loaded; otherwise it judges from the name alone. */
function describerMessages(name: string, image: string | null): ChatMessage[] {
  const text = `This is a custom Discord emoji named :${name}:. In one short line (under 15 words), say what it shows and, from ${image ? "the picture and " : ""}the name, what people probably use it for. Write only that line.`;
  return [{ role: "user", content: image ? [{ type: "text", text }, { type: "image_url", image_url: { url: image } }] : text }];
}

type PendingDescription = { emoji: UsableEmoji; name: string };

/** Event-driven descriptions share the model queue, with only one command queued at a time. */
export class EmojiDescriptions {
  private readonly pending = new Map<string, PendingDescription>();
  private scheduled = false;

  constructor(
    private readonly store: Store,
    private readonly scheduler: Pick<Scheduler, "command">,
    private readonly ask: (messages: ChatMessage[], maxTokens: number) => Promise<string>,
    /** Scope: a guild ID, or APP_EMOJI_SCOPE for Axophyte's own emoji. */
    private readonly ready: (scope: string) => boolean,
  ) {}

  /**
   * Call once per ready scope, after fetching its authoritative emoji cache. A server scope also
   * holds its admins' meanings for Axophyte's own emoji, so pass those (fresh) as `own` to keep them.
   */
  seed(scope: string, emojis: Collection<string, UsableEmoji>, own?: Collection<string, UsableEmoji>): void {
    if (!this.ready(scope)) return;
    const notes = this.store.emojiNotes(scope);
    const known = notes.all();
    for (const id of known.keys()) {
      if (!emojis.has(id) && !own?.has(id)) notes.delete(id);
    }
    for (const emoji of emojis.values()) this.add(emoji, known.get(emoji.id));
    this.schedule();
  }

  enqueue(emoji: UsableEmoji): void {
    const scope = emojiScope(emoji);
    if (!this.ready(scope)) return;
    this.add(emoji, this.store.emojiNotes(scope).all().get(emoji.id));
    this.schedule();
  }

  delete(emoji: UsableEmoji): void {
    const scope = emojiScope(emoji);
    if (!this.ready(scope)) return;
    this.pending.delete(emoji.id);
    this.store.emojiNotes(scope).delete(emoji.id);
  }

  private add(emoji: UsableEmoji, note: EmojiNote | undefined): void {
    if (emoji.available && emoji.name && (!note || (!note.byAdmin && note.name !== emoji.name))) {
      this.pending.set(emoji.id, { emoji, name: emoji.name });
    } else {
      this.pending.delete(emoji.id);
    }
  }

  private current(entry: PendingDescription): UsableEmoji | undefined {
    const { emoji, name } = entry;
    if (!this.ready(emojiScope(emoji)) || this.pending.get(emoji.id) !== entry) return;
    const current = ("guild" in emoji ? emoji.guild.emojis.cache : emoji.application.emojis.cache).get(emoji.id);
    return current?.available && current.name === name ? current : undefined;
  }

  private async describe(emoji: UsableEmoji): Promise<string> {
    const url = emoji.imageURL({ extension: "png", size: 128 });
    // Animated emoji come back as their first frame; a failed fetch still gets a name-only guess.
    const image = await loadImage({ url, proxyURL: url, contentType: "image/png", size: 0, width: 128, height: 128 }).catch(() => null);
    const description = parseDescription(await this.ask(describerMessages(emoji.name!, image), 200));
    if (!description) throw new Error(`empty description for emoji ${emoji.id}`);
    return description;
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
          this.store.emojiNotes(emojiScope(emoji)).set(emoji.id, { name: entry.name, description, byAdmin: false });
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

function parseDescription(text: string): string | null {
  const line = text.trim().split("\n")[0]!.trim().replace(/^["']|["']$/g, "").trim();
  return line ? line.slice(0, EMOJI_NOTE_CHARS) : null;
}
