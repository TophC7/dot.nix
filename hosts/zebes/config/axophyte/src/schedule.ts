import { limits } from "./limits";

/** Runs one turn for `key` answering `triggers` (message IDs); `commit` makes it unabortable. */
type TurnRunner = (key: string, triggers: Set<string>, signal: AbortSignal, commit: () => void) => Promise<void>;
/** Trigger message ID → author ID. */
type Triggers = Map<string, string>;
type Gate = { firstAt: number; lastMessageAt: number; lastTypingAt: number; triggers: Triggers; timer?: Timer };
type Run = { triggers: Triggers; controller: AbortController; committed: boolean };

const hasAuthor = (triggers: Triggers | undefined, userId: string) => !!triggers && triggers.values().some((id) => id === userId);

// Waits for a burst of messages to settle (quiet + nobody pending still typing,
// capped) so one answer covers it, then queues the turn on the global serial chain.
// A new message before the running turn has committed anything aborts it and
// folds its triggers into the next one.
export class Scheduler {
  private readonly gates = new Map<string, Gate>();
  private readonly ready = new Map<string, Triggers>();
  private readonly queued = new Set<string>();
  private readonly runs = new Map<string, Run>();
  private chain: Promise<void> = Promise.resolve();

  constructor(private readonly turn: TurnRunner) {}

  message(key: string, authorId: string, messageId: string): void {
    const now = Date.now();
    let gate = this.gates.get(key);
    if (!gate) {
      gate = { firstAt: now, lastMessageAt: now, lastTypingAt: 0, triggers: new Map() };
      this.gates.set(key, gate);
    }
    const run = this.runs.get(key);
    if (run && !run.committed) {
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

  follows(key: string, authorId: string): boolean {
    return hasAuthor(this.gates.get(key)?.triggers, authorId) || hasAuthor(this.ready.get(key), authorId)
      || hasAuthor(this.runs.get(key)?.triggers, authorId);
  }

  command<T>(run: () => Promise<T>): Promise<T> {
    const result = this.chain.then(run);
    this.chain = result.then(
      () => {},
      () => console.error("turn queue job failed"),
    );
    return result;
  }

  private schedule(key: string, gate: Gate): void {
    clearTimeout(gate.timer);
    const due = Math.min(
      gate.firstAt + limits.burstMaxWaitMs,
      Math.max(gate.lastMessageAt + limits.burstQuietMs, gate.lastTypingAt + limits.burstTypingMs),
    );
    gate.timer = setTimeout(() => {
      this.gates.delete(key);
      const ready = this.ready.get(key) ?? new Map<string, string>();
      for (const [id, author] of gate.triggers) ready.set(id, author);
      this.ready.set(key, ready);
      if (!this.queued.has(key)) {
        this.queued.add(key);
        void this.command(() => this.start(key));
      }
    }, Math.max(0, due - Date.now()));
  }

  private async start(key: string): Promise<void> {
    this.queued.delete(key);
    // The gate reopened after this turn was queued; its own fire re-queues it.
    if (this.gates.has(key)) return;
    const triggers = this.ready.get(key);
    this.ready.delete(key);
    if (!triggers) return;
    const run: Run = { triggers, controller: new AbortController(), committed: false };
    this.runs.set(key, run);
    try {
      await this.turn(key, new Set(triggers.keys()), run.controller.signal, () => { run.committed = true; });
    } finally {
      if (this.runs.get(key) === run) this.runs.delete(key);
    }
  }
}
