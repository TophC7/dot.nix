import { abortWait, throwIfAborted } from "../abort";
import { downloadFile, loadImage, nativeImageTypes } from "./download";
import { DOCUMENT_CHARS, documentText, sniffText } from "./documents";
import { MediaFailure, withTemp } from "./exec";
import { clock, probe, sheet, speech, still, stillTimes, TRANSCRIBE_SECONDS } from "./ffmpeg";
import { dataUrl, discordUrl, IMAGE_MAX_SIDE, MAX_IMAGE_BYTES } from "./media";
import type { Media, Seen } from "./media";
import { clip } from "../text";
import { transcribe } from "./whisper";

/** Per prompt, newest first: images (stills grids included), files read as text, and transcripts. */
const MAX_IMAGES = 4;
const MAX_DOCUMENTS = 4;
const MAX_TRANSCRIPTS = 2;
/** Loaded media kept in memory across turns, oldest evicted first. */
const CACHE_ENTRIES = 64;
const TRANSCRIPT_CHARS = 4000;
const DOWNLOAD_TIMEOUT_MS = 60_000;

type Loaded = { seen: Seen | null; retry: boolean };

// ponytail: count-bounded only (~50-150 MB typical, ~850 MB if every entry is a 10 MB original); track bytes if Zebes RAM gets tight.
const cache = new Map<string, Promise<Seen | null>>();
const caps = {
  image: MAX_IMAGE_BYTES, gif: 50 * 1024 * 1024, video: 50 * 1024 * 1024,
  audio: 25 * 1024 * 1024, pdf: 25 * 1024 * 1024, document: 25 * 1024 * 1024, file: 1024 * 1024,
};

/** Capture one independent component without losing another component's usable output. */
async function attempt<T>(fn: () => Promise<T | null>): Promise<{ value: T | null; retry: boolean }> {
  try { return { value: await fn(), retry: false }; }
  catch (error) { return { value: null, retry: !(error instanceof MediaFailure) || error.retryable }; }
}

/** Speech → transcript; null when the input has no decodable audio. */
async function listen(input: string, dir: string, duration: number | null, model: string): Promise<Seen | null> {
  const wav = await speech(input, dir);
  if (!wav) return null;
  const text = await transcribe(wav, model);
  if (!text) return { detail: ", no speech" };
  return {
    detail: `, transcript${duration !== null && duration > TRANSCRIBE_SECONDS ? ` (first ${TRANSCRIBE_SECONDS / 60} min)` : ""}`,
    body: clip(text, TRANSCRIPT_CHARS),
  };
}

async function moving(input: string, dir: string, gif: boolean, wantTranscript: boolean, model: string): Promise<Loaded> {
  const info = await probe(input, gif);
  if (!info) return { seen: { detail: " - unsupported" }, retry: false };
  const result: Seen = {};
  let retry = false;
  if (info.video) {
    const duration = info.videoDuration ?? info.duration;
    let imageRetry = false;
    if ((!gif || (info.frames ?? 0) > 1) && duration !== null && duration >= 0.5) {
      const times = stillTimes(duration);
      const grid = await attempt(() => sheet(input, times));
      imageRetry = grid.retry;
      if (grid.value) {
        result.image = grid.value;
        result.detail = `, ${clock(duration)}, stills at ${times.map(clock).join(", ")} left to right, top to bottom`;
      }
    }
    if (!result.image) {
      const frame = await attempt(() => still(input));
      imageRetry ||= frame.retry;
      if (frame.value) {
        result.image = frame.value;
        result.detail = ", first frame";
      }
    }
    retry ||= imageRetry;
    if (!result.image) result.detail = imageRetry ? ", image unavailable" : ", image unsupported";
  } else {
    result.detail = ", video unsupported";
  }
  let hasHeard = false;
  if (wantTranscript && info.audio) {
    const heard = await attempt(() => listen(input, dir, info.duration, model));
    retry ||= heard.retry;
    if (heard.value) {
      result.detail = `${result.detail ?? ""}${heard.value.detail}`;
      result.body = heard.value.body;
      hasHeard = true;
    } else {
      result.detail = `${result.detail ?? ""}${heard.retry ? ", transcript unavailable" : ", transcript unsupported"}`;
    }
  }
  return {
    seen: result.image || hasHeard ? result : retry ? null : { detail: " - unsupported" },
    retry,
  };
}

async function loadMedia(m: Media, wantTranscript: boolean, model: string): Promise<Loaded> {
  const cap = caps[m.kind];
  if (m.size !== null && m.size > cap) return { seen: { detail: " - too large" }, retry: false };
  if (!discordUrl(m.url)) return { seen: { detail: " - unsupported" }, retry: false };
  const declared = m.contentType;
  if (m.kind === "image" && !m.linked && declared && declared !== "image/gif" &&
    (Object.hasOwn(nativeImageTypes, declared) || declared === "image/webp")) {
    const image = await loadImage(m);
    return { seen: image ? { image } : null, retry: !image };
  }
  return withTemp(async (input, dir) => {
    const type = await downloadFile(m.url, input, cap, DOWNLOAD_TIMEOUT_MS);
    if (type === null) return { seen: null, retry: true };
    let seen: Seen;
    switch (m.kind) {
      case "image": {
        if (type === "image/gif") return moving(input, dir, true, false, model);
        if (Object.hasOwn(nativeImageTypes, type) && m.width !== null && m.height !== null &&
          m.width <= IMAGE_MAX_SIDE && m.height <= IMAGE_MAX_SIDE) {
          const bytes = await Bun.file(input).bytes();
          seen = { image: dataUrl(type, bytes) };
        } else {
          const image = await still(input);
          seen = image ? { image } : { detail: " - unsupported" };
        }
        break;
      }
      case "gif":
      case "video":
        return moving(input, dir, m.kind === "gif", wantTranscript, model);
      case "audio": {
        const info = await probe(input, false);
        if (!info?.audio) return { seen: { detail: " - unsupported" }, retry: false };
        const heard = await listen(input, dir, info.duration, model);
        if (!heard) return { seen: { detail: " - unsupported" }, retry: false };
        seen = { ...heard, detail: `${info.duration !== null ? `, ${clock(info.duration)}` : ""}${heard.detail}` };
        break;
      }
      case "pdf":
      case "document": {
        const body = await documentText(input, m.kind, m.name.split(".").at(-1)?.toLowerCase() ?? "");
        seen = body === null ? { detail: " - unsupported" } : body ? { body } : { detail: ", no extractable text" };
        break;
      }
      case "file": {
        const text = sniffText(await Bun.file(input).bytes());
        seen = text === null ? { detail: " - unsupported" } : { body: clip(text, DOCUMENT_CHARS) };
        break;
      }
    }
    return { seen, retry: false };
  });
}

export async function seeMedia(
  media: Media[], whisperModel: string, signal?: AbortSignal,
): Promise<Map<string, Seen>> {
  throwIfAborted(signal);
  let images = 0;
  let documents = 0;
  let transcripts = 0;
  const grants: { m: Media; wantTranscript: boolean }[] = [];
  for (let i = media.length - 1; i >= 0; i--) {
    const m = media[i]!;
    let wantTranscript = false;
    switch (m.kind) {
      case "image":
      case "gif":
      case "video":
        if (images >= MAX_IMAGES) continue;
        images++;
        if (m.kind === "video" && transcripts < MAX_TRANSCRIPTS) {
          transcripts++;
          wantTranscript = true;
        }
        break;
      case "audio":
        if (transcripts >= MAX_TRANSCRIPTS) continue;
        transcripts++;
        wantTranscript = true;
        break;
      default:
        if (documents >= MAX_DOCUMENTS) continue;
        documents++;
    }
    grants.push({ m, wantTranscript });
    if (images >= MAX_IMAGES && documents >= MAX_DOCUMENTS &&
      transcripts >= MAX_TRANSCRIPTS) break;
  }
  const results = await abortWait(Promise.all(grants.map(({ m, wantTranscript }) => {
    const key = JSON.stringify([m.id, m.url, wantTranscript ? whisperModel : null]);
    const cached = cache.get(key);
    if (cached) return cached;
    const promise = loadMedia(m, wantTranscript, whisperModel).catch((error: unknown): Loaded => ({
      seen: error instanceof MediaFailure && !error.retryable ? { detail: error.detail } : null,
      retry: !(error instanceof MediaFailure) || error.retryable,
    })).then(({ seen, retry }) => {
      if (retry && cache.get(key) === promise) cache.delete(key);
      return seen;
    });
    cache.set(key, promise);
    if (cache.size > CACHE_ENTRIES) cache.delete(cache.keys().next().value!);
    return promise;
  })), signal);
  const seen = new Map<string, Seen>();
  results.forEach((result, i) => { if (result !== null) seen.set(grants[i]!.m.id, result); });
  return seen;
}
