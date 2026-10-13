import { tagged } from "../conversation/history";
import type { HistoryMessage } from "../conversation/history";
import { MAX_FACT_CHARS } from "../memory/people";
import type { People } from "../memory/store";
import { defineTool, stringArg, toolError } from "./tool";
import type { Tool } from "./tool";

const messageParam = { type: "string", description: "Tag of the message it comes from, e.g. m1" };

export function noteTools(store: People, latest: HistoryMessage[], wrote: (userId: string) => void): Tool[] {
  // A note is always about the author of the tagged trigger message it came from,
  // so one person can never write notes about another.
  const remember = defineTool({
    name: "remember",
    budget: 4,
    description: "Note something the author of a tagged message shares about themselves, so later conversations can build on it. Note it as soon as it comes up, even in passing or alongside another request. Skip secrets and sensitive details.",
    properties: {
      message: messageParam,
      fact: { type: "string", description: "Short third-person note, e.g. 'really likes Minecraft'" },
    },
    required: ["message", "fact"],
    async run(args) {
      const source = tagged(latest, stringArg(args, "message", 10) ?? "");
      if (typeof source === "string") return toolError(source);
      const fact = stringArg(args, "fact", MAX_FACT_CHARS);
      if (!fact) return toolError("invalid arguments");
      const id = store.addFact(source.authorId, fact);
      wrote(source.authorId);
      return { content: JSON.stringify({ saved: id }), footer: `-# 🧠 Noted about @${source.authorHandle}` };
    },
  });

  const revise = defineTool({
    name: "revise",
    budget: 4,
    description: "Correct one of the notes about the author of a tagged message.",
    properties: {
      message: messageParam,
      id: { type: "integer", description: "Note number, e.g. 12 for [#12]" },
      fact: { type: "string", description: "Corrected note" },
    },
    required: ["message", "id", "fact"],
    async run(args) {
      const source = tagged(latest, stringArg(args, "message", 10) ?? "");
      if (typeof source === "string") return toolError(source);
      const id = Number(args.id);
      const fact = stringArg(args, "fact", MAX_FACT_CHARS);
      if (!Number.isSafeInteger(id) || !fact) return toolError("invalid arguments");
      if (!store.reviseFact(source.authorId, id, fact)) return toolError(`note ${id} is not about @${source.authorHandle}`);
      wrote(source.authorId);
      return { content: JSON.stringify({ revised: id }), footer: `-# 🧠 Updated a note about @${source.authorHandle}` };
    },
  });
  return [remember, revise];
}
