import { expect, test } from "bun:test";

const env = {
  ...process.env,
  AXOPHYTE_DISCORD_TOKEN: "codex-test", AXOPHYTE_TAVILY_KEY: "codex-test", AXOPHYTE_SERVERS: '{"codex-test":null}',
  AXOPHYTE_LLAMA_URL: "http://127.0.0.1:1", AXOPHYTE_MODEL: "codex-test-local",
  AXOPHYTE_WHISPER_MODEL: "/unused", AXOPHYTE_SVG_FONTS: "/unused",
  ANTHROPIC_API_KEY: "test-key-for-auth-presence-only",
};
const clientPath = JSON.stringify(new URL("./client.ts", import.meta.url).pathname);
const commandPath = JSON.stringify(new URL("../commands.ts", import.meta.url).pathname);

// Child processes isolate validated startup config, the private credential store, and the HTTP boundary.
// OAuth, atomic persistence, model state, permissions and command lifecycle remain real.
async function isolated(source: string) {
  const child = Bun.spawn([process.execPath, "--eval", source], { cwd: new URL("../../", import.meta.url).pathname, env, stdout: "pipe", stderr: "pipe" });
  const [stdout, stderr, exit] = await Promise.all([new Response(child.stdout).text(), new Response(child.stderr).text(), child.exited]);
  expect({ stdout, stderr, exit }).toEqual({ stdout: "", stderr: "", exit: 0 });
}

const setup = `
import assert from "node:assert/strict";
import { mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
const dir = await mkdtemp(join(tmpdir(), "axo-codex-login-"));
const path = join(dir, "auth.json");
process.env.AXOPHYTE_AUTH_FILE = path;
const original = JSON.stringify({ "openai-codex": { type: "oauth", access: "old-access", refresh: "old-refresh", expires: 1, accountId: "old-account" }, unrelated: { preserved: true } });
await writeFile(path, original, { mode: 0o600 });
// Intentional module-loading boundary: the isolated auth path must exist before client initialization.
const { loginCodex, currentModel, selectModel, availableModels } = await import(${clientPath});
const access = "header." + btoa(JSON.stringify({ "https://api.openai.com/auth": { chatgpt_account_id: "new-account" } })) + ".signature";
const device = () => Response.json({ device_auth_id: "synthetic-device", user_code: "TEST-CODE", interval: 1 });
const approved = () => Response.json({ authorization_code: "synthetic-authorization", code_verifier: "synthetic-verifier" });
const tokens = (refresh = "new-refresh") => Response.json({ access_token: access, refresh_token: refresh, expires_in: 3600 });
`;

test("real SDK device login preserves credentials on failure/cancel and commits privately without selecting a model", async () => {
  await isolated(setup + `
try {
  const before = await selectModel("anthropic/claude-haiku-5-5");
  let mode = "cancel";
  let issuedRefresh = "unapproved-refresh";
  globalThis.fetch = async (input, init) => {
    init?.signal?.throwIfAborted();
    const url = String(input);
    if (url.endsWith("/api/accounts/deviceauth/usercode")) return mode === "fail" ? new Response("synthetic-secret-error", { status: 400 }) : device();
    if (url.endsWith("/api/accounts/deviceauth/token")) return approved();
    if (url === "https://auth.openai.com/oauth/token") {
      const body = new URLSearchParams(init.body);
      assert.equal(body.get("grant_type"), "authorization_code");
      assert.equal(body.get("redirect_uri"), "https://auth.openai.com/deviceauth/callback");
      return tokens(issuedRefresh);
    }
    throw new Error("Unexpected OAuth endpoint");
  };
  for (mode of ["cancel", "fail", "delivery-failed"]) {
    const controller = new AbortController();
    let saving = false;
    await assert.rejects(loginCodex({
      signal: controller.signal,
      async onPrompt() {
        if (mode === "cancel") controller.abort();
        if (mode === "delivery-failed") throw new Error("Discord delivery failed");
      },
      onSaving() { saving = true; },
    }), { message: "Codex login failed" });
    assert.equal(saving, false);
    assert.equal(await readFile(path, "utf8"), original);
    assert.equal(currentModel(), before);
  }
  mode = "approve";
  for (const outcome of ["delivered", "delivery-rejected", "timed-out"]) {
    issuedRefresh = "approved-" + outcome;
    const committing = Promise.withResolvers();
    const delivery = Promise.withResolvers();
    const controller = new AbortController();
    let saving = false;
    const login = loginCodex({
      signal: controller.signal,
      async onPrompt(prompt) {
        assert.equal(prompt.verificationUri, "https://auth.openai.com/codex/device");
        await delivery.promise;
        if (outcome === "timed-out") controller.signal.throwIfAborted();
      },
      onSaving() {
        saving = true;
        committing.resolve();
        controller.abort();
        throw new Error("Saving UI failed");
      },
    });
    await committing.promise;
    assert.equal(saving, true);
    if (outcome === "delivery-rejected") delivery.reject(new Error("Late Discord acknowledgement failed"));
    else delivery.resolve();
    await login;
    const saved = JSON.parse(await readFile(path, "utf8"));
    assert.equal(saved["openai-codex"].access, access);
    assert.equal(saved["openai-codex"].refresh, issuedRefresh);
    assert.equal(saved["openai-codex"].accountId, "new-account");
    assert.deepEqual(saved.unrelated, { preserved: true });
    const file = await stat(path);
    assert.equal(file.mode & 0o777, 0o600);
    assert.equal(file.uid, process.getuid());
    assert.equal(currentModel(), before);
    assert.ok((await availableModels()).some((model) => model.id.startsWith("openai-codex/")));
  }
} finally { await rm(dir, { recursive: true, force: true }); }
`);
});

test("Discord login serializes across guilds and only its initiator can cancel before commit", async () => {
  await isolated(setup + `
import { EventEmitter } from "node:events";
import { MessageFlags, PermissionFlagsBits, PermissionsBitField, Team } from "discord.js";
// This child loads commands after setup establishes the isolated auth/config module boundary.
const { handleCommand } = await import(${commandPath});
const { config } = await import(${JSON.stringify(new URL("../config.ts", import.meta.url).pathname)});
try {
  config.servers.set("other-guild", null);
  let starts = 0;
  let shown = Promise.withResolvers();
  globalThis.fetch = async (input, init) => {
    init?.signal?.throwIfAborted();
    if (String(input).endsWith("/api/accounts/deviceauth/usercode")) { starts++; return device(); }
    if (String(input).endsWith("/api/accounts/deviceauth/token")) {
      const pending = Promise.withResolvers();
      init.signal.addEventListener("abort", () => pending.reject(new Error("cancelled HTTP")), { once: true });
      if (init.signal.aborted) pending.reject(new Error("cancelled HTTP"));
      return pending.promise;
    }
    throw new Error("Unexpected OAuth endpoint");
  };
  const collector = new EventEmitter();
  let stopped = false;
  collector.stop = () => { stopped = true; collector.removeAllListeners(); };
  const team = Object.assign(Object.create(Team.prototype), { ownerId: "owner", id: "team-id" });
  const replies = [];
  const interaction = (guildId, owner = team) => ({
    commandName: "codex-login", guildId, user: { id: "owner" },
    memberPermissions: new PermissionsBitField(PermissionFlagsBits.Administrator),
    channel: { isDMBased: () => false }, inCachedGuild: () => true,
    client: { application: { fetch: async () => ({ owner }) } },
    async deferReply(options) { assert.equal(options.flags, MessageFlags.Ephemeral); },
    async editReply(options) {
      replies.push(options);
      return { createMessageComponentCollector() { shown.resolve(); return collector; } };
    },
  });
  const deps = { ready: () => true, store: {}, retry: async () => { throw new Error("Must not queue model work"); } };
  const nonOwnerTeam = Object.assign(Object.create(Team.prototype), { ownerId: "another-user", id: "owner" });
  await handleCommand(interaction("codex-test", nonOwnerTeam), deps);
  assert.equal(starts, 0);
  const login = handleCommand(interaction("codex-test"), deps);
  await shown.promise;
  await handleCommand(interaction("other-guild", { id: "owner" }), deps);
  assert.equal(starts, 1);
  assert.equal(replies.at(-1).components.length, 0);
  let refused = false;
  collector.emit("collect", { user: { id: "intruder" }, async reply(options) { refused = options.flags === MessageFlags.Ephemeral; } });
  assert.equal(refused, true);
  assert.equal(stopped, false);
  collector.emit("collect", { user: { id: "owner" }, async deferUpdate() {} });
  await login;
  assert.equal(stopped, true);
  assert.equal(await readFile(path, "utf8"), original);
  assert.equal(replies.at(-1).components.length, 0);
  assert.ok(!replies.at(-1).content.includes("TEST-CODE"));
  shown = Promise.withResolvers();
  let expire;
  const realTimeout = globalThis.setTimeout;
  globalThis.setTimeout = (callback, delay, ...args) => {
    if (delay === 10 * 60_000) expire = () => callback(...args);
    return realTimeout(callback, delay, ...args);
  };
  const timedLogin = handleCommand(interaction("other-guild", { id: "owner" }), deps);
  await shown.promise;
  expire();
  await timedLogin;
  globalThis.setTimeout = realTimeout;
  assert.equal(await readFile(path, "utf8"), original);
  assert.equal(replies.at(-1).components.length, 0);
  globalThis.fetch = async () => { starts++; return new Response("synthetic failure", { status: 400 }); };
  await handleCommand(interaction("other-guild", { id: "owner" }), deps);
  assert.equal(starts, 3);
  assert.equal(await readFile(path, "utf8"), original);
} finally { await rm(dir, { recursive: true, force: true }); }
`);
});
