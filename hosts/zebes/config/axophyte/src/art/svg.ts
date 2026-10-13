import { join } from "node:path";
import { MediaFailure, run, withTemp } from "../media/exec";

const MAX_SVG_CHARS = 60_000;
const RENDER_WIDTH = 1024;
const RENDER_TIMEOUT_MS = 20_000;

/** The SVG in the last fenced block (or the whole text when unfenced), or null when incomplete. */
export function extractSvg(text: string): string | null {
  const blocks = [...text.matchAll(/```[^\n]*\n([\s\S]*?)```/g)];
  const body = blocks.at(-1)?.[1] ?? text;
  const start = body.indexOf("<svg");
  const end = body.lastIndexOf("</svg>");
  return start === -1 || end < start ? null : body.slice(start, end + "</svg>".length);
}

/**
 * Model-written SVG is shaped by Discord users and resvg reads local files, so only
 * self-contained drawings pass. Returns a fix-it sentence for the model, or null.
 */
export function checkSvg(svg: string): string | null {
  if (svg.length > MAX_SVG_CHARS) return `the SVG is over ${MAX_SVG_CHARS} characters; simplify it`;
  if (/<!DOCTYPE|<!ENTITY/i.test(svg)) return "remove the DOCTYPE/ENTITY declarations";
  const banned = /<(?:[\w-]+:)?(image|script|foreignObject|iframe)\b/i.exec(svg);
  if (banned) return `<${banned[1]}> is not allowed; draw it with shapes`;
  if (/\bhref\s*=\s*["'](?!#)/i.test(svg)) return "href may only point inside the file (href=\"#id\")";
  if (/url\((?!\s*["']?\s*#)/i.test(svg)) return "url() may only point inside the file (url(#id))";
  if (/@import/i.test(svg)) return "CSS @import is not allowed";
  return null;
}

/** PNG bytes of a checked SVG; fonts come only from fontsDir. */
export async function renderSvg(svg: string, fontsDir: string): Promise<Uint8Array> {
  const png = await withTemp(async (_input, dir) => {
    const file = join(dir, "art.svg");
    await Bun.write(file, svg);
    return run([
      "resvg", "--skip-system-fonts", "--use-fonts-dir", fontsDir,
      "--font-family", "DejaVu Sans", "--sans-serif-family", "DejaVu Sans",
      "--serif-family", "DejaVu Serif", "--monospace-family", "DejaVu Sans Mono",
      "--resources-dir", dir, "-w", String(RENDER_WIDTH), file, "-c",
    ], RENDER_TIMEOUT_MS);
  });
  if (!png.byteLength) throw new MediaFailure("resvg produced no image");
  return png;
}
