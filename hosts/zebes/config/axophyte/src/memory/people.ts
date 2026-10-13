import { label } from "../conversation/history";
import type { Speaker } from "../conversation/history";
import type { ChatMessage } from "../llm/protocol";
import type { People } from "./store";

const PERSON_MEMORY_CHARS = 2000;
const PRUNE_TARGET_CHARS = 1200;
const PRUNE_MAX_TOKENS = 2048;
export const MAX_FACT_CHARS = 300;

const PRUNER = `You keep notes about one Discord user, from what they shared about themselves, so later conversations can pick up where they left off. Rewrite the notes so they total at most ${PRUNE_TARGET_CHARS} characters: merge duplicates; when two notes conflict keep the newer one (higher number); fold small related details into broader notes; keep what helps future conversation (interests, what they're working on, how they like to talk, names, pronouns) over trivia. Output one note per line, no numbering, nothing else.`;

// Memory is per person per server and loads anywhere in that server; tools only write it in public channels.
export function peopleSection(store: People, people: Map<string, Speaker>): string {
  const lines: string[] = [];
  for (const [id, person] of people) {
    const current = label(person.name, person.handle);
    const previous = store.touchPerson(id, current);
    const shown: string[] = [];
    let used = 0;
    for (const { id: factId, fact } of store.facts(id).reverse()) {
      if (used + fact.length > PERSON_MEMORY_CHARS) break;
      used += fact.length;
      shown.push(`  [#${factId}] ${fact}`);
    }
    if (!shown.length && !previous) continue;
    lines.push(`- ${current}${previous ? `, previously ${previous}` : ""}:`, ...shown.reverse());
  }
  return lines.length
    ? `## What you know about people here (from what they shared; may be outdated or wrong)\n${lines.join("\n")}`
    : "";
}

// Bad rewrites keep the old notes; the next touch retries.
export function parsePruned(text: string, oldTotal: number): string[] | null {
  const facts = text.split("\n")
    .map((line) => line.replace(/^\s*(?:[-*]\s+|\[#\d+\]\s*)+/, "").trim().slice(0, MAX_FACT_CHARS))
    .filter(Boolean);
  const total = facts.reduce((sum, fact) => sum + fact.length, 0);
  return facts.length && total <= PERSON_MEMORY_CHARS && total < oldTotal ? facts : null;
}

export async function prunePerson(
  store: People,
  userId: string,
  rewrite: (messages: ChatMessage[], maxTokens: number) => Promise<string>,
): Promise<void> {
  const facts = store.facts(userId);
  const total = facts.reduce((sum, { fact }) => sum + fact.length, 0);
  if (total <= PERSON_MEMORY_CHARS) return;
  const listing = facts.map(({ id, fact }) => `[#${id}] ${fact}`).join("\n");
  const pruned = parsePruned(await rewrite([
    { role: "system", content: PRUNER },
    { role: "user", content: listing },
  ], PRUNE_MAX_TOKENS), total);
  // /memory forget can run while the model rewrites; never resurrect forgotten notes.
  const unchanged = store.facts(userId).map(({ id, fact }) => `[#${id}] ${fact}`).join("\n") === listing;
  if (pruned && unchanged) store.replaceFacts(userId, pruned);
}
