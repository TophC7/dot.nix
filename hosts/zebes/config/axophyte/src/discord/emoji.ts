import type { Guild } from "discord.js";
import { limits } from "../limits";
import type { EmojiNote } from "../memory/store";

/** Prompt lines: each available server emoji with its description, once one exists. */
export function serverEmoji(guild: Guild, notes: Map<string, EmojiNote>): string[] {
  const lines: string[] = [];
  for (const emoji of guild.emojis.cache.values()) {
    if (!emoji.available || !emoji.name) continue;
    const description = notes.get(emoji.id)?.description;
    lines.push(description ? `:${emoji.name}: ${description}` : `:${emoji.name}:`);
    if (lines.length === limits.promptEmoji) break;
  }
  return lines;
}

export function discordEmoji(text: string, guild: Guild): string {
  return text.replace(/<a?:\w+:\d+>|:(\w+):/g, (token, name: string | undefined) => {
    if (!name) return token;
    const emoji = guild.emojis.cache.find((emoji) => emoji.name === name && emoji.available);
    return emoji ? String(emoji) : token;
  });
}

export function reactionEmoji(raw: string, guild: Guild): string {
  const token = raw.trim();
  const name = token.replace(/^:|:$/g, "");
  const emoji = guild.emojis.cache.find((emoji) => emoji.name === name && emoji.available);
  return emoji?.identifier ?? token;
}
