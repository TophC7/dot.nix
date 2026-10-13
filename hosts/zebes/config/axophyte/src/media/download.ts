import { MediaFailure } from "./exec";
import { dataUrl, discordUrl, IMAGE_MAX_SIDE, MAX_IMAGE_BYTES, mime } from "./media";
import type { Media } from "./media";

export const nativeImageTypes: Record<string, true> = {
  "image/png": true,
  "image/jpeg": true,
  "image/gif": true,
  "image/bmp": true,
};

async function fetchCapped(
  raw: string, maxBytes: number, timeoutMs: number,
): Promise<{ body: Response; type: string } | null> {
  const url = discordUrl(raw);
  if (!url) return null;
  const response = await fetch(url.href, {
    redirect: "error",
    signal: AbortSignal.timeout(timeoutMs),
  });
  if (!response.ok) {
    await response.body?.cancel();
    return null;
  }
  if (Number(response.headers.get("content-length")) > maxBytes) {
    await response.body?.cancel().catch(() => {});
    throw new MediaFailure("Download exceeds byte limit", false, " - too large");
  }
  if (!response.body) return null;
  let size = 0;
  const cap = new TransformStream<Uint8Array, Uint8Array>({
    transform(chunk, controller) {
      size += chunk.byteLength;
      if (size > maxBytes) {
        throw new MediaFailure("Download exceeds byte limit", false, " - too large");
      }
      controller.enqueue(chunk);
    },
  });
  return {
    body: new Response(response.body.pipeThrough(cap)),
    type: mime(response.headers.get("content-type")),
  };
}

export async function download(
  raw: string, maxBytes: number, timeoutMs: number,
): Promise<{ bytes: Uint8Array; type: string } | null> {
  const r = await fetchCapped(raw, maxBytes, timeoutMs);
  if (!r) return null;
  const bytes = await r.body.bytes();
  return bytes.length ? { bytes, type: r.type } : null;
}

export async function downloadFile(
  raw: string, input: string, maxBytes: number, timeoutMs: number,
): Promise<string | null> {
  const r = await fetchCapped(raw, maxBytes, timeoutMs);
  return r && await Bun.write(input, r.body) ? r.type : null;
}

export async function loadImage(
  a: Pick<Media, "url" | "proxyURL" | "contentType" | "size" | "width" | "height">,
): Promise<string | null> {
  const type = a.contentType;
  if (!type || (!Object.hasOwn(nativeImageTypes, type) && type !== "image/webp")) return null;
  if ((a.size ?? 0) > MAX_IMAGE_BYTES) return null;
  const width = a.width ?? 0;
  const height = a.height ?? 0;
  const longest = Math.max(width, height);
  const proxy = type === "image/webp" || longest > IMAGE_MAX_SIDE;
  const url = discordUrl(proxy ? a.proxyURL : a.url);
  if (!url) return null;
  if (proxy) {
    const scale = Math.min(1, IMAGE_MAX_SIDE / longest);
    if (width > 0 && Number.isFinite(width)) {
      url.searchParams.set("width", String(Math.max(1, Math.floor(width * scale))));
    }
    if (height > 0 && Number.isFinite(height)) {
      url.searchParams.set("height", String(Math.max(1, Math.floor(height * scale))));
    }
    if (type === "image/webp") url.searchParams.set("format", "png");
  }
  const loaded = await download(url.href, MAX_IMAGE_BYTES, 20_000);
  if (!loaded) return null;
  if (!Object.hasOwn(nativeImageTypes, loaded.type)) throw new MediaFailure("Unsupported image response");
  return dataUrl(loaded.type, loaded.bytes);
}
