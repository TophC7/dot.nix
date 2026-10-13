import { afterEach, expect, mock, spyOn, test } from "bun:test";
import { TurnAborted } from "../abort";
import type { Media } from "./media";
import { seeMedia } from "./see";

// Real file-backed loading; only Discord transport is replaced.
afterEach(() => mock.restore());

function history(): Media[] {
  const id = crypto.randomUUID();
  const media: Media = {
    id, kind: "file", name: "message.txt",
    url: `https://cdn.discordapp.com/attachments/${id}/message.txt`,
    proxyURL: `https://media.discordapp.net/attachments/${id}/message.txt`,
    contentType: "text/plain", size: null, width: null, height: null,
    alt: null, voice: false, linked: false, forwarded: false,
  };
  return [media];
}

test("canceled waiter exits before shared download finishes; next turn reuses job", async () => {
  const started = Promise.withResolvers<void>();
  const release = Promise.withResolvers<void>();
  let fetchCalls = 0;
  spyOn(globalThis, "fetch").mockImplementation(Object.assign(async (_url: string | URL | Request, options?: RequestInit) => {
    fetchCalls++;
    const transfer = options?.signal;
    const abort = () => release.reject(transfer?.reason);
    transfer?.addEventListener("abort", abort, { once: true });
    started.resolve();
    try { await release.promise; }
    finally { transfer?.removeEventListener("abort", abort); }
    return new Response("shared work survives cancellation");
  }, { preconnect: fetch.preconnect }));
  const messages = history();
  const id = messages[0]!.id;
  const controller = new AbortController();
  const obsolete = seeMedia(messages, "unused-model", controller.signal);
  await started.promise;
  controller.abort();
  try {
    await expect(obsolete).rejects.toBeInstanceOf(TurnAborted);
    const current = seeMedia(messages, "unused-model");
    release.resolve();
    expect((await current).get(id)).toEqual({ body: "shared work survives cancellation" });
    expect(fetchCalls).toBe(1);
  } finally {
    release.resolve();
  }
});

test("already canceled turn starts no media work", async () => {
  let fetchCalls = 0;
  spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => {
    fetchCalls++;
    return new Response("must not download");
  }, { preconnect: fetch.preconnect }));
  const controller = new AbortController();
  controller.abort();
  await expect(seeMedia(history(), "unused-model", controller.signal)).rejects.toBeInstanceOf(TurnAborted);
  expect(fetchCalls).toBe(0);
});

test("permanent binary and transfer-cap failures are cached across turns", async () => {
  let fetchCalls = 0;
  let tooLarge = false;
  spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => {
    fetchCalls++;
    return tooLarge
      ? new Response("too large", { headers: { "content-length": String(2 ** 40) } })
      : new Response(new Uint8Array([0xff, 0x00]));
  }, { preconnect: fetch.preconnect }));
  const binary = history();
  const binaryId = binary[0]!.id;
  expect((await seeMedia(binary, "unused-model")).get(binaryId)).toEqual({ detail: " - unsupported" });
  await seeMedia(binary, "unused-model");
  tooLarge = true;
  const oversized = history();
  const oversizedId = oversized[0]!.id;
  expect((await seeMedia(oversized, "unused-model")).get(oversizedId)).toEqual({ detail: " - too large" });
  await seeMedia(oversized, "unused-model");
  expect(fetchCalls).toBe(2);
});

test("unknown network failures retry next turn rather than poisoning cache", async () => {
  let fetchCalls = 0;
  spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => {
    if (++fetchCalls === 1) throw new Error("network disconnected");
    return new Response("retry succeeded");
  }, { preconnect: fetch.preconnect }));
  const messages = history();
  const id = messages[0]!.id;
  expect((await seeMedia(messages, "unused-model")).size).toBe(0);
  expect((await seeMedia(messages, "unused-model")).get(id)).toEqual({ body: "retry succeeded" });
  expect(fetchCalls).toBe(2);
});
