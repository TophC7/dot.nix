import { defineTool } from "./tool";
import type { Tool } from "./tool";

export function selfInfoTool(model: () => string): Tool {
  return defineTool({
    name: "self_info",
    description: "Facts about Axophyte: identity, hosting, model, privacy, memory, and capabilities. Use for introductions and questions about yourself, before answering; don't guess.",
    properties: {},
    required: [],
    async run() {
      return {
        content: JSON.stringify({
          identity: "Axophyte, usually called Axo, is a Discord bot built by Toph.",
          author: "Toph",
          model: model(),
          inference: "Open-weights model running fully locally through llama.cpp on Toph's home server; no cloud AI inference.",
          transport: "Messages and attachments use Discord, an external service; local inference does not make Discord traffic local.",
          web: "Web searches send queries to Tavily. Opening pages sends URLs and any requested focus to Tavily for extraction; the bot does not fetch those pages itself.",
          participation: "Answers human messages in its configured forum. Elsewhere in configured servers, mentions and replies trigger it; active participants can follow up while an exchange is pending or running. It reads recent same-channel context and reply chains.",
          debounce: "Groups message bursts, waiting 4 seconds after messages or 10 seconds after participant typing, with a 45-second maximum wait.",
          serverSearch: "Searches older server messages only where the bot has access and every viewer of the reply channel can read the source. Private threads are excluded; search is unavailable when replying in a private thread.",
          memory: "Person notes are stored locally, separately per server, and learned only in channels readable by every server member. Notes can load elsewhere in that server. /memory show displays your notes; /memory forget deletes one or all. Long forum conversations retain summaries of older messages; other channels have no persistent conversation summaries.",
          emoji: "The model gradually describes custom server emoji and its own application emoji (usable in every server) from their image and name; some may not be described yet. Server admins can set meanings with /emoji, overriding model descriptions; a meaning for an own emoji applies in every server.",
          capabilities: "Can see supported attached images, search the web, read web pages, search accessible server history, remember person notes, and react to messages. No code-execution or filesystem-access tools, and no DM access.",
        }),
      };
    },
  });
}
