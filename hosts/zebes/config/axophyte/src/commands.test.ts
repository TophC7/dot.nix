import { afterAll, expect, spyOn, test } from "bun:test";
import { MessageFlags, PermissionFlagsBits, PermissionsBitField } from "discord.js";
import type { AutocompleteInteraction, ChatInputCommandInteraction } from "discord.js";
import type { CommandDeps } from "./commands";

// Exercise the real catalog and selection without provider requests or module mocks.
const defaults = {
  AXOPHYTE_DISCORD_TOKEN: "command-test",
  AXOPHYTE_TAVILY_KEY: "command-test",
  AXOPHYTE_SERVERS: '{"command-test":null}',
  AXOPHYTE_LLAMA_URL: "http://127.0.0.1:1",
  AXOPHYTE_MODEL: "command-test-local",
  AXOPHYTE_WHISPER_MODEL: "command-test-whisper",
  AXOPHYTE_SVG_FONTS: "/unused",
};
const previous = Object.fromEntries(Object.keys(defaults).map((key) => [key, process.env[key]]));
for (const [key, value] of Object.entries(defaults)) process.env[key] ??= value;
// Static imports cannot work here: config validates required env when the module first loads.
const { handleAutocomplete, handleCommand } = await import("./commands");
const { config } = await import("./config");
const { availableModels, currentModel, selectModel } = await import("./llm/client");
for (const [key, value] of Object.entries(previous)) {
  if (value === undefined) delete process.env[key];
  else process.env[key] = value;
}
const guildId = "model-command-regression-guild";
config.servers.set(guildId, null);
afterAll(() => { config.servers.delete(guildId); });

function interaction(name: string | null, admin = true, guild = guildId) {
  const replies: string[] = [];
  const flags: number[] = [];
  const choices: { name: string; value: string }[][] = [];
  // Only Discord transport is replaced; permission bits, command routing, and model state are real.
  const value = {
    commandName: "model",
    guildId: guild,
    memberPermissions: new PermissionsBitField(admin ? PermissionFlagsBits.Administrator : 0n),
    channel: { isDMBased: () => false },
    inCachedGuild: () => true,
    options: { getString: () => name, getFocused: () => name ?? "" },
    deferReply: async (options: { flags: number }) => { flags.push(options.flags); },
    editReply: async (content: string) => { replies.push(content); },
    reply: async (options: { content: string; flags: number }) => {
      replies.push(options.content);
      flags.push(options.flags);
    },
    respond: async (options: { name: string; value: string }[]) => { choices.push(options); },
  };
  return { value, replies, flags, choices };
}
const deps: CommandDeps = {
  store: {} as CommandDeps["store"],
  ready: () => true,
  retry: async () => { throw new Error("model command must not retry a turn"); },
};

test("model dispatch checks runtime admin, configured guild, and readiness before reading a selection", async () => {
  const before = currentModel();
  for (const [admin, guild, ready] of [
    [false, guildId, true],
    [true, "unconfigured-model-command-guild", true],
    [true, guildId, false],
  ] as const) {
    const request = interaction("local", admin, guild);
    request.value.options.getString = () => { throw new Error("unauthorized selection was read"); };
    await handleCommand(request.value as unknown as ChatInputCommandInteraction, { ...deps, ready: () => ready });
    expect(request.flags).toEqual([MessageFlags.Ephemeral]);
    expect(currentModel()).toBe(before);
  }
});

test("model status, rejected selection, and local selection use the real selection state", async () => {
  await selectModel("local");
  const before = currentModel();
  const status = interaction(null);
  await handleCommand(status.value as unknown as ChatInputCommandInteraction, deps);
  expect(status.replies[0]).toContain(before.id);
  expect(currentModel()).toBe(before);

  const invalid = interaction("unknown-provider/unknown-model");
  await handleCommand(invalid.value as unknown as ChatInputCommandInteraction, deps);
  expect(currentModel()).toBe(before);

  const local = interaction("local");
  await handleCommand(local.value as unknown as ChatInputCommandInteraction, deps);
  expect(currentModel().id).toBe("local");
  for (const request of [status, invalid, local]) expect(request.flags).toEqual([MessageFlags.Ephemeral]);
});

test("model autocomplete matches labels case-insensitively and keeps authorization guards", async () => {
  const local = (await availableModels()).find((model) => model.id === "local")!;
  const request = interaction(local.label.toUpperCase());
  await handleAutocomplete(request.value as unknown as AutocompleteInteraction, deps);
  expect(request.choices[0]!.map((model) => model.value)).toContain("local");
  for (const [admin, guild, ready] of [
    [false, guildId, true],
    [true, "unconfigured-model-command-guild", true],
    [true, guildId, false],
  ] as const) {
    const request = interaction("local", admin, guild);
    request.value.options.getFocused = () => { throw new Error("unauthorized catalog was read"); };
    await handleAutocomplete(request.value as unknown as AutocompleteInteraction, { ready: () => ready });
    expect(request.choices).toEqual([[]]);
  }
});

test("Codex login is guild/admin-only and fails closed on application ownership", async () => {
  for (const [admin, guild, ready] of [
    [false, guildId, true],
    [true, "unconfigured-codex-command-guild", true],
    [true, guildId, false],
  ] as const) {
    const request = interaction(null, admin, guild);
    request.value.commandName = "codex-login";
    await handleCommand(request.value as unknown as ChatInputCommandInteraction, { ...deps, ready: () => ready });
    expect(request.flags).toEqual([MessageFlags.Ephemeral]);
  }
  const network = spyOn(globalThis, "fetch").mockRejectedValue(new Error("Unauthorized provider request"));
  try {
    for (const owner of [{ id: "another-user" }, null]) {
      const request = interaction(null);
      request.value.commandName = "codex-login";
      await handleCommand({
        ...request.value,
        user: { id: "initiator" },
        client: { application: { fetch: async () => ({ owner }) } },
        editReply: async () => {},
      } as unknown as ChatInputCommandInteraction, deps);
      expect(network).not.toHaveBeenCalled();
    }
    const request = interaction(null);
    request.value.commandName = "codex-login";
    await handleCommand({
      ...request.value,
      user: { id: "initiator" },
      client: { application: { fetch: async () => { throw new Error("unavailable"); } } },
      editReply: async () => {},
    } as unknown as ChatInputCommandInteraction, deps);
    expect(network).not.toHaveBeenCalled();
  } finally { network.mockRestore(); }
});
