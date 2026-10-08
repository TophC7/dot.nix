import { describe, expect, test } from "bun:test";
import { TurnQueue } from "./queue";

const barrier = () => Promise.withResolvers<void>();

describe("turn queue", () => {
  test("coalesces messages while queued", async () => {
    const queue = new TurnQueue();
    let calls = 0;
    const run = async () => { calls++; };
    queue.message("post", run);
    queue.message("post", run);
    queue.message("post", run);
    await queue.command(async () => {});
    expect(calls).toBe(1);
  });

  test("messages during a run cause exactly one rerun", async () => {
    const queue = new TurnQueue();
    const started = barrier();
    const release = barrier();
    const reran = barrier();
    let calls = 0;
    const run = async () => {
      calls++;
      if (calls === 1) {
        started.resolve();
        await release.promise;
      } else {
        reran.resolve();
      }
    };
    queue.message("post", run);
    await started.promise;
    queue.message("post", run);
    queue.message("post", run);
    queue.message("post", run);
    release.resolve();
    await reran.promise;
    await queue.command(async () => {});
    expect(calls).toBe(2);
    queue.message("post", run);
    await queue.command(async () => {});
    expect(calls).toBe(3);
  });

  test("posts and commands serialize in call order, reruns join the tail", async () => {
    const queue = new TurnQueue();
    const started = barrier();
    const release = barrier();
    const reran = barrier();
    const events: string[] = [];
    let active = 0;
    let calls = 0;
    const run = async (name: string, wait?: Promise<void>) => {
      active++;
      expect(active).toBe(1);
      events.push(`${name}:start`);
      if (wait) await wait;
      await Promise.resolve();
      events.push(`${name}:end`);
      active--;
    };
    const first = async () => {
      calls++;
      if (calls === 1) {
        started.resolve();
        await run("a", release.promise);
      } else {
        await run("a-again");
        reran.resolve();
      }
    };
    queue.message("a", first);
    await started.promise;
    queue.message("b", () => run("b"));
    const command = queue.command(() => run("command"));
    queue.message("a", first);
    release.resolve();
    await command;
    await reran.promise;
    await queue.command(async () => {});
    expect(events).toEqual([
      "a:start", "a:end", "b:start", "b:end",
      "command:start", "command:end", "a-again:start", "a-again:end",
    ]);
    expect(active).toBe(0);
  });

  test("failed messages do not stop later jobs", async () => {
    const queue = new TurnQueue();
    let ran = false;
    queue.message("bad", async () => { throw new Error("job failed"); });
    queue.message("next", async () => { ran = true; });
    await queue.command(async () => {});
    expect(ran).toBe(true);
  });

  test("commands preserve results and rejection without poisoning the chain", async () => {
    const queue = new TurnQueue();
    const failure = new Error("compaction failed");
    const failed = queue.command(async () => { throw failure; });
    const later = queue.command(async () => 7);
    await expect(failed).rejects.toBe(failure);
    expect(await later).toBe(7);
  });
});
