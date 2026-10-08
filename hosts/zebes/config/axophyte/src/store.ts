import { Database } from "bun:sqlite";

export type Memory = { summary: string; summaryUntil: string };

export function openStore(path: string) {
  const db = new Database(path, { create: true });
  db.exec(`
    PRAGMA journal_mode = WAL;
    CREATE TABLE IF NOT EXISTS conversations (
      thread_id TEXT PRIMARY KEY,
      summary TEXT NOT NULL,
      summary_until TEXT NOT NULL,
      updated_at INTEGER NOT NULL
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
  return {
    get(threadId: string): Memory | null {
      const row = get.get(threadId);
      return row ? { summary: row.summary, summaryUntil: row.summary_until } : null;
    },
    save(threadId: string, memory: Memory): void {
      save.run(threadId, memory.summary, memory.summaryUntil, Date.now());
    },
    close(): void {
      db.close();
    },
  };
}
