import { afterEach, beforeEach, describe, expect, jest, test } from "bun:test";
import { limits } from "./limits";
import { Scheduler } from "./schedule";

const barrier = () => Promise.withResolvers<void>();

beforeEach(() => jest.useFakeTimers());
afterEach(() => jest.useRealTimers());

describe("scheduler", () => {
  // Without the cap, someone who keeps typing would starve the answer forever.
  test("continuous typing still starts one turn at the hard cap", async () => {
    let calls = 0;
    const scheduler = new Scheduler(async () => { calls++; });
    scheduler.message("k", "a", "1");
    for (let elapsed = 0; elapsed < limits.burstMaxWaitMs; elapsed += 1000) {
      scheduler.typing("k", "a");
      jest.advanceTimersByTime(1000);
      await scheduler.command(async () => {});
      expect(calls).toBe(elapsed + 1000 < limits.burstMaxWaitMs ? 0 : 1);
    }
    await scheduler.command(async () => {});
    expect(calls).toBe(1);
  });

  // After commit, aborting would truncate output people are already reading.
  test("new messages abort only before commit and retain aborted triggers", async () => {
    for (const committed of [false, true]) {
      const started = barrier();
      const release = barrier();
      const calls: { triggers: string[]; signal: AbortSignal }[] = [];
      const scheduler = new Scheduler(async (_key, triggers, signal, commit) => {
        calls.push({ triggers: [...triggers], signal });
        if (calls.length === 1) {
          if (committed) commit();
          started.resolve();
          await release.promise;
        }
      });
      scheduler.message("k", "a", "1");
      jest.advanceTimersByTime(limits.burstQuietMs);
      await started.promise;
      expect(calls[0]!.signal.aborted).toBe(false);
      expect(scheduler.follows("k", "a")).toBe(true);
      scheduler.message("k", "b", "2");
      expect(calls[0]!.signal.aborted).toBe(!committed);
      jest.advanceTimersByTime(limits.burstQuietMs);
      release.resolve();
      await scheduler.command(async () => {});
      expect(calls.map((call) => call.triggers)).toEqual(committed ? [["1"], ["2"]] : [["1"], ["1", "2"]]);
      expect(calls[1]!.signal.aborted).toBe(false);
      expect(scheduler.follows("k", "a")).toBe(false);
      expect(scheduler.follows("k", "b")).toBe(false);
    }
  });

  test("turns and commands serialize by settle time and survive a failed runner", async () => {
    const started = barrier();
    const release = barrier();
    const events: string[] = [];
    let active = 0;
    const scheduler = new Scheduler(async (key) => {
      active++;
      expect(active).toBe(1);
      events.push(`${key}:start`);
      try {
        if (key === "a") {
          started.resolve();
          await release.promise;
        }
        await Promise.resolve();
        if (key === "b") throw new Error("job failed");
      } finally {
        events.push(`${key}:end`);
        active--;
      }
    });
    scheduler.message("a", "alice", "1");
    jest.advanceTimersByTime(limits.burstQuietMs);
    await started.promise;
    scheduler.message("b", "bob", "2");
    jest.advanceTimersByTime(limits.burstQuietMs);
    const command = scheduler.command(async () => {
      active++;
      expect(active).toBe(1);
      events.push("command:start");
      await Promise.resolve();
      events.push("command:end");
      active--;
    });
    release.resolve();
    await command;
    await scheduler.command(async () => {});
    expect(events).toEqual(["a:start", "a:end", "b:start", "b:end", "command:start", "command:end"]);
    expect(active).toBe(0);
  });

  test("commands preserve results and rejection without poisoning the chain", async () => {
    const scheduler = new Scheduler(async () => {});
    const failure = new Error("compaction failed");
    const failed = scheduler.command(async () => { throw failure; });
    const later = scheduler.command(async () => 7);
    await expect(failed).rejects.toBe(failure);
    expect(await later).toBe(7);
  });

  test("queued messages coalesce even when their gate reopens before start", async () => {
    const started = barrier();
    const release = barrier();
    const calls: string[][] = [];
    const scheduler = new Scheduler(async (_key, triggers) => { calls.push([...triggers]); });
    const command = scheduler.command(async () => {
      started.resolve();
      await release.promise;
    });
    await started.promise;
    scheduler.message("k", "a", "1");
    jest.advanceTimersByTime(limits.burstQuietMs);
    expect(scheduler.follows("k", "a")).toBe(true);
    scheduler.message("k", "b", "2");
    jest.advanceTimersByTime(limits.burstQuietMs);
    scheduler.message("k", "c", "3");
    release.resolve();
    await command;
    await scheduler.command(async () => {});
    expect(calls).toEqual([]);
    jest.advanceTimersByTime(limits.burstQuietMs);
    await scheduler.command(async () => {});
    expect(calls).toEqual([["1", "2", "3"]]);
  });
});
