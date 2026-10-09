import { DiscordAPIError, messageLink, SnowflakeUtil } from "discord.js";
import type { APIMessage, GuildTextBasedChannel, RESTGetAPIGuildMessagesSearchResult } from "discord.js";
import { asHistory, byId, excerpt } from "../conversation/load";
import { speakerLine } from "../conversation/prompt";
import { limits } from "../limits";
import { label, relevant } from "../conversation/history";
import { defineTool, stringArg, toolError } from "./tool";
import type { Tool } from "./tool";
import type { Store } from "../memory/store";
import { audienceOf, cleanText, discloses, placeFromApi, placeOf } from "../discord/visibility";
import { botTime, calendarMidnight, dayAge, TIME_ZONE } from "../time";

// undefined = not given, null = invalid.
function dayToSnowflake(day: string | null): string | null | undefined {
  if (day === null) return undefined;
  const timestamp = calendarMidnight(day);
  return Number.isNaN(timestamp) ? null : SnowflakeUtil.generate({ timestamp }).toString();
}

/** `inView`: message IDs already in the prompt; search skips them, not the rest of this channel. */
export function serverTools(channel: GuildTextBasedChannel, store: Store, inView: Set<string>): Tool[] {
  const hits = new Map<string, { channelId: string; messageId: string }>();
  let cached: string[] | undefined;
  const audience = () => cached ??= audienceOf(channel);
  const guild = channel.guild;
  const botId = channel.client.user.id;

  const searchServer = defineTool({
    name: "search_server",
    description: "Keyword search over older messages in this server, for things people refer to that are not in view. Returns hits (h1, h2, …) for read_conversation; if none, try other wording.",
    properties: {
      query: { type: "string" },
      person: { type: "string", description: "Optional @username to limit results to their messages" },
      after: { type: "string", description: `Optional YYYY-MM-DD in ${TIME_ZONE}; only messages on or after this day` },
      before: { type: "string", description: `Optional YYYY-MM-DD in ${TIME_ZONE}; only messages before this day` },
    },
    required: ["query"],
    async run(args, signal) {
      const query = stringArg(args, "query", 200);
      if (!query) return toolError("invalid arguments");
      const params = new URLSearchParams({ content: query, limit: "25", sort_by: "relevance", author_type: "-webhook" });
      const person = stringArg(args, "person", 100);
      if (person) {
        const handle = person.replace(/^@/, "").toLowerCase();
        const member = guild.members.cache.find((candidate) => candidate.user.username.toLowerCase() === handle);
        if (!member) return toolError(`unknown person ${person}`);
        params.set("author_id", member.id);
      }
      const minId = dayToSnowflake(stringArg(args, "after", 10));
      const maxId = dayToSnowflake(stringArg(args, "before", 10));
      if (minId === null || maxId === null) return toolError("dates must be YYYY-MM-DD");
      if (minId) params.set("min_id", minId);
      if (maxId) params.set("max_id", maxId);

      let data: RESTGetAPIGuildMessagesSearchResult;
      try {
        data = await guild.client.rest.get(`/guilds/${guild.id}/messages/search`, { query: params, signal }) as RESTGetAPIGuildMessagesSearchResult;
      } catch (error) {
        if (error instanceof DiscordAPIError && (error.status === 403 || error.status === 404)) return toolError("server search unavailable");
        throw error;
      }
      if (!("messages" in data)) return toolError("server search index is still building; try again later");

      const viewers = audience();
      const threads = data.threads ?? [];
      const messages: APIMessage[] = [];
      for (const [message] of data.messages) {
        if (!message || messages.length >= limits.serverHits) continue;
        if (message.webhook_id || (message.author.bot && message.author.id !== botId)) continue;
        if (inView.has(message.id)) continue;
        const place = placeFromApi(guild, message.channel_id, threads);
        // Hidden hits vanish entirely: no count, no placeholder.
        if (!place || !discloses(place, channel.id, viewers)) continue;
        messages.push(message as APIMessage);
      }
      const now = Date.now();
      const lines = messages.map((message) => {
        const ref = `h${hits.size + 1}`;
        hits.set(ref, { channelId: message.channel_id, messageId: message.id });
        const thread = threads.find((candidate) => candidate.id === message.channel_id);
        const cached = guild.channels.cache.get(message.channel_id);
        const parentId = thread?.parent_id ?? (cached?.isThread() ? cached.parentId : null);
        const name = thread?.name ?? cached?.name ?? "unknown";
        const where = parentId ? `#${guild.channels.cache.get(parentId)?.name ?? "unknown"} › ${name}` : `#${name}`;
        const member = guild.members.cache.get(message.author.id);
        const who = message.author.id === botId
          ? "Axophyte"
          : label(member?.displayName ?? message.author.global_name ?? message.author.username, message.author.username);
        const clock = botTime(Date.parse(message.timestamp));
        return `[${ref}] ${where} · ${who} · ${dayAge(clock.day, now)} ${clock.time}: "${excerpt(cleanText(message.content, channel), 200)}"`;
      });
      return { content: lines.length ? lines.join("\n") : "No results.", footer: `-# 🗂️ Searched server for “${query}”` };
    },
  });

  const readConversation = defineTool({
    name: "read_conversation",
    description: "Read the conversation around a search_server hit.",
    properties: { hit: { type: "string", description: "e.g. h2" } },
    required: ["hit"],
    async run(args) {
      const target = hits.get(stringArg(args, "hit", 10) ?? "");
      if (!target) return toolError("unknown hit");
      const found = await guild.client.channels.fetch(target.channelId).catch(() => null);
      if (!found || found.isDMBased() || !found.isTextBased()) return toolError("unknown hit");
      // Recheck at read time: permissions may have changed since the search.
      const place = placeOf(found);
      if (!place || !discloses(place, channel.id, audience())) return toolError("unknown hit");
      const fetched = await found.messages.fetch({ around: target.messageId, limit: 15 });
      const history = relevant([...fetched.values()].sort(byId).map(asHistory), botId);
      const now = Date.now();
      const lines = history.map((message, index) => speakerLine(message, botId, history[index - 1], now));
      const hitIndex = history.findIndex((message) => message.id === target.messageId);
      if (hitIndex < 0) return toolError("hit message no longer available");
      let start = 0;
      let end = lines.length;
      let total = lines.reduce((sum, line) => sum + line.length + 1, 0);
      while (total > limits.conversationChars && start < hitIndex) total -= lines[start++]!.length + 1;
      while (total > limits.conversationChars && end > hitIndex + 1) total -= lines[--end]!.length + 1;
      const summary = store.get(found.id)?.summary;
      const transcript = history.slice(start, end).map((message, index, visible) => speakerLine(message, botId, visible[index - 1], now)).join("\n").slice(0, limits.conversationChars);
      return {
        content: `${summary ? `Earlier summary:\n${summary.slice(0, 1500)}\n\n` : ""}${transcript || "No readable messages."}`,
        footer: `-# 💬 Read ${messageLink(target.channelId, target.messageId, guild.id)}`,
      };
    },
  });
  return [searchServer, readConversation];
}
