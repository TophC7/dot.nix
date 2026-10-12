import { limits } from "../limits";
import { run } from "./exec";

// Only self-contained formats and local inputs: no HLS, concat, image2, or network reads.
const SAFE_INPUT = [
  "-protocol_whitelist", "file",
  "-format_whitelist", "mov,matroska,gif,ogg,mp3,wav,flac,aac,png_pipe,jpeg_pipe,webp_pipe,bmp_pipe",
];
const FFMPEG = ["ffmpeg", "-nostdin", "-hide_banner", "-v", "error"];

export type Probe = {
  duration: number | null;
  videoDuration: number | null;
  video: boolean;
  audio: boolean;
  frames: number | null;
};

export async function probe(input: string, countFrames: boolean): Promise<Probe | null> {
  const bytes = await run([
    "ffprobe", "-hide_banner", "-v", "error", ...SAFE_INPUT,
    ...(countFrames ? ["-count_frames"] : []),
    "-show_entries", "format=duration:stream=codec_type,duration,nb_read_frames", "-of", "json", input,
  ], limits.processTimeoutMs);
  if (!bytes.length) return null;
  try {
    const data: unknown = JSON.parse(new TextDecoder().decode(bytes));
    if (typeof data !== "object" || data === null || Array.isArray(data)) return null;
    let duration: number | null = null;
    const format = "format" in data ? data.format : undefined;
    if (format !== undefined) {
      if (typeof format !== "object" || format === null || Array.isArray(format)) return null;
      const rawDuration = "duration" in format ? format.duration : undefined;
      if (rawDuration !== undefined && typeof rawDuration !== "string") return null;
      const seconds = Number(rawDuration);
      if (Number.isFinite(seconds) && seconds > 0) duration = seconds;
    }
    const rawStreams = "streams" in data ? data.streams : undefined;
    if (rawStreams !== undefined && !Array.isArray(rawStreams)) return null;
    const streams: unknown[] = rawStreams ?? [];
    let video = false;
    let audio = false;
    let videoDuration: number | null = null;
    let frames: number | null = null;
    for (const stream of streams) {
      if (typeof stream !== "object" || stream === null || Array.isArray(stream)) return null;
      const kind = "codec_type" in stream ? stream.codec_type : undefined;
      const rawDuration = "duration" in stream ? stream.duration : undefined;
      const rawFrames = "nb_read_frames" in stream ? stream.nb_read_frames : undefined;
      if ((kind !== undefined && typeof kind !== "string") ||
        (rawDuration !== undefined && typeof rawDuration !== "string") ||
        (rawFrames !== undefined && typeof rawFrames !== "string")) return null;
      if (kind === "video" && !video) {
        const seconds = Number(rawDuration);
        const count = Number(rawFrames);
        if (Number.isFinite(seconds) && seconds > 0) videoDuration = seconds;
        if (Number.isFinite(count)) frames = count;
        video = true;
      }
      if (kind === "audio") audio = true;
    }
    return { duration, videoDuration, video, audio, frames };
  } catch {
    return null;
  }
}

export function stillTimes(duration: number): [number, number, number, number] {
  return [duration / 8, (duration * 3) / 8, (duration * 5) / 8, (duration * 7) / 8];
}

export function clock(seconds: number): string {
  return `${Math.floor(seconds / 60)}:${(seconds % 60).toFixed(1).padStart(4, "0")}`;
}

export async function sheet(input: string, times: [number, number, number, number]): Promise<string | null> {
  const filters = times.map((_, k) =>
    `[${k}:v]scale=768:768:force_original_aspect_ratio=decrease,pad=768:768:(ow-iw)/2:(oh-ih)/2,setsar=1[v${k}]`,
  );
  filters.push("[v0][v1][v2][v3]xstack=inputs=4:layout=0_0|768_0|0_768|768_768");
  const bytes = await run([
    ...FFMPEG, ...times.flatMap((t) => [...SAFE_INPUT, "-ss", t.toFixed(3), "-i", input]),
    "-filter_complex", filters.join(";"), "-frames:v", "1", "-c:v", "mjpeg", "-q:v", "3", "-f", "image2pipe", "pipe:1",
  ], limits.processTimeoutMs);
  return bytes.length ? `data:image/jpeg;base64,${Buffer.from(bytes.buffer, bytes.byteOffset, bytes.byteLength).toString("base64")}` : null;
}

export async function still(input: string): Promise<string | null> {
  const bytes = await run([
    ...FFMPEG, ...SAFE_INPUT, "-i", input, "-frames:v", "1",
    "-vf", `scale='min(${limits.imageMaxSide},iw)':'min(${limits.imageMaxSide},ih)':force_original_aspect_ratio=decrease`,
    "-c:v", "png", "-f", "image2pipe", "pipe:1",
  ], limits.processTimeoutMs);
  return bytes.length ? `data:image/png;base64,${Buffer.from(bytes.buffer, bytes.byteOffset, bytes.byteLength).toString("base64")}` : null;
}

export async function speech(input: string, dir: string): Promise<string | null> {
  const wav = `${dir}/audio.wav`;
  await run([
    ...FFMPEG, ...SAFE_INPUT, "-i", input, "-vn", "-ac", "1", "-ar", "16000",
    "-t", String(limits.transcribeSeconds), "-c:a", "pcm_s16le", "-f", "wav", wav,
  ], limits.processTimeoutMs);
  return await Bun.file(wav).exists() ? wav : null;
}
