import type { ChatMessage } from "../llm/protocol";
import { TurnAborted } from "../abort";
import { MediaFailure } from "../media/exec";
import { dataUrl } from "../media/media";
import { clip } from "../text";
import { checkSvg, extractSvg, renderSvg } from "./svg";

/** One art-only completion: no chat history, no persona. */
export type Complete = (messages: ChatMessage[]) => Promise<string>;
type Drawing = { svg: string; png: Uint8Array };

const FENCE = "```";

export const EXAMPLE_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#1e1b4b"/>
      <stop offset="0.5" stop-color="#7c3aed"/>
      <stop offset="0.8" stop-color="#f472b6"/>
      <stop offset="1" stop-color="#fdba74"/>
    </linearGradient>
    <radialGradient id="glow">
      <stop offset="0" stop-color="#fde68a" stop-opacity="0.8"/>
      <stop offset="1" stop-color="#fde68a" stop-opacity="0"/>
    </radialGradient>
    <filter id="grain"><feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="3" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/></filter>
  </defs>
  <g id="background">
    <rect width="800" height="800" fill="url(#sky)"/>
    <circle cx="560" cy="430" r="160" fill="url(#glow)"/>
    <circle cx="560" cy="430" r="70" fill="#fde68a"/>
  </g>
  <g id="midground">
    <polygon points="0,520 180,330 330,480 470,360 640,500 800,400 800,800 0,800" fill="#8a72c8"/>
    <path d="M0 600 Q200 520 400 590 Q600 660 800 570 L800 800 L0 800 Z" fill="#3b2f6b"/>
  </g>
  <g id="foreground">
    <ellipse cx="230" cy="672" rx="70" ry="10" fill="#1e1b4b" opacity="0.35"/>
    <rect x="222" y="560" width="16" height="110" fill="#2d1b4e"/>
    <polygon points="230,420 300,580 160,580" fill="#1f3d3a"/>
    <polygon points="230,380 285,500 175,500" fill="#2a5550"/>
    <path d="M0 700 Q400 650 800 710 L800 800 L0 800 Z" fill="#1e1b4b"/>
  </g>
  <g id="effects">
    <rect width="800" height="800" filter="url(#grain)" opacity="0.08"/>
  </g>
</svg>`;

// Probed live against the local model; the numbered PLAN stands in for reasoning, which is off.
const ARTIST_GUIDE = `You are an illustrator who draws by writing SVG code. You can't see while you write, so plan every position with numbers first, then write the code.

Canvas and code
- Root element: <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800">. (0,0) is the top-left corner, (800,800) the bottom-right, (400,400) the center. Keep important shapes between 40 and 760.
- Whole numbers for coordinates and sizes.
- Later elements cover earlier ones. Write layers back to front: <g id="background">, <g id="midground">, <g id="foreground">, <g id="details">, <g id="effects">.
- Start with a full-canvas background rect (solid or gradient).
- Build from primitives: rect (rx for rounded corners), circle, ellipse, polygon, polyline, line. Use path for curves; keep each path short, use absolute commands (M L Q C A Z), and close filled shapes with Z.
- Repeat or tilt parts with <defs> + <use href="#id"> and transform="translate(x y)", "rotate(deg cx cy)", "scale(s)".
- Effects allowed: linearGradient, radialGradient, pattern, clipPath, mask, filter (feGaussianBlur, feOffset, feFlood, feComposite, feMerge, feDropShadow, feTurbulence, feColorMatrix, feBlend). References stay inside the file: href="#id", url(#id).
- Never use <image>, links to files or websites, data: URLs, <script>, <foreignObject>, CSS @import, or DOCTYPE/ENTITY declarations. Animation is pointless: the result is a still picture.
- Text only when the request asks for words, in "DejaVu Sans", "DejaVu Serif", or "DejaVu Sans Mono". No emoji characters.

Drawing well
- Composition: one clear main subject, large (about half the canvas), centered or on a thirds line (x or y near 267 or 533). A few big shapes read better than many tiny ones.
- Creatures and people: overlapping shapes, body first, then head, then limbs. Every limb starts inside the body so nothing floats; eyes, nose, and mouth sit inside the head outline, drawn after it. Mirror symmetric parts around a center line (x = c - d and x = c + d).
- Proportions: fix sizes relative to the main body before coding (cute animals: head about 2/3 of body width, short legs).
- Color: pick a palette of 4 to 6 hex colors first (dark, mid, light, accent). Touching parts get distinct colors. No white shapes on a white background.
- Light: one light direction, top-left unless the scene says otherwise. Lit side lighter and warmer; shadow side tinted dark blue or purple (#1e1b4b, #2d1b4e) at opacity 0.2 to 0.4, never pure black or gray.
- Gradients: 3 to 5 stops with a slight hue shift; round objects get a radialGradient with fx="0.35" fy="0.3".
- Objects standing on ground get a contact shadow: a flat dark ellipse at their base.
- Scenes: far layers lighter, bluer, and less saturated; near layers darker and more saturated. Opaque layers hide what is behind them; use opacity only for glow, haze, and shadows.
- Glow (sun, lamps, magic): a larger circle behind the shape filled with a radialGradient that fades to stop-opacity="0".
- Texture for painterly pictures: add this filter in <defs> and the rect as the last element:
  <filter id="grain"><feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="3" stitchTiles="stitch"/><feColorMatrix type="saturate" values="0"/></filter>
  <rect width="800" height="800" filter="url(#grain)" opacity="0.08"/>

Styles that work (follow the request if it names one)
- Flat illustration: solid fills, one shadow tone and one highlight tone per object; optional dark outlines with stroke-width 4 to 6 and stroke-linejoin="round".
- Layered landscape: gradient sky, sun or moon with glow, 2 to 4 overlapping hill or mountain silhouettes from far to near, foreground details.
- Emblem, badge, or logo: symmetric around (400,400), concentric circles or a shield, one bold simple symbol, 2 or 3 colors.
- Pixel art: 50x50 rects on a 16x16 grid, flat colors, no gradients; draw only the cells that differ from the background.
- Line art or icon: fill="none", one stroke color and width, stroke-linecap="round", stroke-linejoin="round".
- Silhouette: one dark color for all foreground shapes against a gradient sky.

Example, a dusk landscape:
${FENCE}svg
${EXAMPLE_SVG}
${FENCE}`;

const draftPrompt = (request: string) => `Draw: ${request}

Answer in this order, with no other talk:
PLAN
1. Scene: one or two sentences on exactly what is visible, the style, and the palette as hex colors.
2. Parts: every object with ALL its parts, and the SVG element for each part.
3. Layout: for every part, its position and size in canvas numbers (centers, radii, widths, points) and what it overlaps or connects to.
Then the complete SVG in one ${FENCE}svg code block.`;

const revisePrompt = (previous: { request: string; svg: string }, change: string) => `Here is your current drawing of: ${previous.request}
${FENCE}svg
${previous.svg}
${FENCE}
Change it: ${change}

Keep everything the change doesn't touch. Answer in this order, with no other talk:
PLAN: each change, naming the elements you add, remove, or modify, with canvas numbers.
Then the complete new SVG in one ${FENCE}svg code block.`;

const repairPrompt = (error: string) => `That SVG could not be rendered: ${error}
Fix it and reply with only the complete corrected SVG in one ${FENCE}svg code block.`;

const reviewPrompt = (request: string) => `This image is the render of your SVG. Look at it as a viewer who never saw the code, and compare it with the request: "${request}".
Answer in this order, with no other talk:
SEEN: one line describing what the image actually shows.
PROBLEMS: every visual problem: parts detached or floating, parts hidden behind others or drawn in the wrong order, shapes that don't read as what they should be, wrong proportions, things cut off at the canvas edge, colors that blend together, empty or cluttered composition, anything the request asked for that is missing.
Then the complete improved SVG in one ${FENCE}svg code block. Fix the problems by editing the existing elements; rewrite from scratch only if the picture is unrecognizable. If nothing needs fixing, repeat the SVG unchanged.`;

/** The rendered drawing in a reply, or the error sentence the model gets to repair. */
async function rendered(text: string, fontsDir: string): Promise<Drawing | string> {
  const svg = extractSvg(text);
  if (!svg) return "no complete <svg>…</svg> element found";
  const problem = checkSvg(svg);
  if (problem) return problem;
  try {
    return { svg, png: await renderSvg(svg, fontsDir) };
  } catch (error) {
    if (error instanceof MediaFailure) return error.message;
    throw error;
  }
}

/** Draft (plus one repair if it won't render), then optional vision review whose fix must render. */
export async function paint(input: {
  /** What the review compares the picture against. */
  request: string;
  /** Set for revisions. */
  previous?: { request: string; svg: string };
  /** The revision instruction. */
  change?: string;
  fontsDir: string;
  complete: Complete;
  supportsImages: boolean;
  onDraft?: (png: Uint8Array) => void;
}): Promise<Drawing & { seen: string | null }> {
  const { request, previous, change, fontsDir, complete } = input;
  const messages: ChatMessage[] = [
    { role: "system", content: ARTIST_GUIDE },
    { role: "user", content: previous ? revisePrompt(previous, change ?? request) : draftPrompt(request) },
  ];
  let text = await complete(messages);
  let draft = await rendered(text, fontsDir);
  if (typeof draft === "string") {
    messages.push({ role: "assistant", content: text }, { role: "user", content: repairPrompt(draft) });
    text = await complete(messages);
    draft = await rendered(text, fontsDir);
    if (typeof draft === "string") throw new Error(`couldn't render the drawing: ${draft}`);
  }
  if (!input.supportsImages) return { ...draft, seen: null };
  input.onDraft?.(draft.png);

  messages.push({ role: "assistant", content: text }, {
    role: "user",
    content: [
      { type: "text", text: reviewPrompt(request) },
      { type: "image_url", image_url: { url: dataUrl("image/png", draft.png) } },
    ],
  });
  let review: string;
  try {
    review = await complete(messages);
  } catch (error) {
    if (error instanceof TurnAborted) throw error;
    return { ...draft, seen: null }; // the draft is still a finished picture
  }
  const seenLine = /^SEEN:\s*(.+)$/m.exec(review)?.[1];
  const seen = seenLine ? clip(seenLine, 300) : null;
  const final = await rendered(review, fontsDir);
  return { ...(typeof final === "string" ? draft : final), seen };
}
