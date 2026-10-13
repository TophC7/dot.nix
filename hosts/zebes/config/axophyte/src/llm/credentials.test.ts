import { expect, test } from "bun:test";
import { chmod, mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { OAuthFileStore } from "./credentials";

const credential = { type: "oauth" as const, access: "access", refresh: "refresh", expires: 1_000_000, accountId: "account" };

test("OAuth refresh modifications serialize across store instances and persist privately", async () => {
  const dir = await mkdtemp(join(tmpdir(), "axo-oauth-"));
  const path = join(dir, "auth.json");
  try {
    await writeFile(path, JSON.stringify({ "openai-codex": credential, unrelated: { preserved: true } }), { mode: 0o600 });
    const stores = [new OAuthFileStore(path), new OAuthFileStore(path)];
    await Promise.all(stores.map((store, i) => store.modify("openai-codex", async (current) => {
      expect(current?.type).toBe("oauth");
      if (current?.type !== "oauth") throw new Error("missing OAuth");
      return { ...current, access: `${current.access}-${i}`, expires: current.expires + 1 };
    })));
    const saved = JSON.parse(await readFile(path, "utf8"));
    expect(saved["openai-codex"].expires).toBe(credential.expires + 2);
    expect(saved["openai-codex"].access).toMatch(/^access-(0-1|1-0)$/);
    expect(saved.unrelated).toEqual({ preserved: true });
    expect((await stat(path)).mode & 0o777).toBe(0o600);
    const before = await readFile(path, "utf8");
    await expect(stores[0]!.modify("openai-codex", async () => { throw new Error("refresh failed"); })).rejects.toThrow("refresh failed");
    expect(await readFile(path, "utf8")).toBe(before);
  } finally { await rm(dir, { recursive: true, force: true }); }
});

test("OAuth storage rejects exposed or malformed credentials rather than silently using them", async () => {
  const dir = await mkdtemp(join(tmpdir(), "axo-oauth-"));
  const path = join(dir, "auth.json");
  const store = new OAuthFileStore(path);
  try {
    expect(await store.read("openai-codex")).toBeUndefined();
    await writeFile(path, JSON.stringify({ "openai-codex": credential }), { mode: 0o644 });
    await chmod(path, 0o644);
    await expect(store.read("openai-codex")).rejects.toThrow("0600");
    await chmod(path, 0o600);
    await writeFile(path, JSON.stringify({ "openai-codex": { ...credential, refresh: "" } }));
    await expect(store.read("openai-codex")).rejects.toThrow("Invalid Codex");
    expect(await store.read("anthropic")).toBeUndefined();
  } finally { await rm(dir, { recursive: true, force: true }); }
});
