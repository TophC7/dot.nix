import { constants } from "node:fs";
import { open, rename, unlink } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { lock } from "proper-lockfile";
import type { AuthOperationOptions, Credential, CredentialStore } from "@earendil-works/pi-ai";
import { throwIfAborted } from "../abort";
import { object } from "./protocol";

/** Only Codex subscription credentials are read; API providers use their explicit env keys. */
export class OAuthFileStore implements CredentialStore {
  private chain: Promise<unknown> = Promise.resolve();
  readonly path: string;

  constructor(path = process.env.AXOPHYTE_AUTH_FILE ?? "auth.json") {
    this.path = resolve(path);
  }

  private async load(): Promise<Record<string, unknown>> {
    let file;
    try { file = await open(this.path, constants.O_RDONLY | constants.O_NOFOLLOW); }
    catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") return {};
      throw new Error("OAuth credential storage unavailable");
    }
    try {
      const stat = await file.stat();
      if (!stat.isFile() || (stat.mode & 0o077) !== 0 || stat.uid !== process.getuid?.()) {
        throw new Error("OAuth credential file must be owned by the service user with mode 0600");
      }
      const data: unknown = JSON.parse(await file.readFile("utf8"));
      if (!object(data)) throw new Error("Invalid OAuth credential file");
      return data;
    } finally { await file.close(); }
  }

  private credential(data: Record<string, unknown>): Credential | undefined {
    const value = data["openai-codex"];
    if (value === undefined) return undefined;
    if (!object(value) || value.type !== "oauth" || typeof value.access !== "string" || !value.access
      || typeof value.refresh !== "string" || !value.refresh || typeof value.expires !== "number"
      || !Number.isFinite(value.expires) || value.expires <= 0
      || typeof value.accountId !== "string" || !value.accountId) {
      throw new Error("Invalid Codex OAuth credential");
    }
    return value as Credential;
  }

  async read(providerId: string, options?: AuthOperationOptions): Promise<Credential | undefined> {
    throwIfAborted(options?.signal);
    return providerId === "openai-codex" ? this.credential(await this.load()) : undefined;
  }

  async list(options?: AuthOperationOptions) {
    return await this.read("openai-codex", options) ? [{ providerId: "openai-codex", type: "oauth" as const }] : [];
  }

  private enqueue<T>(work: () => Promise<T>): Promise<T> {
    const result = this.chain.then(work, work);
    this.chain = result.catch(() => {});
    return result;
  }

  private async update(
    fn: (current: Credential | undefined) => Promise<Credential | undefined>,
    remove: boolean,
    options?: AuthOperationOptions,
  ): Promise<Credential | undefined> {
    return this.enqueue(async () => {
      throwIfAborted(options?.signal);
      // ponytail: one file lock; per-provider locks if more persisted providers are added.
      let compromised = false;
      const release = await lock(this.path, {
        realpath: false, stale: 30_000, retries: { retries: 60, minTimeout: 100, maxTimeout: 500 },
        onCompromised: () => { compromised = true; },
      });
      let temp: string | undefined;
      try {
        throwIfAborted(options?.signal);
        const data = await this.load();
        const current = this.credential(data);
        const next = remove ? undefined : await fn(current);
        if (!remove && next === undefined) return current;
        if (remove) delete data["openai-codex"];
        else data["openai-codex"] = next;
        this.credential(data);
        temp = `${this.path}.${crypto.randomUUID()}.tmp`;
        const file = await open(temp, "wx", 0o600);
        try { await file.writeFile(JSON.stringify(data)); await file.sync(); }
        finally { await file.close(); }
        if (compromised) throw new Error("OAuth credential lock lost");
        await rename(temp, this.path);
        temp = undefined;
        const directory = await open(dirname(this.path), "r");
        try { await directory.sync(); } finally { await directory.close(); }
        return next;
      } finally {
        if (temp) await unlink(temp).catch(() => {});
        await release();
      }
    });
  }

  async modify(providerId: string, fn: (current: Credential | undefined) => Promise<Credential | undefined>, options?: AuthOperationOptions): Promise<Credential | undefined> {
    if (providerId !== "openai-codex") throw new Error("Only Codex OAuth credentials may be stored");
    return this.update(fn, false, options);
  }

  async delete(providerId: string, options?: AuthOperationOptions): Promise<void> {
    if (providerId === "openai-codex") await this.update(async () => undefined, true, options);
  }
}
