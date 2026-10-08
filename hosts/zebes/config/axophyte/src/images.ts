import { limits } from "./limits";

const imageTypes: Record<string, true> = {
  "image/png": true,
  "image/jpeg": true,
  "image/gif": true,
  "image/bmp": true,
};
const hosts: Record<string, true> = {
  "cdn.discordapp.com": true,
  "media.discordapp.net": true,
};
const cache = new Map<string, string>();

type Attachment = {
  id: string;
  url: string;
  proxyURL: string;
  contentType: string | null;
  size: number;
  width: number | null;
  height: number | null;
  name: string;
};

export async function loadImage(
  a: Attachment,
  fetchFn: (input: Parameters<typeof fetch>[0], init?: Parameters<typeof fetch>[1]) => Promise<Response> = fetch,
): Promise<string | null> {
  const type = a.contentType?.split(";")[0]?.trim().toLowerCase();
  if (!type || (!Object.hasOwn(imageTypes, type) && type !== "image/webp")) return null;
  if (a.size > limits.maxImageBytes) return null;

  try {
    const width = a.width ?? 0;
    const height = a.height ?? 0;
    const longest = Math.max(width, height);
    const proxy = type === "image/webp" || longest > limits.imageMaxSide;
    const url = new URL(proxy ? a.proxyURL : a.url);
    if (
      url.protocol !== "https:" || !Object.hasOwn(hosts, url.hostname) ||
      url.username || url.password || (url.port && url.port !== "443")
    ) return null;

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

    const key = `${a.id}:${url.href}`;
    const cached = cache.get(key);
    if (cached !== undefined) return cached;
    const response = await fetchFn(url.href, {
      redirect: "error",
      signal: AbortSignal.timeout(20_000),
    });
    const responseType = response.headers.get("content-type")?.split(";")[0]?.trim().toLowerCase();
    const declaredBytes = Number(response.headers.get("content-length"));
    if (
      !response.ok || !responseType || !Object.hasOwn(imageTypes, responseType) ||
      declaredBytes > limits.maxImageBytes
    ) {
      await response.body?.cancel();
      return null;
    }
    if (!response.body) return null;

    const reader = response.body.getReader();
    const chunks: Uint8Array[] = [];
    let bytes = 0;
    try {
      while (true) {
        const chunk = await reader.read();
        if (chunk.done) break;
        bytes += chunk.value.byteLength;
        if (bytes > limits.maxImageBytes) {
          await reader.cancel();
          return null;
        }
        chunks.push(chunk.value);
      }
    } finally {
      reader.releaseLock();
    }
    if (!bytes) return null;
    const data = `data:${responseType};base64,${Buffer.concat(chunks, bytes).toString("base64")}`;
    cache.set(key, data);
    if (cache.size > 64) cache.delete(cache.keys().next().value!);
    return data;
  } catch {
    return null;
  }
}
