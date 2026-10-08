import {
  DiscordAPIError,
  messageLink,
  SnowflakeUtil,
  type APIMessage,
  type RESTGetAPIGuildMessagesSearchResult,
} from "discord.js";
import { asHistory, byId, excerpt, speakerLine } from "./context";
import { limits } from "./limits";
import { label, relevant } from "./memory";
import { stringArg, toolError, type Tool } from "./tools";
import { cleanText, discloses, placeFromApi, placeOf } from "./visibility";

// undefined = not given, null = invalid.
function dayToSnowflake(day: string | null): string | null | undefined {
  if (day === null) return undefined;
  const timestamp = /^\d{4}-\d{2}-\d{2}$/.test(day) ? Date.parse(`${day}T00:00:00Z`) : NaN;
  return Number.isNaN(timestamp) ? null : SnowflakeUtil.generate({ timestamp }).toString();
}

export const searchServerTool: Tool = {
  budget: limits.toolBudgets.search_server,
  schema: {
    type: "function",
    function: {
      name: "search_server",
      description: "Keyword search over older messages in this Discord server. Returns hit refs (h1, h2, …) for read_conversation. If nothing is found, try other wording.",
      parameters: {
        type: "object",
        properties: {
          query: { type: "string", description: "Keywords to look for" },
          person: { type: "string", description: "Optional @username to limit results to their messages" },
          after: { type: "string", description: "Optional YYYY-MM-DD; only messages on or after this day" },
          before: { type: "string", description: "Optional YYYY-MM-DD; only messages before this day" },
        },
        required: ["query"],
      },
    },
  },
  async run(args, ctx) {
    const query = stringArg(args, "query", 200);
    if (!query) return toolError("invalid arguments");
    const params = new URLSearchParams({ content: query, limit: "25", sort_by: "relevance", author_type: "-webhook" });
    const person = stringArg(args, "person", 100);
    if (person) {
      const handle = person.replace(/^@/, "").toLowerCase();
      const member = ctx.guild.members.cache.find((candidate) => candidate.user.username.toLowerCase() === handle);
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
      data = await ctx.guild.client.rest.get(`/guilds/${ctx.guild.id}/messages/search`, { query: params, signal: ctx.signal }) as RESTGetAPIGuildMessagesSearchResult;
    } catch (error) {
      if (error instanceof DiscordAPIError && (error.status === 403 || error.status === 404)) return toolError("server search unavailable");
      throw error;
    }
    if (!("messages" in data)) return toolError("server search index is still building; try again later");

    const audience = ctx.audience();
    const threads = data.threads ?? [];
    const hits: APIMessage[] = [];
    for (const [message] of data.messages) {
      if (!message || hits.length >= limits.serverHits) continue;
      if (message.webhook_id || (message.author.bot && message.author.id !== ctx.botId)) continue;
      if (message.channel_id === ctx.channel.id) continue;
      const place = placeFromApi(ctx.guild, message.channel_id, threads);
      // Hidden hits vanish entirely: no count, no placeholder.
      if (!place || !discloses(place, ctx.channel.id, audience)) continue;
      hits.push(message as APIMessage);
    }
    const lines = hits.map((message) => {
      const ref = `h${ctx.hits.size + 1}`;
      ctx.hits.set(ref, { channelId: message.channel_id, messageId: message.id });
      const thread = threads.find((candidate) => candidate.id === message.channel_id);
      const cached = ctx.guild.channels.cache.get(message.channel_id);
      const parentId = thread?.parent_id ?? (cached?.isThread() ? cached.parentId : null);
      const name = thread?.name ?? cached?.name ?? "unknown";
      const where = parentId ? `#${ctx.guild.channels.cache.get(parentId)?.name ?? "unknown"} › ${name}` : `#${name}`;
      const member = ctx.guild.members.cache.get(message.author.id);
      const who = message.author.id === ctx.botId
        ? "Axophyte"
        : label(member?.displayName ?? message.author.global_name ?? message.author.username, message.author.username);
      return `[${ref}] ${where} · ${who} · ${message.timestamp.slice(0, 10)}: "${excerpt(cleanText(message.content, ctx.channel), 200)}"`;
    });
    return { content: lines.length ? lines.join("\n") : "No results.", footer: `-# 🗂️ Searched server for “${query}”` };
  },
};

export const readConversationTool: Tool = {
  budget: limits.toolBudgets.read_conversation,
  schema: {
    type: "function",
    function: {
      name: "read_conversation",
      description: "Read the conversation around a search_server hit.",
      parameters: {
        type: "object",
        properties: { hit: { type: "string", description: "Hit ref from search_server, e.g. h2" } },
        required: ["hit"],
      },
    },
  },
  async run(args, ctx) {
    const target = ctx.hits.get(stringArg(args, "hit", 10) ?? "");
    if (!target) return toolError("unknown hit");
    const channel = await ctx.guild.client.channels.fetch(target.channelId).catch(() => null);
    if (!channel || channel.isDMBased() || !channel.isTextBased()) return toolError("unknown hit");
    // Recheck at read time: permissions may have changed since the search.
    const place = placeOf(channel);
    if (!place || !discloses(place, ctx.channel.id, ctx.audience())) return toolError("unknown hit");
    const fetched = await channel.messages.fetch({ around: target.messageId, limit: 15 });
    const history = relevant([...fetched.values()].sort(byId).map(asHistory), ctx.botId);
    const lines = history.map((message) => speakerLine(message, ctx.botId));
    const hitIndex = history.findIndex((message) => message.id === target.messageId);
    if (hitIndex < 0) return toolError("hit message no longer available");
    let start = 0;
    let end = lines.length;
    let total = lines.reduce((sum, line) => sum + line.length + 1, 0);
    while (total > limits.conversationChars && start < hitIndex) total -= lines[start++]!.length + 1;
    while (total > limits.conversationChars && end > hitIndex + 1) total -= lines[--end]!.length + 1;
    const summary = ctx.store.get(channel.id)?.summary;
    const transcript = lines.slice(start, end).join("\n").slice(0, limits.conversationChars);
    return {
      content: `${summary ? `Earlier summary:\n${summary.slice(0, 1500)}\n\n` : ""}${transcript || "No readable messages."}`,
      footer: `-# 💬 Read ${messageLink(target.channelId, target.messageId, ctx.guild.id)}`,
    };
  },
};
