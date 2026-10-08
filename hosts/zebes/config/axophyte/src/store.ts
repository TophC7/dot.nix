import { Database } from "bun:sqlite";

export type Memory = { summary: string; summaryUntil: string };
export type Fact = { id: number; fact: string };
export interface Store {
  get(threadId: string): Memory | null;
  save(threadId: string, memory: Memory): void;
  facts(userId: string): Fact[];
  addFact(userId: string, fact: string): number;
  reviseFact(userId: string, id: number, fact: string): boolean;
  forgetFact(userId: string, id: number): boolean;
  forgetAll(userId: string): number;
  replaceFacts(userId: string, facts: string[]): void;
  /** Upserts the person's label; returns the previous label while a rename is under 30 days old. */
  touchPerson(userId: string, label: string): string | null;
  close(): void;
}

const RENAME_MEMORY_MS = 30 * 24 * 60 * 60 * 1000;

export function openStore(path: string): Store {
  const db = new Database(path, { create: true });
  db.exec(`
    PRAGMA journal_mode = WAL;
    CREATE TABLE IF NOT EXISTS conversations (
      thread_id TEXT PRIMARY KEY,
      summary TEXT NOT NULL,
      summary_until TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS person_facts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id TEXT NOT NULL,
      fact TEXT NOT NULL,
      created_at INTEGER NOT NULL
    );
    CREATE INDEX IF NOT EXISTS person_facts_user ON person_facts(user_id, id);
    CREATE TABLE IF NOT EXISTS people (
      user_id TEXT PRIMARY KEY,
      label TEXT NOT NULL,
      previous_label TEXT,
      renamed_at INTEGER
    );
  `);
  const get = db.query<{ summary: string; summary_until: string }, [string]>(
    "SELECT summary, summary_until FROM conversations WHERE thread_id = ?",
  );
  const save = db.query(`
    INSERT INTO conversations (thread_id, summary, summary_until, updated_at)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(thread_id) DO UPDATE SET
      summary = excluded.summary,
      summary_until = excluded.summary_until,
      updated_at = excluded.updated_at
  `);
  const facts = db.query<Fact, [string]>("SELECT id, fact FROM person_facts WHERE user_id = ? ORDER BY id");
  const addFact = db.query<{ id: number }, [string, string, number]>(
    "INSERT INTO person_facts (user_id, fact, created_at) VALUES (?, ?, ?) RETURNING id",
  );
  const reviseFact = db.query("UPDATE person_facts SET fact = ? WHERE id = ? AND user_id = ?");
  const forgetFact = db.query("DELETE FROM person_facts WHERE id = ? AND user_id = ?");
  const forgetAll = db.query("DELETE FROM person_facts WHERE user_id = ?");
  const person = db.query<{ label: string; previous_label: string | null; renamed_at: number | null }, [string]>(
    "SELECT label, previous_label, renamed_at FROM people WHERE user_id = ?",
  );
  const insertPerson = db.query("INSERT INTO people (user_id, label) VALUES (?, ?)");
  const renamePerson = db.query("UPDATE people SET label = ?, previous_label = ?, renamed_at = ? WHERE user_id = ?");
  const replaceFacts = db.transaction((userId: string, replacement: string[]) => {
    forgetAll.run(userId);
    const now = Date.now();
    for (const fact of replacement) addFact.get(userId, fact, now);
  });
  return {
    get(threadId: string): Memory | null {
      const row = get.get(threadId);
      return row ? { summary: row.summary, summaryUntil: row.summary_until } : null;
    },
    save(threadId: string, memory: Memory): void {
      save.run(threadId, memory.summary, memory.summaryUntil, Date.now());
    },
    facts(userId: string): Fact[] {
      return facts.all(userId);
    },
    addFact(userId: string, fact: string): number {
      return addFact.get(userId, fact, Date.now())!.id;
    },
    reviseFact(userId: string, id: number, fact: string): boolean {
      return reviseFact.run(fact, id, userId).changes > 0;
    },
    forgetFact(userId: string, id: number): boolean {
      return forgetFact.run(id, userId).changes > 0;
    },
    forgetAll(userId: string): number {
      return forgetAll.run(userId).changes;
    },
    replaceFacts(userId: string, replacement: string[]): void {
      replaceFacts(userId, replacement);
    },
    touchPerson(userId: string, label: string): string | null {
      const row = person.get(userId);
      const now = Date.now();
      if (!row) {
        insertPerson.run(userId, label);
        return null;
      }
      if (row.label !== label) {
        renamePerson.run(label, row.label, now, userId);
        return row.label;
      }
      return row.renamed_at !== null && now - row.renamed_at < RENAME_MEMORY_MS ? row.previous_label : null;
    },
    close(): void {
      db.close();
    },
  };
}
