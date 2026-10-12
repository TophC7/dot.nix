import { open, rm } from "node:fs/promises";
import { limits } from "../limits";
import { MediaFailure } from "./failure";
import type { Media } from "./media";

export const nativeImageTypes: Record<string, true> = {
  "image/png": true,
  "image/jpeg": true,
  "image/gif": true,
  "image/bmp": true,
};

export function discordUrl(raw: string): URL | null {
  try {
    const url = new URL(raw);
    if (
      url.protocol !== "https:" || url.username || url.password || (url.port && url.port !== "443") ||
      !(url.hostname === "cdn.discordapp.com" || url.hostname === "media.discordapp.net" ||
        /^images-ext-\d+\.discordapp\.net$/.test(url.hostname))
    ) return null;
    return url;
  } catch {
    return null;
  }
}

async function receive(
  raw: string, maxBytes: number, timeoutMs: number,
  write: (chunk: Uint8Array) => Promise<void>,
): Promise<{ type: string; size: number } | null> {
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
  const reader = response.body.getReader();
  let size = 0;
  try {
    while (true) {
      const chunk = await reader.read();
      if (chunk.done) break;
      size += chunk.value.byteLength;
      if (size > maxBytes) {
        throw new MediaFailure("Download exceeds byte limit", false, " - too large");
      }
      await write(chunk.value);
    }
  } finally {
    try { await reader.cancel().catch(() => {}); }
    finally { reader.releaseLock(); }
  }
  return size ? {
    size,
    type: response.headers.get("content-type")?.split(";")[0]?.trim().toLowerCase() ?? "",
  } : null;
}

export async function download(
  raw: string, maxBytes: number, timeoutMs: number,
): Promise<{ bytes: Uint8Array; type: string } | null> {
  const chunks: Uint8Array[] = [];
  const loaded = await receive(raw, maxBytes, timeoutMs, async (chunk) => { chunks.push(chunk); });
  return loaded ? { bytes: Buffer.concat(chunks, loaded.size), type: loaded.type } : null;
}

export async function downloadFile(
  raw: string, input: string, maxBytes: number, timeoutMs: number,
): Promise<{ type: string; size: number } | null> {
  if (!discordUrl(raw)) return null;
  const file = await open(input, "w");
  let complete = false;
  try {
    const loaded = await receive(raw, maxBytes, timeoutMs, async (chunk) => {
      let offset = 0;
      while (offset < chunk.byteLength) {
        const { bytesWritten } = await file.write(chunk, offset, chunk.byteLength - offset);
        if (!bytesWritten) throw new Error("Download file write made no progress");
        offset += bytesWritten;
      }
    });
    complete = loaded !== null;
    return loaded;
  } finally {
    try { await file.close(); }
    finally { if (!complete) await rm(input, { force: true }); }
  }
}

export async function loadImage(
  a: Pick<Media, "url" | "proxyURL" | "contentType" | "size" | "width" | "height">,
): Promise<string | null> {
  const type = a.contentType?.split(";")[0]?.trim().toLowerCase();
  if (!type || (!Object.hasOwn(nativeImageTypes, type) && type !== "image/webp")) return null;
  if ((a.size ?? 0) > limits.maxImageBytes) return null;
  const width = a.width ?? 0;
  const height = a.height ?? 0;
  const longest = Math.max(width, height);
  const proxy = type === "image/webp" || longest > limits.imageMaxSide;
  const url = discordUrl(proxy ? a.proxyURL : a.url);
  if (!url) return null;
  if (proxy) {
    const scale = Math.min(1, limits.imageMaxSide / longest);
    if (width > 0 && Number.isFinite(width)) {
      url.searchParams.set("width", String(Math.max(1, Math.floor(width * scale))));
    }
    if (height > 0 && Number.isFinite(height)) {
      url.searchParams.set("height", String(Math.max(1, Math.floor(height * scale))));
    }
    if (type === "image/webp") url.searchParams.set("format", "png");
  }
  const loaded = await download(url.href, limits.maxImageBytes, 20_000);
  if (!loaded) return null;
  if (!Object.hasOwn(nativeImageTypes, loaded.type)) throw new MediaFailure("Unsupported image response");
  return `data:${loaded.type};base64,${Buffer.from(loaded.bytes.buffer, loaded.bytes.byteOffset, loaded.bytes.byteLength).toString("base64")}`;
}
