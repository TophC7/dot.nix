import { afterEach, beforeEach, expect, jest, test } from "bun:test";
import { Burst } from "./burst";

const timing = { quietMs: 20, typingMs: 60, maxWaitMs: 200 };

beforeEach(() => jest.useFakeTimers());
afterEach(() => jest.useRealTimers());

// Without the cap, someone who keeps typing would starve the answer forever.
test("continuous typing still fires at the hard cap", () => {
  let fired = 0;
  const burst = new Burst(() => fired++, timing);
  burst.message("k", "a", "1");
  for (let elapsed = 0; elapsed < timing.maxWaitMs; elapsed += 15) {
    burst.typing("k", "a");
    jest.advanceTimersByTime(15);
  }
  expect(fired).toBe(1);
});

// Aborting after output would delete or truncate an answer people are reading;
// the aborted turn's messages must still be answered.
test("a new message aborts a turn only before it commits, and keeps its triggers", () => {
  const burst = new Burst(() => {}, timing);
  const quiet = new AbortController();
  burst.running("k", new Map([["1", "a"]]), quiet, () => false);
  burst.message("k", "b", "2");
  expect(quiet.signal.aborted).toBe(true);
  jest.advanceTimersByTime(timing.quietMs);
  expect([...burst.take("k")]).toEqual([["1", "a"], ["2", "b"]]);

  const streaming = new AbortController();
  burst.running("j", new Map([["1", "a"]]), streaming, () => true);
  burst.message("j", "b", "2");
  expect(streaming.signal.aborted).toBe(false);
});
