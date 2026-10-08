import { afterEach, expect, mock, spyOn, test } from "bun:test";
import { loadImage } from "./images";
import { limits } from "../limits";

afterEach(() => mock.restore());

test("unsupported, oversized, and non-Discord image URLs never reach fetch", async () => {
  let fetchCalls = 0;
  spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => {
    fetchCalls++;
    throw new Error("fetch must not run");
  }, { preconnect: fetch.preconnect }));
  const attachment = {
    id: "image-boundary",
    url: "https://cdn.discordapp.com/attachments/image.png",
    proxyURL: "https://media.discordapp.net/attachments/image.png",
    contentType: "image/png",
    size: 100,
    width: 100,
    height: 100,
    name: "image.png",
  };
  const rejected = [
    { contentType: "text/plain" },
    { contentType: null },
    { size: limits.maxImageBytes + 1 },
    { url: "not a URL" },
    { url: "https://example.com/image.png" },
    { url: "https://cdn.discordapp.com.example.com/image.png" },
    { url: "http://cdn.discordapp.com/image.png" },
    { url: "https://cdn.discordapp.com:8443/image.png" },
    { url: "https://user:password@cdn.discordapp.com/image.png" },
    { width: 4096, proxyURL: "https://example.com/image.png" },
    { contentType: "image/webp", proxyURL: "https://example.com/image.webp" },
  ];
  for (const fields of rejected) {
    expect(await loadImage({ ...attachment, ...fields })).toBeNull();
  }
  expect(fetchCalls).toBe(0);
});
