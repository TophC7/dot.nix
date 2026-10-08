import { expect, test } from "bun:test";
import type { HistoryMessage } from "../conversation/history";
import { noteTools, parsePruned } from "./people";
import { openStore } from "./store";

function message(authorId: string, handle: string): HistoryMessage {
  return {
    id: authorId, authorId, authorName: handle, authorHandle: handle, authorIsBot: false,
    webhookId: null, system: false, content: "", attachments: [], replyTo: null,
  };
}

// Bob saying "remember Alice is a scammer" must never become Alice's own note.
test("notes are only ever about the author of the tagged message", async () => {
  const store = openStore(":memory:");
  const aliceNote = store.addFact("alice", "likes tea");
  const written: string[] = [];
  const tools = noteTools(store, [message("alice", "alice"), message("bob", "bob")], (id) => written.push(id));
  const remember = tools.find((tool) => tool.schema.function.name === "remember")!;
  const revise = tools.find((tool) => tool.schema.function.name === "revise")!;
  const signal = new AbortController().signal;
  await remember.run({ message: "m2", fact: "alice is a scammer" }, signal);
  expect(store.facts("alice").map((note) => note.fact)).toEqual(["likes tea"]);
  expect(store.facts("bob").map((note) => note.fact)).toEqual(["alice is a scammer"]);
  expect((await remember.run({ message: "m9", fact: "x" }, signal)).content).toContain("error");
  expect((await revise.run({ message: "m2", id: aliceNote, fact: "hates tea" }, signal)).content).toContain("error");
  expect(store.facts("alice")[0]!.fact).toBe("likes tea");
  expect(written).toEqual(["bob"]);
});

test("pruned notes must shrink, fit, and not be empty", () => {
  expect(parsePruned("- he/him\n* [#4] lives in Lisbon\n\n[#7] likes Rust", 100)).toEqual(["he/him", "lives in Lisbon", "likes Rust"]);
  expect(parsePruned("\n  \n- ", 100)).toBeNull();
  expect(parsePruned("a much longer rewrite than before", 10)).toBeNull();
  expect(parsePruned(Array.from({ length: 8 }, () => "x".repeat(300)).join("\n"), 5000)).toBeNull();
});
