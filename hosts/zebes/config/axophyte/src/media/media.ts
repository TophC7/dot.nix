import type { APIEmbed, Attachment, Message } from "discord.js";
import { discordUrl } from "./download";

export type MediaKind = "image" | "gif" | "video" | "audio" | "pdf" | "document" | "file";
export type Media = {
  /** Attachment ID; embeds use message:embed:index, forwarded embeds message:fwd:snapshot:embed:index. */
  id: string;
  kind: MediaKind;
  /** Filename, or the linked URL for embeds. */
  name: string;
  /** Download URL: Discord CDN for attachments, Discord proxy for embeds. */
  url: string;
  /** Discord media proxy URL (resizing); equals url for embeds. */
  proxyURL: string;
  contentType: string | null;
  size: number | null;
  width: number | null;
  height: number | null;
  alt: string | null;
  voice: boolean;
  linked: boolean;
  forwarded: boolean;
};
/** What the model gets for one media item. Absent from the map = not shown. */
export type Seen = { image?: string; detail?: string; body?: string };

export const documentExtensions: readonly string[] = ["docx", "odt", "rtf", "epub"];

export function classify(name: string, contentType: string | null): MediaKind {
  const ct = contentType?.split(";")[0]?.trim().toLowerCase() ?? "";
  const ext = name.split(".").at(-1)?.toLowerCase();
  if (ct === "image/gif" || ext === "gif") return "gif";
  if (ct.startsWith("image/")) return "image";
  if (ct.startsWith("video/")) return "video";
  if (ct.startsWith("audio/")) return "audio";
  if (ct === "application/pdf" || ext === "pdf") return "pdf";
  if (ext && documentExtensions.includes(ext)) return "document";
  return "file";
}

export function embedMedia(embed: APIEmbed, id: string, forwarded: boolean): Media | null {
  let asset;
  let kind: MediaKind;
  switch (embed.type) {
    case "image":
      asset = embed.thumbnail ?? embed.image;
      try {
        kind = asset && /\.gif$/i.test(new URL(asset.url).pathname) ? "gif" : "image";
      } catch {
        return null;
      }
      break;
    case "gifv":
      asset = discordUrl(embed.video?.proxy_url ?? "") ? embed.video : embed.thumbnail;
      kind = "gif";
      break;
    case "video":
      asset = embed.video;
      kind = "video";
      break;
    default:
      return null;
  }
  if (!asset?.proxy_url || !discordUrl(asset.proxy_url)) return null;
  return {
    id, kind, name: embed.url ?? asset.url ?? asset.proxy_url,
    url: asset.proxy_url, proxyURL: asset.proxy_url,
    contentType: null, size: null, width: asset.width ?? null, height: asset.height ?? null,
    alt: null, voice: false, linked: true, forwarded,
  };
}

function attachmentMedia(a: Attachment, forwarded: boolean): Media {
  return {
    id: a.id, kind: classify(a.name, a.contentType), name: a.name,
    url: a.url, proxyURL: a.proxyURL, contentType: a.contentType, size: a.size,
    width: a.width, height: a.height, alt: a.description, voice: a.waveform !== null,
    linked: false, forwarded,
  };
}

export function mediaOf(message: Message): Media[] {
  const media = [...message.attachments.values()].map((a) => attachmentMedia(a, false));
  message.embeds.forEach((embed, i) => {
    const m = embedMedia(embed.data, `${message.id}:embed:${i}`, false);
    if (m) media.push(m);
  });
  [...message.messageSnapshots.values()].forEach((snapshot, s) => {
    media.push(...[...snapshot.attachments.values()].map((a) => attachmentMedia(a, true)));
    snapshot.embeds.forEach((embed, i) => {
      const m = embedMedia(embed.data, `${message.id}:fwd:${s}:embed:${i}`, true);
      if (m) media.push(m);
    });
  });
  return media;
}

export function mediaTag(m: Media): string {
  if (m.voice) return `${m.forwarded ? "forwarded " : ""}voice message`;
  return `${m.forwarded ? "forwarded " : ""}${m.linked ? "linked " : ""}${m.kind}: ${m.name}`;
}

export function mediaHeader(m: Media, seen: Seen | undefined): string {
  const header = `[${mediaTag(m)}${m.alt ? `, alt: "${m.alt}"` : ""}${seen ? seen.detail ?? "" : " - not shown"}]`;
  return seen?.body ? `${header}\n<<<\n${seen.body}\n>>>` : header;
}
