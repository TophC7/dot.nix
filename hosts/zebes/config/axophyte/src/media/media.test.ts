import { expect, test } from "bun:test";
import { EmbedType, type APIEmbed } from "discord.js";
import { embedMedia } from "./media";
import type { Media } from "./media";

// Only Discord-proxied direct media may be fetched; site previews stay text.
test("embeds expose only direct media through Discord proxies", () => {
  const thumbnail = { url: "https://example.com/image.png", proxy_url: "https://images-ext-1.discordapp.net/image.png" };
  const video = { url: "https://example.com/video.mp4", proxy_url: "https://media.discordapp.net/video.mp4" };
  const cases: [APIEmbed, Partial<Media> | null][] = [
    [{ type: EmbedType.Image, thumbnail }, { kind: "image", url: thumbnail.proxy_url }],
    [{ type: EmbedType.Image, image: { ...thumbnail, url: "https://example.com/animated.GIF" } }, { kind: "gif", url: thumbnail.proxy_url }],
    [{ type: EmbedType.GIFV, thumbnail, video }, { kind: "gif", url: video.proxy_url }],
    [{ type: EmbedType.GIFV, thumbnail, video: { ...video, proxy_url: "https://example.com/video.mp4" } }, { kind: "gif", url: thumbnail.proxy_url }],
    [{ type: EmbedType.Video, video }, { kind: "video", url: video.proxy_url }],
    [{ type: EmbedType.Video, url: "https://youtube.com/watch?v=id", video: { url: "https://youtube.com/embed/id" }, thumbnail }, null],
    [{ type: EmbedType.Article, thumbnail }, null],
    [{ type: EmbedType.Rich, thumbnail }, null],
    [{ type: EmbedType.Link, thumbnail }, null],
    [{ type: EmbedType.Image, thumbnail: { ...thumbnail, proxy_url: "https://example.com/image.png" } }, null],
  ];
  for (const [embed, expected] of cases) {
    const media = embedMedia(embed, "message:embed:0", false);
    if (expected === null) expect(media).toBeNull();
    else expect(media).toMatchObject({
      ...expected, id: "message:embed:0", proxyURL: expected.url, linked: true, forwarded: false,
    });
  }
});
