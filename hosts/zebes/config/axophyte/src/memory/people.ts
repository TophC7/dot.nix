import { limits } from "../limits";
import { label } from "../conversation/history";
import type { HistoryMessage, Speaker } from "../conversation/history";
import type { ChatMessage } from "../llm/protocol";
import type { Store } from "./store";
import { defineTool, stringArg, toolError } from "../tools/tool";
import type { Tool } from "../tools/tool";

const PRUNER = `You maintain long-term notes about one Discord user, written from what they said about themselves. Rewrite the notes so they total at most ${limits.pruneTargetChars} characters: merge duplicates; when two notes conflict keep the newer one (higher number); fold small related details into broader notes; drop passing chatter before lasting facts (names, pronouns, preferences, ongoing projects, skills). Output one note per line, no numbering, nothing else.`;

// Memory is per person and loads in every channel; tools only write it in public channels.
export function peopleSection(store: Store, people: Map<string, Speaker>): string {
  const lines: string[] = [];
  for (const [id, person] of people) {
    const current = label(person.name, person.handle);
    const previous = store.touchPerson(id, current);
    const shown: string[] = [];
    let used = 0;
    for (const { id: factId, fact } of store.facts(id).reverse()) {
      if (used + fact.length > limits.personMemoryChars) break;
      used += fact.length;
      shown.push(`  [#${factId}] ${fact}`);
    }
    if (!shown.length && !previous) continue;
    lines.push(`- ${current}${previous ? `, previously ${previous}` : ""}:`, ...shown.reverse());
  }
  return lines.length
    ? `People here (what they told you about themselves; may be outdated or untrue):\n${lines.join("\n")}`
    : "";
}

const messageParam = { type: "string", description: "Tag of the latest message the fact comes from, e.g. m1" };

/** Writes refs in place for speakerLine; create these tools before rendering the latest messages. */
export function noteTools(store: Store, latest: HistoryMessage[], wrote: (userId: string) => void): Tool[] {
  const messages = new Map<string, HistoryMessage>();
  for (const message of latest) {
    message.ref = `m${messages.size + 1}`;
    messages.set(message.ref, message);
  }
  // A note is always about the author of the tagged trigger message it came from,
  // so one person can never write notes about another.
  function sourceMessage(args: Record<string, unknown>): HistoryMessage | string {
    const message = messages.get(stringArg(args, "message", 10) ?? "");
    return message ?? `message must be one of: ${[...messages.keys()].join(", ")}`;
  }

  const remember = defineTool({
    name: "remember",
    description: "Save one lasting fact the author of a tagged latest message states about themselves.",
    properties: {
      message: messageParam,
      fact: { type: "string", description: "Short fact in third person, e.g. 'uses a Corne keyboard'" },
    },
    required: ["message", "fact"],
    async run(args) {
      const source = sourceMessage(args);
      if (typeof source === "string") return toolError(source);
      const fact = stringArg(args, "fact", limits.maxFactChars);
      if (!fact) return toolError("invalid arguments");
      const id = store.addFact(source.authorId, fact);
      wrote(source.authorId);
      return { content: JSON.stringify({ saved: id }), footer: `-# 🧠 Noted about @${source.authorHandle}` };
    },
  });

  const revise = defineTool({
    name: "revise",
    description: "Correct one of the notes about the author of a tagged latest message.",
    properties: {
      message: messageParam,
      id: { type: "integer", description: "Note number, e.g. 12 for [#12]" },
      fact: { type: "string", description: "Corrected fact" },
    },
    required: ["message", "id", "fact"],
    async run(args) {
      const source = sourceMessage(args);
      if (typeof source === "string") return toolError(source);
      const id = Number(args.id);
      const fact = stringArg(args, "fact", limits.maxFactChars);
      if (!Number.isSafeInteger(id) || !fact) return toolError("invalid arguments");
      if (!store.reviseFact(source.authorId, id, fact)) return toolError(`note ${id} is not about @${source.authorHandle}`);
      wrote(source.authorId);
      return { content: JSON.stringify({ revised: id }), footer: `-# 🧠 Updated a note about @${source.authorHandle}` };
    },
  });
  return [remember, revise];
}

// Bad rewrites keep the old notes; the next touch retries.
export function parsePruned(text: string, oldTotal: number): string[] | null {
  const facts = text.split("\n")
    .map((line) => line.replace(/^\s*(?:[-*]\s+|\[#\d+\]\s*)+/, "").trim().slice(0, limits.maxFactChars))
    .filter(Boolean);
  const total = facts.reduce((sum, fact) => sum + fact.length, 0);
  return facts.length && total <= limits.personMemoryChars && total < oldTotal ? facts : null;
}

export async function prunePerson(store: Store, userId: string, rewrite: (messages: ChatMessage[]) => Promise<string>): Promise<void> {
  const facts = store.facts(userId);
  const total = facts.reduce((sum, { fact }) => sum + fact.length, 0);
  if (total <= limits.personMemoryChars) return;
  const listing = facts.map(({ id, fact }) => `[#${id}] ${fact}`).join("\n");
  const pruned = parsePruned(await rewrite([
    { role: "system", content: PRUNER },
    { role: "user", content: listing },
  ]), total);
  // /memory forget can run while the model rewrites; never resurrect forgotten notes.
  const unchanged = store.facts(userId).map(({ id, fact }) => `[#${id}] ${fact}`).join("\n") === listing;
  if (pruned && unchanged) store.replaceFacts(userId, pruned);
}
