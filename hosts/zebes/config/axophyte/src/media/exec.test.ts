import { expect, test } from "bun:test";
import { existsSync } from "node:fs";
import { run, runText, withTemp } from "./exec";

test("normal child failures are permanent, even with a signal-like exit code", async () => {
  for (const code of [7, 137]) {
    await expect(run([process.execPath, "-e", `process.exit(${code})`], 5000)).rejects.toMatchObject({
      name: "MediaFailure", retryable: false, detail: " - unsupported",
    });
  }
});

test("actual child signal termination is retryable", async () => {
  await expect(run([process.execPath, "-e", 'process.kill(process.pid, "SIGTERM")'], 5000)).rejects.toMatchObject({
    name: "MediaFailure", retryable: true,
  });
});

test("timeout kills and reaps child before temporary files are removed", async () => {
  let directory = "";
  await withTemp(async (input, dir) => {
    directory = dir;
    expect(existsSync(input)).toBe(false);
    // Native subprocess deadlines run outside fake timers; exercise real kill/reap behavior.
    await expect(runText([
      process.execPath, "-e",
      `await Bun.write(${JSON.stringify(input)}, String(process.pid)); for (;;) {}`,
    ], 1000, 8)).rejects.toMatchObject({ name: "MediaFailure", retryable: true });
    const pid = Number(await Bun.file(input).text());
    expect(pid).toBeGreaterThan(0);
    expect(() => process.kill(pid, 0)).toThrow();
    expect(existsSync(dir)).toBe(true);
  });
  expect(existsSync(directory)).toBe(false);
});

test("bounded text capture drains child output and still honors final exit failure", async () => {
  const script = 'for (let i = 0; i < 32; i++) await Bun.write(Bun.stdout, "a😀".repeat(8192));';
  expect(await runText([process.execPath, "-e", script], 5000, 2)).toBe("a\n[truncated]");
  await expect(runText([process.execPath, "-e", `${script} process.exit(7);`], 5000, 2)).rejects.toMatchObject({
    name: "MediaFailure", retryable: false,
  });
  expect(new TextDecoder().decode(await run([process.execPath, "-e", 'await Bun.write(Bun.stdout, "done");'], 5000))).toBe("done");
});

test("temporary directory cleanup also runs after callback failure", async () => {
  let directory = "";
  const failure = new Error("callback failed");
  await expect(withTemp(async (input, dir) => {
    directory = dir;
    await Bun.write(input, "temporary data");
    throw failure;
  })).rejects.toBe(failure);
  expect(existsSync(directory)).toBe(false);
});
