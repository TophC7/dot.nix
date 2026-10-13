import { MessageFlags, PermissionFlagsBits, SlashCommandBuilder } from "discord.js";
import type { AutocompleteInteraction, ChatInputCommandInteraction, GuildTextBasedChannel } from "discord.js";
import { config } from "./config";
import { usableEmoji } from "./discord/emoji";
import { codexLoginCommand } from "./discord/codex-login";
import type { People, Store } from "./memory/store";
import { SPLIT_AT } from "./discord/reply";
import { EMOJI_NOTE_CHARS } from "./memory/emoji";
import { availableModels, currentModel, selectModel } from "./llm/client";

export const COMMANDS = [
  new SlashCommandBuilder()
    .setName("memory")
    .setDescription("What Axophyte remembers about you")
    .setDMPermission(false)
    .addSubcommand((sub) => sub.setName("show").setDescription("Show your notes"))
    .addSubcommand((sub) => sub
      .setName("forget")
      .setDescription("Forget one note, or all of them")
      .addStringOption((option) => option
        .setName("item")
        .setDescription("Note number from /memory show, or all")
        .setRequired(true)
        .setMaxLength(20))),
  new SlashCommandBuilder()
    .setName("emoji")
    .setDescription("Tell Axophyte what an emoji means (admins)")
    .setDMPermission(false)
    .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
    .addStringOption((option) => option
      .setName("emoji")
      .setDescription("This server's emoji or Axophyte's own; pick from the list")
      .setRequired(true)
      .setAutocomplete(true)
      .setMaxLength(100))
    .addStringOption((option) => option
      .setName("use")
      .setDescription("What it means or when people use it here")
      .setRequired(true)
      .setMaxLength(EMOJI_NOTE_CHARS)),
  new SlashCommandBuilder()
    .setName("retry")
    .setDescription("Answer the latest message here as if it just arrived (admins)")
    .setDMPermission(false)
    .setDefaultMemberPermissions(PermissionFlagsBits.Administrator),
  new SlashCommandBuilder()
    .setName("model")
    .setDescription("Show or change Axophyte's model bot-wide (admins)")
    .setDMPermission(false)
    .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
    .addStringOption((option) => option
      .setName("name")
      .setDescription("Model to use for new work; local restores llama.cpp")
      .setRequired(false)
      .setAutocomplete(true)
      .setMaxLength(100)),
  new SlashCommandBuilder()
    .setName("codex-login")
    .setDescription("Connect the bot owner's Codex subscription (owner and admin only)")
    .setDMPermission(false)
    .setDefaultMemberPermissions(PermissionFlagsBits.Administrator),
];

export type CommandDeps = {
  store: Store;
  ready(guildId: string): boolean;
  /** Queues the newest human message in `channel` as a fresh trigger; false when there is none. */
  retry(channel: GuildTextBasedChannel): Promise<boolean>;
};

// Server admins can widen a command's default permissions in Integrations; admin commands check again.
const isAdmin = (interaction: ChatInputCommandInteraction<"cached"> | AutocompleteInteraction<"cached">) => interaction.memberPermissions.has(PermissionFlagsBits.Administrator);

function memoryCommand(interaction: ChatInputCommandInteraction, people: People): string {
  const userId = interaction.user.id;
  if (interaction.options.getSubcommand() === "show") {
    const facts = people.facts(userId);
    if (!facts.length) return "I don't remember anything about you.";
    let text = "";
    for (const [index, { id, fact }] of facts.entries()) {
      const line = `#${id} ${fact}\n`;
      if (text.length + line.length > SPLIT_AT) return `${text}…and ${facts.length - index} more`;
      text += line;
    }
    return text.trimEnd();
  }
  const item = interaction.options.getString("item", true).trim().toLowerCase();
  if (item === "all") return `Forgot everything (${people.forgetAll(userId)} notes).`;
  if (!/^#?\d{1,15}$/.test(item)) return "Use a note number from /memory show, or all.";
  const id = Number(item.replace("#", ""));
  return people.forgetFact(userId, id) ? `Forgot #${id}.` : `No note #${id} of yours.`;
}

function emojiCommand(interaction: ChatInputCommandInteraction<"cached">, store: Store): string {
  if (!isAdmin(interaction)) return "Only server admins can set emoji meanings.";
  const raw = interaction.options.getString("emoji", true).trim();
  const id = /<a?:\w+:(\d+)>/.exec(raw)?.[1];
  const name = raw.replace(/^:|:$/g, "");
  const emoji = usableEmoji(interaction.guild).find((candidate) => id ? candidate.id === id : candidate.name === name);
  if (!emoji?.name) return "Pick one of this server's custom emoji or Axophyte's own.";
  const use = interaction.options.getString("use", true).trim();
  if (!use) return "Emoji meaning cannot be empty.";
  // Per server even for Axophyte's own emoji: one server's admins must not steer another server's prompt.
  store.emojiNotes(interaction.guildId).set(emoji.id, { name: emoji.name, description: use, byAdmin: true });
  return `Saved for this server. Axophyte now reads ${emoji} as: ${use}`;
}

async function modelCommand(interaction: ChatInputCommandInteraction<"cached">): Promise<string> {
  if (!isAdmin(interaction)) return "Only server admins can use /model.";
  const name = interaction.options.getString("name");
  if (name === null) {
    const model = currentModel();
    return `Active model: ${model.label} (${model.id}). Selection is bot-wide; restarting resets to local llama.cpp.`;
  }
  try {
    const model = await selectModel(name);
    const privacy = model.id === "local" ? "" : ` Prompts, Discord context, memory, and attachments are sent to ${model.provider}.`;
    return `Selected ${model.label} (${model.id}) bot-wide for new work. Running work keeps its captured model. Restarting resets to local llama.cpp.${privacy}`;
  } catch {
    return "Couldn't select that model. Choose an available model from autocomplete and check its provider credentials. This request did not change the active model.";
  }
}

/** Lists models and Axophyte's own emoji too, without exposing provider credentials. */
export async function handleAutocomplete(interaction: AutocompleteInteraction, deps: Pick<CommandDeps, "ready">): Promise<void> {
  if (!interaction.inCachedGuild()) return interaction.respond([]);
  if (interaction.commandName === "model") {
    if (!config.servers.has(interaction.guildId) || !deps.ready(interaction.guildId) || !isAdmin(interaction)) return interaction.respond([]);
    const typed = interaction.options.getFocused().toLowerCase();
    const models = await availableModels().catch(() => []);
    await interaction.respond(models
      .filter((model) => model.id.toLowerCase().includes(typed) || model.label.toLowerCase().includes(typed))
      .slice(0, 25)
      .map((model) => ({ name: model.label.slice(0, 100), value: model.id })));
    return;
  }
  if (interaction.commandName !== "emoji") return interaction.respond([]);
  const typed = interaction.options.getFocused().replace(/^:|:$/g, "").toLowerCase();
  await interaction.respond(usableEmoji(interaction.guild)
    .filter((emoji) => emoji.name!.toLowerCase().includes(typed))
    .slice(0, 25)
    .map((emoji) => ({ name: `:${emoji.name}:${"guild" in emoji ? "" : " (Axophyte's own)"}`, value: String(emoji) })));
}

export async function handleCommand(interaction: ChatInputCommandInteraction, deps: CommandDeps): Promise<void> {
  const channel = interaction.channel;
  if (!interaction.inCachedGuild() || !config.servers.has(interaction.guildId) || !channel || channel.isDMBased()) {
    await interaction.reply({ content: "Use this in a server channel.", flags: MessageFlags.Ephemeral });
    return;
  }
  await interaction.deferReply({ flags: MessageFlags.Ephemeral });
  const respond = (content: string) => interaction.editReply(content).catch(() => {});
  if (!deps.ready(interaction.guildId)) {
    await respond("Axophyte is not ready yet. Try again in a moment.");
    return;
  }
  if (interaction.commandName === "memory") {
    await respond(memoryCommand(interaction, deps.store.people(interaction.guildId)));
    return;
  }
  if (interaction.commandName === "emoji") {
    await respond(emojiCommand(interaction, deps.store));
    return;
  }
  if (interaction.commandName === "model") {
    await respond(await modelCommand(interaction));
    return;
  }
  if (interaction.commandName === "codex-login") {
    if (!isAdmin(interaction)) await respond("Only server admins can use /codex-login.");
    else await codexLoginCommand(interaction);
    return;
  }
  if (interaction.commandName !== "retry") {
    await respond("Unknown command.");
    return;
  }
  if (!isAdmin(interaction)) await respond("Only server admins can use /retry.");
  // Turns never answer in locked threads.
  else if (channel.isThread() && channel.locked) await respond("This thread is locked.");
  else {
    const queued = await deps.retry(channel).catch((error: unknown) => {
      console.error("retry failed", error);
      return null;
    });
    await respond(queued === null ? "Couldn't read this channel." : queued ? "Answering the latest message again." : "No message to answer here.");
  }
}
