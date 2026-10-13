import { TRANSCRIBE_SECONDS } from "../media/ffmpeg";
import { documentExtensions } from "../media/media";
import { BURST_MAX_WAIT_MS, BURST_QUIET_MS, BURST_TYPING_MS } from "../schedule";
import type { ModelClient } from "../llm/client";
import { defineTool } from "./tool";
import type { Tool } from "./tool";

export function selfInfoTool(model: Pick<ModelClient, "id" | "label" | "provider" | "supportsImages">): Tool {
  return defineTool({
    name: "self_info",
    budget: 1,
    description: "Facts about Axophyte: identity, hosting, model, privacy, memory, and capabilities. Use for introductions and questions about yourself, before answering; don't guess.",
    properties: {},
    required: [],
    async run() {
      return {
        content: JSON.stringify({
          identity: "Axophyte, usually called Axo, is a Discord bot built by Toph.",
          author: "Toph",
          model: model.label,
          modelId: model.id,
          provider: model.provider,
          supportsImages: model.supportsImages,
          modelCommands: "Server admins use /model to view or change the bot-wide model; every restart starts local. /codex-login lets the Discord application owner (also a server admin) connect the shared Codex subscription using a private device code and browser approval. Tokens stay on the bot, never in chat. Login does not change the selected model.",
          inference: model.provider === "local"
            ? "Open-weights model running fully locally through llama.cpp on Toph's home server; no cloud AI inference for this turn."
            : `Cloud inference through ${model.provider}${model.provider === "openai-codex" ? " using a ChatGPT subscription, not an OpenAI API key" : " using its API"}. Model selection applies bot-wide to future jobs and resets to local on restart.`,
          transport: model.provider === "local"
            ? "Messages and attachments use Discord, an external service; attachment processing (stills, transcripts, text extraction) and this turn's inference run locally."
            : "Messages and attachments use Discord. Attachment processing (stills, transcripts, text extraction) runs locally; this turn's Discord context, person notes, conversation memory, and attachment content can be sent to the selected cloud provider.",
          web: "Web searches send queries to Tavily. Opening pages sends URLs and any requested focus to Tavily for extraction; the bot does not fetch those pages itself.",
          participation: "Answers human messages in its configured forum and active Discord threads (threads started from an Axophyte message or where Axophyte was mentioned). Elsewhere in configured servers, mentions (including a ping of Axophyte's own bot role) and replies trigger it; @everyone and other role pings do not. Active participants can follow up while an exchange is pending or running. It reads recent same-channel context and reply chains.",
          debounce: `Groups message bursts, waiting ${BURST_QUIET_MS / 1000} seconds after messages or ${BURST_TYPING_MS / 1000} seconds after participant typing, with a ${BURST_MAX_WAIT_MS / 1000}-second maximum wait.`,
          serverSearch: "Searches older server messages only where the bot has access and every viewer of the reply channel can read the source. Private threads are excluded; search is unavailable when replying in a private thread.",
          memory: `Person notes are stored locally, separately per server, and learned only in channels readable by every server member. Notes can load elsewhere in that server. /memory show displays your notes; /memory forget deletes one or all. Server admins can use /retry to have it answer the channel's newest human message again. Long forum and thread conversations retain summaries of older messages; other channels have no persistent conversation summaries.`,
          emoji: model.supportsImages
            ? "The model gradually describes custom server emoji and its own application emoji (usable in every server) from their image and name; some may not be described yet. Server admins can set meanings with /emoji, overriding model descriptions in their server only, including for its own emoji."
            : "Uses saved custom emoji descriptions and names. The selected model cannot describe emoji images; image-description jobs are skipped. Server admins can set meanings with /emoji.",
          capabilities: `${model.supportsImages ? "Can see attached images and images, GIFs, and videos linked in messages (read through Discord's own embed proxy, never from the linked site); videos and animated GIFs as a grid of four stills, falling back to the first frame if the grid fails." : "Cannot see images; image attachments and video stills are omitted from this model's input with an explicit notice."} Transcribes voice messages, audio, and video sound locally with whisper.cpp (first ${TRANSCRIBE_SECONDS / 60} minutes). Reads text and code files, PDFs, and ${documentExtensions.join("/")} documents, plus forwarded messages. Also searches the web, reads web pages, searches accessible server history, remembers person notes, and reacts to messages. Draws pictures on request: the selected model writes SVG, resvg renders it locally, and PNG plus SVG are posted${model.supportsImages ? " after a visual review" : " without visual review"}; it can revise its last drawing in a channel until restart. Can't read pptx or xlsx. No code-execution or filesystem-access tools, and no DM access.`,
        }),
      };
    },
  });
}
