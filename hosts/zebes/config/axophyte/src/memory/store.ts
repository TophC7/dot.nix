import { Database } from "bun:sqlite";

export type Memory = { summary: string; summaryUntil: string };
type Fact = { id: number; fact: string };

/** One server's person memory: nicknames and notes never cross servers. */
export interface People {
  facts(userId: string): Fact[];
  addFact(userId: string, fact: string): number;
  reviseFact(userId: string, id: number, fact: string): boolean;
  forgetFact(userId: string, id: number): boolean;
  forgetAll(userId: string): number;
  replaceFacts(userId: string, facts: string[]): void;
  /** Upserts the person's label; returns the previous label while a rename is under 30 days old. */
  touchPerson(userId: string, label: string): string | null;
}

export type EmojiNote = { name: string; description: string; byAdmin: boolean };

/** One scope's emoji descriptions by emoji ID; an admin's description is final. */
interface EmojiNotes {
  all(): Map<string, EmojiNote>;
  set(emojiId: string, note: EmojiNote): void;
  delete(emojiId: string): void;
}

export interface Store {
  /** Thread IDs are unique across servers, so conversations need no server key. */
  get(threadId: string): Memory | null;
  save(threadId: string, memory: Memory): void;
  people(guildId: string): People;
  /** Scope: a guild ID, or APP_EMOJI_SCOPE for Axophyte's own emoji (stored in the guild_id column). */
  emojiNotes(scope: string): EmojiNotes;
  close(): void;
}

const RENAME_MEMORY_MS = 30 * 24 * 60 * 60 * 1000;
const SCHEMA = `
  CREATE TABLE IF NOT EXISTS conversations (
    thread_id TEXT PRIMARY KEY,
    summary TEXT NOT NULL,
    summary_until TEXT NOT NULL,
    updated_at INTEGER NOT NULL
  );
  CREATE TABLE IF NOT EXISTS person_facts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    guild_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    fact TEXT NOT NULL,
    created_at INTEGER NOT NULL
  );
  CREATE INDEX IF NOT EXISTS person_facts_owner ON person_facts(guild_id, user_id, id);
  CREATE TABLE IF NOT EXISTS people (
    guild_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    label TEXT NOT NULL,
    previous_label TEXT,
    renamed_at INTEGER,
    PRIMARY KEY (guild_id, user_id)
  );
  CREATE TABLE IF NOT EXISTS emoji (
    guild_id TEXT NOT NULL,
    emoji_id TEXT NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    by_admin INTEGER NOT NULL,
    PRIMARY KEY (guild_id, emoji_id)
  );
`;

export function openStore(path: string): Store {
  const db = new Database(path, { create: true });
  db.exec("PRAGMA journal_mode = WAL;");
  db.exec(SCHEMA);
  const get = db.query<Memory, [string]>(
    "SELECT summary, summary_until AS summaryUntil FROM conversations WHERE thread_id = ?",
  );
  const save = db.query(`
    INSERT INTO conversations (thread_id, summary, summary_until, updated_at)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(thread_id) DO UPDATE SET
      summary = excluded.summary,
      summary_until = excluded.summary_until,
      updated_at = excluded.updated_at
  `);
  const facts = db.query<Fact, [string, string]>("SELECT id, fact FROM person_facts WHERE guild_id = ? AND user_id = ? ORDER BY id");
  const addFact = db.query<{ id: number }, [string, string, string, number]>(
    "INSERT INTO person_facts (guild_id, user_id, fact, created_at) VALUES (?, ?, ?, ?) RETURNING id",
  );
  const reviseFact = db.query("UPDATE person_facts SET fact = ? WHERE id = ? AND guild_id = ? AND user_id = ?");
  const forgetFact = db.query("DELETE FROM person_facts WHERE id = ? AND guild_id = ? AND user_id = ?");
  const forgetAll = db.query("DELETE FROM person_facts WHERE guild_id = ? AND user_id = ?");
  const person = db.query<{ label: string; previous_label: string | null; renamed_at: number | null }, [string, string]>(
    "SELECT label, previous_label, renamed_at FROM people WHERE guild_id = ? AND user_id = ?",
  );
  const insertPerson = db.query("INSERT INTO people (guild_id, user_id, label) VALUES (?, ?, ?)");
  const renamePerson = db.query("UPDATE people SET label = ?, previous_label = ?, renamed_at = ? WHERE guild_id = ? AND user_id = ?");
  const replaceFacts = db.transaction((guildId: string, userId: string, replacement: string[]) => {
    forgetAll.run(guildId, userId);
    const now = Date.now();
    for (const fact of replacement) addFact.get(guildId, userId, fact, now);
  });
  const emojiNotes = db.query<{ id: string; name: string; description: string; byAdmin: number }, [string]>(
    "SELECT emoji_id AS id, name, description, by_admin AS byAdmin FROM emoji WHERE guild_id = ?",
  );
  // A model description finishing after an admin's must never replace it.
  const setEmojiNote = db.query(`
    INSERT INTO emoji (guild_id, emoji_id, name, description, by_admin) VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(guild_id, emoji_id) DO UPDATE SET
      name = excluded.name,
      description = excluded.description,
      by_admin = excluded.by_admin
    WHERE emoji.by_admin = 0 OR excluded.by_admin = 1
  `);
  const deleteEmojiNote = db.query("DELETE FROM emoji WHERE guild_id = ? AND emoji_id = ?");
  return {
    get(threadId: string): Memory | null {
      return get.get(threadId);
    },
    save(threadId: string, memory: Memory): void {
      save.run(threadId, memory.summary, memory.summaryUntil, Date.now());
    },
    people(guildId: string): People {
      return {
        facts(userId: string): Fact[] {
          return facts.all(guildId, userId);
        },
        addFact(userId: string, fact: string): number {
          return addFact.get(guildId, userId, fact, Date.now())!.id;
        },
        reviseFact(userId: string, id: number, fact: string): boolean {
          return reviseFact.run(fact, id, guildId, userId).changes > 0;
        },
        forgetFact(userId: string, id: number): boolean {
          return forgetFact.run(id, guildId, userId).changes > 0;
        },
        forgetAll(userId: string): number {
          return forgetAll.run(guildId, userId).changes;
        },
        replaceFacts(userId: string, replacement: string[]): void {
          replaceFacts(guildId, userId, replacement);
        },
        touchPerson(userId: string, label: string): string | null {
          const row = person.get(guildId, userId);
          const now = Date.now();
          if (!row) {
            insertPerson.run(guildId, userId, label);
            return null;
          }
          if (row.label !== label) {
            renamePerson.run(label, row.label, now, guildId, userId);
            return row.label;
          }
          return row.renamed_at !== null && now - row.renamed_at < RENAME_MEMORY_MS ? row.previous_label : null;
        },
      };
    },
    emojiNotes(scope: string): EmojiNotes {
      return {
        all(): Map<string, EmojiNote> {
          return new Map(emojiNotes.all(scope).map(({ id, byAdmin, ...note }) => [id, { ...note, byAdmin: byAdmin === 1 }]));
        },
        set(emojiId: string, note: EmojiNote): void {
          setEmojiNote.run(scope, emojiId, note.name, note.description, note.byAdmin ? 1 : 0);
        },
        delete(emojiId: string): void {
          deleteEmojiNote.run(scope, emojiId);
        },
      };
    },
    close(): void {
      db.close();
    },
  };
}
