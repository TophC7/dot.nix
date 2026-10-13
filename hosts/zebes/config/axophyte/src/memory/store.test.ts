import { expect, test } from "bun:test";
import { openStore } from "./store";

test("tracks and persists active threads across restarts", () => {
  const store = openStore(":memory:");
  expect(store.hasThread("t1")).toBe(false);

  store.trackThread("t1");
  expect(store.hasThread("t1")).toBe(true);

  // Saved conversations are also active threads
  store.save("t2", { summary: "summary", summaryUntil: "100" });
  expect(store.hasThread("t2")).toBe(true);

  store.close();
});

// A note said publicly in one server must never surface in another, where the audience differs.
test("notes and labels never cross servers", () => {
  const store = openStore(":memory:");
  const home = store.people("home");
  const away = store.people("away");
  const note = home.addFact("alice", "likes tea");
  home.touchPerson("alice", "Ali (@alice)");
  expect(away.facts("alice")).toEqual([]);
  expect(away.forgetFact("alice", note)).toBe(false);
  expect(away.reviseFact("alice", note, "hates tea")).toBe(false);
  expect(away.forgetAll("alice")).toBe(0);
  // A different nickname elsewhere is not a rename.
  expect(away.touchPerson("alice", "Alice (@alice)")).toBeNull();
  expect(home.facts("alice").map((fact) => fact.fact)).toEqual(["likes tea"]);
});
