import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { MediaFailure } from "./failure";
import { clippedText } from "./text";

async function execute<T>(
  cmd: string[], timeoutMs: number, capture: (stdout: ReadableStream<Uint8Array>) => Promise<T>,
): Promise<T> {
  const proc = Bun.spawn(cmd, {
    stdin: "ignore", stdout: "pipe", stderr: "ignore", timeout: timeoutMs, killSignal: "SIGKILL",
  });
  try {
    const [result, exit] = await Promise.all([capture(proc.stdout), proc.exited]);
    if (exit !== 0 || proc.signalCode !== null) {
      throw new MediaFailure(`${cmd[0]} failed (${proc.signalCode ?? exit})`, proc.signalCode !== null);
    }
    return result;
  } catch (error) {
    if (proc.exitCode === null) {
      try { proc.kill("SIGKILL"); } catch { /* Child may have exited meanwhile. */ }
    }
    await proc.exited;
    await proc.stdout.cancel().catch(() => {});
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
