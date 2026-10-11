import { expect, test } from "bun:test";
import { openStore } from "./store";

test("tracks and persists active threads across restarts", () => {
  const store = openStore(":memory:");
  expect(store.activeThreads().size).toBe(0);
  expect(store.hasThread("t1")).toBe(false);

  store.trackThread("t1");
  expect(store.hasThread("t1")).toBe(true);
  expect(store.activeThreads().has("t1")).toBe(true);

  // Saved conversations are also active threads
  store.save("t2", { summary: "summary", summaryUntil: "100" });
  expect(store.hasThread("t2")).toBe(true);
  expect(store.activeThreads().has("t2")).toBe(true);
  expect(store.activeThreads().size).toBe(2);

  store.close();
});
