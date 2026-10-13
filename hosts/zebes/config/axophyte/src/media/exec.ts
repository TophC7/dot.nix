import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { clippedText } from "../text";

export const PROCESS_TIMEOUT_MS = 60_000;

export class MediaFailure extends Error {
  constructor(
    message: string,
    readonly retryable = false,
    readonly detail: " - unsupported" | " - too large" = " - unsupported",
  ) {
    super(message);
    this.name = "MediaFailure";
  }
}

// The cause of a failure is printed last, so keep stderr's tail rather than its head.
async function stderrTail(stream: ReadableStream<Uint8Array>, max: number): Promise<string> {
  const decoder = new TextDecoder();
  let tail = "";
  for await (const chunk of stream) tail = (tail + decoder.decode(chunk, { stream: true })).slice(-max);
  return tail + decoder.decode();
}

async function execute<T>(
  cmd: string[], timeoutMs: number, capture: (stdout: ReadableStream<Uint8Array>) => Promise<T>,
): Promise<T> {
  const proc = Bun.spawn(cmd, {
    stdin: "ignore", stdout: "pipe", stderr: "pipe", timeout: timeoutMs, killSignal: "SIGKILL",
  });
  try {
    // stderr drains concurrently so a chatty child can't block on a full pipe.
    const [result, exit, errors] = await Promise.all([
      capture(proc.stdout), proc.exited, stderrTail(proc.stderr, 2000),
    ]);
    if (exit !== 0 || proc.signalCode !== null) {
      const line = errors.split("\n").map((l) => l.trim()).filter((l) => l && !l.startsWith("Warning")).at(-1);
      throw new MediaFailure(`${cmd[0]} failed (${proc.signalCode ?? exit})${line ? `: ${line}` : ""}`, proc.signalCode !== null);
    }
    return result;
  } catch (error) {
    if (proc.exitCode === null) {
      try { proc.kill("SIGKILL"); } catch { /* Child may have exited meanwhile. */ }
    }
    await proc.exited;
    await proc.stdout.cancel().catch(() => {});
    await proc.stderr.cancel().catch(() => {});
    throw error;
  }
}

export function run(cmd: string[], timeoutMs: number): Promise<Uint8Array> {
  return execute(cmd, timeoutMs, (stdout) => new Response(stdout).bytes());
}

export function runText(cmd: string[], timeoutMs: number, maxChars: number): Promise<string> {
  return execute(cmd, timeoutMs, (stdout) => clippedText(stdout, maxChars));
}

export async function withTemp<T>(fn: (input: string, dir: string) => Promise<T>): Promise<T> {
  const dir = await mkdtemp(join(tmpdir(), "axo-"));
  try {
    return await fn(join(dir, "input"), dir);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}
