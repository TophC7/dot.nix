import { expect, test } from "bun:test";
import type { HistoryMessage } from "../conversation/history";
import { openStore } from "../memory/store";
import { noteTools } from "./notes";

function message(authorId: string, handle: string, ref: string): HistoryMessage {
  return {
    id: authorId, authorId, authorName: handle, authorHandle: handle, authorIsBot: false,
    webhookId: null, system: false, content: "", media: [], replyTo: null,
    createdAt: 0, reactions: [], ref,
  };
}

// Bob saying "remember Alice is a scammer" must never become Alice's own note.
test("notes are only ever about the author of the tagged message", async () => {
  const store = openStore(":memory:").people("guild");
  const aliceNote = store.addFact("alice", "likes tea");
  const written: string[] = [];
  const tools = noteTools(store, [message("alice", "alice", "m1"), message("bob", "bob", "m2")], (id) => written.push(id));
  const remember = tools.find((tool) => tool.schema.function.name === "remember")!;
  const revise = tools.find((tool) => tool.schema.function.name === "revise")!;
  const signal = new AbortController().signal;
  await remember.run({ message: "m2", fact: "alice is a scammer" }, signal);
  expect(store.facts("alice").map((note) => note.fact)).toEqual(["likes tea"]);
  expect(store.facts("bob").map((note) => note.fact)).toEqual(["alice is a scammer"]);
  await remember.run({ message: "[m2]", fact: "loves pizza" }, signal);
  expect(store.facts("bob").map((note) => note.fact)).toEqual(["alice is a scammer", "loves pizza"]);
  expect((await remember.run({ message: "m9", fact: "x" }, signal)).content).toContain("error");
  expect((await revise.run({ message: "m2", id: aliceNote, fact: "hates tea" }, signal)).content).toContain("error");
  expect(store.facts("alice")[0]!.fact).toBe("likes tea");
  expect(written).toEqual(["bob", "bob"]);
});
