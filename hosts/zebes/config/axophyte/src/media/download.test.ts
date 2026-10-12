import { afterEach, expect, mock, spyOn, test } from "bun:test";
import { download, downloadFile, loadImage } from "./download";
import { limits } from "../limits";
import { withTemp } from "./exec";
import { MediaFailure } from "./failure";

afterEach(() => mock.restore());

test("unsupported, oversized, and non-Discord image URLs never reach fetch", async () => {
  let fetchCalls = 0;
  spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => {
    fetchCalls++;
    throw new Error("fetch must not run");
  }, { preconnect: fetch.preconnect }));
  const attachment = {
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

test("external embed URLs never reach fetch", async () => {
  let fetchCalls = 0;
  spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => {
    fetchCalls++;
    throw new Error("fetch must not run");
  }, { preconnect: fetch.preconnect }));
  for (const url of [
    "https://images-ext-1.discordapp.net.evil.com/image.png",
    "https://example.com/image.png",
    "http://images-ext-1.discordapp.net/image.png",
    "https://images-ext-x.discordapp.net/image.png",
  ]) {
    expect(await download(url, limits.maxImageBytes, 20_000)).toBeNull();
  }
  expect(fetchCalls).toBe(0);
});

test("stream byte caps cancel reader and remove incomplete files", async () => {
  let canceled = 0;
  spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => {
    let chunks = 0;
    return new Response(new ReadableStream<Uint8Array>({
      pull(controller) {
        controller.enqueue(new Uint8Array([1, 2, 3, 4]));
        chunks++;
        if (chunks === 3) controller.close();
      },
      cancel() { canceled++; },
    }, { highWaterMark: 0 }), { headers: { "content-type": "APPLICATION/OCTET-STREAM; charset=binary" } });
  }, { preconnect: fetch.preconnect }));
  const url = "https://cdn.discordapp.com/attachments/capped.bin";
  await expect(download(url, 6, 20_000)).rejects.toBeInstanceOf(MediaFailure);
  await withTemp(async (input) => {
    try {
      await downloadFile(url, input, 6, 20_000);
      throw new Error("byte cap accepted oversized stream");
    } catch (error) {
      expect(error).toBeInstanceOf(MediaFailure);
      if (error instanceof MediaFailure) {
        expect(error.retryable).toBe(false);
        expect(error.detail).toBe(" - too large");
      }
    }
    expect(await Bun.file(input).exists()).toBe(false);
  });
  expect(canceled).toBe(2);
});

test("file receiver preserves bytes while awaiting each file write", async () => {
  spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => {
    let chunk = 0;
    return new Response(new ReadableStream<Uint8Array>({
      pull(controller) {
        controller.enqueue(new Uint8Array([chunk++, 255]));
        if (chunk === 3) controller.close();
      },
    }, { highWaterMark: 0 }), { headers: { "content-type": "TEXT/PLAIN; charset=utf-8" } });
  }, { preconnect: fetch.preconnect }));
  await withTemp(async (input) => {
    expect(await downloadFile("https://media.discordapp.net/attachments/text", input, 6, 20_000))
      .toEqual({ type: "text/plain", size: 6 });
    expect(await Bun.file(input).bytes()).toEqual(new Uint8Array([0, 255, 1, 255, 2, 255]));
  });
});
