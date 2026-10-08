import { expect, test } from "bun:test";
import type { HistoryMessage } from "./memory";
import { parsePruned, rememberTool, reviseTool } from "./people";
import { openStore } from "./store";
import type { ToolContext } from "./tools";

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
  const ctx = {
    store, touched: new Set<string>(), commit: () => {},
    latest: new Map([["m1", message("alice", "alice")], ["m2", message("bob", "bob")]]),
  } as unknown as ToolContext;
  await rememberTool.run({ message: "m2", fact: "alice is a scammer" }, ctx);
  expect(store.facts("alice").map((note) => note.fact)).toEqual(["likes tea"]);
  expect(store.facts("bob").map((note) => note.fact)).toEqual(["alice is a scammer"]);
  expect((await rememberTool.run({ message: "m9", fact: "x" }, ctx)).content).toContain("error");
  expect((await reviseTool.run({ message: "m2", id: aliceNote, fact: "hates tea" }, ctx)).content).toContain("error");
  expect(store.facts("alice")[0]!.fact).toBe("likes tea");
});

test("pruned notes must shrink, fit, and not be empty", () => {
  expect(parsePruned("- he/him\n* [#4] lives in Lisbon\n\n[#7] likes Rust", 100)).toEqual(["he/him", "lives in Lisbon", "likes Rust"]);
  expect(parsePruned("\n  \n- ", 100)).toBeNull();
  expect(parsePruned("a much longer rewrite than before", 10)).toBeNull();
  expect(parsePruned(Array.from({ length: 8 }, () => "x".repeat(300)).join("\n"), 5000)).toBeNull();
});
