import { paint } from "../art/artist";
import type { Complete } from "../art/artist";
import type { ReplyFile } from "../discord/reply";
import { clip } from "../text";
import { defineTool, stringArg, toolError } from "./tool";
import type { Tool } from "./tool";

const ART_PROMPT_CHARS = 1500;
const ART_REQUEST_CHARS = 3000;
const ART_MEMORY_CHANNELS = 50;

// Axophyte never sees its own posted images, so this is the only basis for revisions; lost on restart.
const memory = new Map<string, { request: string; svg: string }>();

export function drawTool(opts: {
  channelId: string;
  fontsDir: string;
  complete: Complete;
  supportsImages: boolean;
  onCommit(): void;
  preview(text: string, file: ReplyFile): void;
}): Tool {
  return defineTool({
    name: "draw",
    budget: 1,
    description: "Draw a picture and attach it to your reply, with its SVG file. A separate drawing session writes SVG that gets rendered; it takes a few minutes. Use when someone asks you to draw, sketch, paint, design, or make art, an image, a logo, or an icon. The drawing session can't see this chat or any images, so put everything it needs in prompt.",
    properties: {
      title: { type: "string", description: "Short name for the picture, 2 to 6 words" },
      prompt: { type: "string", description: "What to draw: subject, details, style, colors, mood, composition. With revise, only the change." },
      revise: { type: "boolean", description: "true to change your last drawing in this channel instead of starting over" },
    },
    required: ["title", "prompt", "revise"],
    status: (args) => `🎨 drawing “${stringArg(args, "title", 80) ?? "something"}”, takes a few minutes…`,
    async run(args) {
      const title = stringArg(args, "title", 80);
      const prompt = stringArg(args, "prompt", ART_PROMPT_CHARS);
      if (!title || !prompt || typeof args.revise !== "boolean") return toolError("invalid arguments");
      // Minutes of drawing must not be thrown away by a follow-up message.
      opts.onCommit();
      const previous = args.revise ? memory.get(opts.channelId) : undefined;
      const request = previous ? clip(`${previous.request}; then changed: ${prompt}`, ART_REQUEST_CHARS) : prompt;
      const { svg, png, seen } = await paint({
        request, previous, change: prompt, fontsDir: opts.fontsDir, complete: opts.complete, supportsImages: opts.supportsImages,
        onDraft: (draft) => opts.preview(`🎨 draft of “${title}” done, touching it up…`, { attachment: Buffer.from(draft.buffer, draft.byteOffset, draft.byteLength), name: "draft.png" }),
      });

      memory.delete(opts.channelId);
      memory.set(opts.channelId, { request, svg });
      if (memory.size > ART_MEMORY_CHANNELS) memory.delete(memory.keys().next().value!);

      const base = title.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 40).replace(/-+$/, "") || "drawing";
      return {
        content: JSON.stringify({
          drawn: true,
          revised: !!previous,
          ...(args.revise && !previous ? { note: "no earlier drawing remembered in this channel, so this one is new" } : {}),
          looks_like: seen,
          ...(!opts.supportsImages ? { review: "Rendered from SVG without visual review: this model cannot see images." } : {}),
          attached: [`${base}.png`, `${base}.svg`],
          instructions: "The picture and its SVG are attached to your reply. Don't paste SVG code; say something short about it in your own voice.",
        }),
        footer: `-# 🎨 Drew “${title}”`,
        files: [{ attachment: Buffer.from(png.buffer, png.byteOffset, png.byteLength), name: `${base}.png` }, { attachment: Buffer.from(svg), name: `${base}.svg` }],
      };
    },
  });
}
