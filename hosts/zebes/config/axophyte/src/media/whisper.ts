import { MediaFailure, run } from "./exec";

const WHISPER_TIMEOUT_MS = 180_000;

// ponytail: one whisper at a time; CPU-bound, the 5600G can't run two usefully.
let queue: Promise<unknown> = Promise.resolve();

export function transcribe(wav: string, model: string): Promise<string> {
  const result = queue.then(async () => {
    const bytes = await run([
      "whisper-cli", "-m", model, "-f", wav, "-l", "auto", "-t", "6", "-nt", "-np",
    ], WHISPER_TIMEOUT_MS);
    const text = new TextDecoder().decode(bytes).replaceAll("[BLANK_AUDIO]", "")
      .split("\n").map((line) => line.trim()).filter(Boolean).join("\n");
    // Whisper can emit punctuation alone for tones or silence; that contains no speech.
    return /[\p{L}\p{N}]/u.test(text) ? text : "";
  }).catch(() => { throw new MediaFailure("Transcription failed", true); });
  queue = result.catch(() => {});
  return result;
}
