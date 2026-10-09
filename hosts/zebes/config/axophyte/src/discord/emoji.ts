import type { Guild, GuildEmoji } from "discord.js";
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

function isDistanceOne(a: string, b: string): boolean {
  if (Math.abs(a.length - b.length) > 1) return false;
  if (a.length === b.length) {
    let diff = 0;
    for (let i = 0; i < a.length; i++) {
      if (a[i] !== b[i] && ++diff > 1) return false;
    }
    return diff === 1;
  }
  const [short, long] = a.length < b.length ? [a, b] : [b, a];
  let diff = 0;
  let i = 0;
  let j = 0;
  while (i < short.length && j < long.length) {
    if (short[i] !== long[j]) {
      if (++diff > 1) return false;
      j++;
    } else {
      i++;
      j++;
    }
  }
  return true;
}

export function findEmoji(name: string, guild: Guild): GuildEmoji | undefined {
  const emojis = [...guild.emojis.cache.values()].filter((e) => e.available && e.name);
  const exact = emojis.find((e) => e.name === name);
  if (exact) return exact;
  const lower = name.toLowerCase();
  const caseMatch = emojis.find((e) => e.name!.toLowerCase() === lower);
  if (caseMatch) return caseMatch;
  if (lower.length >= 3) {
    return emojis.find((e) => isDistanceOne(lower, e.name!.toLowerCase()));
  }
}

export function discordEmoji(text: string, guild: Guild): string {
  return text.replace(/<a?:\w+:\d+>|(?<!\w):([a-zA-Z0-9_]+):?/g, (token, name: string | undefined) => {
    if (!name) return token;
    const emoji = findEmoji(name, guild);
    return emoji ? String(emoji) : token;
  });
}

export function reactionEmoji(raw: string, guild: Guild): string {
  const token = raw.trim();
  const name = token.replace(/^:|:$/g, "");
  const emoji = findEmoji(name, guild);
  return emoji?.identifier ?? token;
}

const ALL_EMOJIS_REGEX = /^(?:(?:<a?:\w+:\d+>|[\p{Extended_Pictographic}\p{Emoji_Modifier}\uFE0E\uFE0F\u200D])|\s)+$/u;
const TRAILING_EMOJI_REGEX = /^([\s\S]*?[^\s<])\s*((?:(?:<a?:\w+:\d+>|[\p{Extended_Pictographic}\p{Emoji_Modifier}\uFE0E\uFE0F\u200D])+[\s]*)+)$/u;

export function extractTrailingEmojis(text: string): { body: string; emojis: string } | null {
  const trimmed = text.trim();
  if (!trimmed || ALL_EMOJIS_REGEX.test(trimmed)) return null;
  const match = trimmed.match(TRAILING_EMOJI_REGEX);
  if (!match) return null;
  const [, body, emojis] = match;
  if (!body.trim()) return null;
  return { body: body.trimEnd(), emojis: emojis.trim() };
}
