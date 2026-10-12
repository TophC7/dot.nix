import { abortWait, throwIfAborted } from "../abort";
import type { HistoryMessage } from "../conversation/history";
import { limits } from "../limits";
import { discordUrl, downloadFile, loadImage, nativeImageTypes } from "./download";
import { documentText, sniffText } from "./documents";
import { withTemp } from "./exec";
import { MediaFailure } from "./failure";
import { clock, probe, sheet, speech, still, stillTimes } from "./ffmpeg";
import type { Media, Seen } from "./media";
import { clip } from "./text";
import { transcribe } from "./whisper";

type Loaded = { seen: Seen | null; retry: boolean };

// ponytail: count-bounded only (~50-150 MB typical, ~850 MB if every entry is a 10 MB original); track bytes if Zebes RAM gets tight.
const cache = new Map<string, Promise<Seen | null>>();
const caps = {
  image: limits.maxImageBytes, gif: limits.maxVideoBytes, video: limits.maxVideoBytes,
  audio: limits.maxAudioBytes, pdf: limits.maxDocumentBytes, document: limits.maxDocumentBytes, file: limits.maxTextBytes,
};

/** Capture one independent component without losing another component's usable output. */
async function attempt<T>(fn: () => Promise<T | null>): Promise<{ value: T | null; retry: boolean }> {
  try { return { value: await fn(), retry: false }; }
  catch (error) { return { value: null, retry: !(error instanceof MediaFailure) || error.retryable }; }
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
  let heard = false;
  if (wantTranscript && info.audio) {
    const transcript = await attempt(async () => {
      const wav = await speech(input, dir);
      if (!wav) return null;
      const text = await transcribe(wav, model);
      if (text === null) throw new MediaFailure("Transcription failed", true);
      return text;
    });
    retry ||= transcript.retry;
    if (transcript.value !== null) {
      heard = true;
      result.detail = `${result.detail ?? ""}${transcript.value ? ", transcript" : ", no speech"}`;
      if (transcript.value) {
        if (info.duration !== null && info.duration > limits.transcribeSeconds) {
          result.detail += ` (first ${limits.transcribeSeconds / 60} min)`;
        }
        result.body = clip(transcript.value, limits.transcriptChars);
      }
    } else {
      result.detail = `${result.detail ?? ""}${transcript.retry ? ", transcript unavailable" : ", transcript unsupported"}`;
    }
  }
  return {
    seen: result.image || heard ? result : retry ? null : { detail: " - unsupported" },
    retry,
  };
}

async function loadMedia(m: Media, wantTranscript: boolean, model: string): Promise<Loaded> {
  const cap = caps[m.kind];
  if (m.size !== null && m.size > cap) return { seen: { detail: " - too large" }, retry: false };
  if (!discordUrl(m.url)) return { seen: { detail: " - unsupported" }, retry: false };
  const type = m.contentType?.split(";")[0]?.trim().toLowerCase();
  if (m.kind === "image" && !m.linked && type && type !== "image/gif" &&
    (Object.hasOwn(nativeImageTypes, type) || type === "image/webp")) {
    const image = await loadImage(m);
    return { seen: image ? { image } : null, retry: !image };
  }
  return withTemp(async (input, dir) => {
    const loaded = await downloadFile(m.url, input, cap, limits.downloadTimeoutMs);
    if (!loaded) return { seen: null, retry: true };
    let seen: Seen;
    switch (m.kind) {
      case "image": {
        if (loaded.type === "image/gif") return moving(input, dir, true, false, model);
        if (Object.hasOwn(nativeImageTypes, loaded.type) && m.width !== null && m.height !== null &&
          m.width <= limits.imageMaxSide && m.height <= limits.imageMaxSide) {
          const bytes = await Bun.file(input).bytes();
          seen = { image: `data:${loaded.type};base64,${Buffer.from(bytes.buffer, bytes.byteOffset, bytes.byteLength).toString("base64")}` };
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
        if (!info) return { seen: { detail: " - unsupported" }, retry: false };
        if (!info.audio) return { seen: { detail: " - unsupported" }, retry: false };
        const wav = await speech(input, dir);
        if (!wav) return { seen: { detail: " - unsupported" }, retry: false };
        const text = await transcribe(wav, model);
        if (text === null) return { seen: null, retry: true };
        let detail = info.duration !== null ? `, ${clock(info.duration)}` : "";
        detail += text ? ", transcript" : ", no speech";
        if (text && info.duration !== null && info.duration > limits.transcribeSeconds) {
          detail += ` (first ${limits.transcribeSeconds / 60} min)`;
        }
        seen = { detail, ...(text ? { body: clip(text, limits.transcriptChars) } : {}) };
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
        seen = text === null ? { detail: " - unsupported" } : { body: clip(text, limits.documentChars) };
        break;
      }
    }
    return { seen, retry: false };
  });
}

export async function seeMedia(
  history: HistoryMessage[], botId: string, whisperModel: string, signal?: AbortSignal,
): Promise<Map<string, Seen>> {
  throwIfAborted(signal);
  let images = 0;
  let documents = 0;
  let transcripts = 0;
  const grants: { m: Media; wantTranscript: boolean }[] = [];
  messages: for (let i = history.length - 1; i >= 0; i--) {
    const message = history[i]!;
    if (message.authorId === botId) continue;
    for (let j = message.media.length - 1; j >= 0; j--) {
      const m = message.media[j]!;
      let wantTranscript = false;
      switch (m.kind) {
        case "image":
        case "gif":
        case "video":
          if (images >= limits.maxImagesPerRequest) continue;
          images++;
          if (m.kind === "video" && transcripts < limits.maxTranscriptsPerRequest) {
            transcripts++;
            wantTranscript = true;
          }
          break;
        case "audio":
          if (transcripts >= limits.maxTranscriptsPerRequest) continue;
          transcripts++;
          wantTranscript = true;
          break;
        default:
          if (documents >= limits.maxDocumentsPerRequest) continue;
          documents++;
      }
      grants.push({ m, wantTranscript });
      if (images >= limits.maxImagesPerRequest && documents >= limits.maxDocumentsPerRequest &&
        transcripts >= limits.maxTranscriptsPerRequest) break messages;
    }
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
    if (cache.size > limits.mediaCacheEntries) cache.delete(cache.keys().next().value!);
    return promise;
  })), signal);
  const seen = new Map<string, Seen>();
  results.forEach((result, i) => { if (result !== null) seen.set(grants[i]!.m.id, result); });
  return seen;
}
