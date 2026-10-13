import { PROCESS_TIMEOUT_MS, run } from "./exec";
import { dataUrl, IMAGE_MAX_SIDE } from "./media";

/** Only the first this-many seconds of audio are transcribed. */
export const TRANSCRIBE_SECONDS = 180;

// Only self-contained formats and local inputs: no HLS, concat, image2, or network reads.
const SAFE_INPUT = [
  "-protocol_whitelist", "file",
  "-format_whitelist", "mov,matroska,gif,ogg,mp3,wav,flac,aac,png_pipe,jpeg_pipe,webp_pipe,bmp_pipe",
];
const FFMPEG = ["ffmpeg", "-nostdin", "-hide_banner", "-v", "error"];

export async function probe(input: string, countFrames: boolean) {
  const bytes = await run([
    "ffprobe", "-hide_banner", "-v", "error", ...SAFE_INPUT,
    ...(countFrames ? ["-count_frames"] : []),
    "-show_entries", "format=duration:stream=codec_type,duration,nb_read_frames", "-of", "json", input,
  ], PROCESS_TIMEOUT_MS);
  try {
    const data = JSON.parse(new TextDecoder().decode(bytes)) as {
      format?: { duration?: string };
      streams?: { codec_type?: string; duration?: string; nb_read_frames?: string }[];
    };
    function seconds(raw?: string): number | null {
      const value = Number(raw);
      return Number.isFinite(value) && value > 0 ? value : null;
    }
    const video = data.streams?.find((s) => s.codec_type === "video");
    return {
      duration: seconds(data.format?.duration),
      videoDuration: seconds(video?.duration),
      video: !!video,
      audio: !!data.streams?.some((s) => s.codec_type === "audio"),
      frames: video && Number.isFinite(Number(video.nb_read_frames)) ? Number(video.nb_read_frames) : null,
    };
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
  ], PROCESS_TIMEOUT_MS);
  return bytes.length ? dataUrl("image/jpeg", bytes) : null;
}

export async function still(input: string): Promise<string | null> {
  const bytes = await run([
    ...FFMPEG, ...SAFE_INPUT, "-i", input, "-frames:v", "1",
    "-vf", `scale='min(${IMAGE_MAX_SIDE},iw)':'min(${IMAGE_MAX_SIDE},ih)':force_original_aspect_ratio=decrease`,
    "-c:v", "png", "-f", "image2pipe", "pipe:1",
  ], PROCESS_TIMEOUT_MS);
  return bytes.length ? dataUrl("image/png", bytes) : null;
}

export async function speech(input: string, dir: string): Promise<string | null> {
  const wav = `${dir}/audio.wav`;
  await run([
    ...FFMPEG, ...SAFE_INPUT, "-i", input, "-vn", "-ac", "1", "-ar", "16000",
    "-t", String(TRANSCRIBE_SECONDS), "-c:a", "pcm_s16le", "-f", "wav", wav,
  ], PROCESS_TIMEOUT_MS);
  return await Bun.file(wav).exists() ? wav : null;
}
