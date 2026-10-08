import { limits } from "./limits";

/** Trigger message ID → author ID. */
export type Triggers = Map<string, string>;
type Timing = { quietMs: number; typingMs: number; maxWaitMs: number };
type Gate = { firstAt: number; lastMessageAt: number; lastTypingAt: number; triggers: Triggers; timer?: Timer };
type Running = { triggers: Triggers; controller: AbortController; started: () => boolean };

const hasAuthor = (triggers: Triggers | undefined, userId: string) => !!triggers && [...triggers.values()].includes(userId);

// Waits for a burst of messages to settle (quiet + nobody pending still typing,
// capped) so one answer covers it. A new message before the running turn has
// committed anything aborts it and folds its triggers into the next one.
export class Burst {
  private readonly gates = new Map<string, Gate>();
  private readonly ready = new Map<string, Triggers>();
  private readonly runs = new Map<string, Running>();

  constructor(
    private readonly fire: (key: string) => void,
    private readonly timing: Timing = { quietMs: limits.burstQuietMs, typingMs: limits.burstTypingMs, maxWaitMs: limits.burstMaxWaitMs },
  ) {}

  message(key: string, authorId: string, messageId: string): void {
    const now = Date.now();
    let gate = this.gates.get(key);
    if (!gate) {
      gate = { firstAt: now, lastMessageAt: now, lastTypingAt: 0, triggers: new Map() };
      this.gates.set(key, gate);
    }
    const run = this.runs.get(key);
    if (run && !run.started()) {
      run.controller.abort();
      for (const [id, author] of run.triggers) gate.triggers.set(id, author);
    }
    gate.triggers.set(messageId, authorId);
    gate.lastMessageAt = now;
    this.schedule(key, gate);
  }

  typing(key: string, userId: string): void {
    const gate = this.gates.get(key);
    if (!gate || !hasAuthor(gate.triggers, userId)) return;
    gate.lastTypingAt = Date.now();
    this.schedule(key, gate);
  }

  pending(key: string): boolean {
    return this.gates.has(key);
  }

  follows(key: string, authorId: string): boolean {
    return hasAuthor(this.gates.get(key)?.triggers, authorId) || hasAuthor(this.ready.get(key), authorId)
      || hasAuthor(this.runs.get(key)?.triggers, authorId);
  }

  take(key: string): Triggers {
    const triggers = this.ready.get(key) ?? new Map<string, string>();
    this.ready.delete(key);
    return triggers;
  }

  running(key: string, triggers: Triggers, controller: AbortController, started: () => boolean): () => void {
    const entry = { triggers, controller, started };
    this.runs.set(key, entry);
    return () => { if (this.runs.get(key) === entry) this.runs.delete(key); };
  }

  private schedule(key: string, gate: Gate): void {
    clearTimeout(gate.timer);
    const { quietMs, typingMs, maxWaitMs } = this.timing;
    const due = Math.min(gate.firstAt + maxWaitMs, Math.max(gate.lastMessageAt + quietMs, gate.lastTypingAt + typingMs));
    gate.timer = setTimeout(() => {
      this.gates.delete(key);
      const ready = this.ready.get(key) ?? new Map<string, string>();
      for (const [id, author] of gate.triggers) ready.set(id, author);
      this.ready.set(key, ready);
      this.fire(key);
    }, Math.max(0, due - Date.now()));
  }
}
