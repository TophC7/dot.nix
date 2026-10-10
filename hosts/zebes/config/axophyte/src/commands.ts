import { MessageFlags, PermissionFlagsBits, SlashCommandBuilder, type AutocompleteInteraction, type ChatInputCommandInteraction, type GuildTextBasedChannel } from "discord.js";
import { config } from "./config";
import { APP_EMOJI_SCOPE, emojiScope, usableEmoji } from "./discord/emoji";
import { limits } from "./limits";
import type { People, Store } from "./memory/store";

export const COMMANDS = [
  new SlashCommandBuilder()
    .setName("search")
    .setDescription("Search the web and answer here")
    .setDMPermission(false)
    .addStringOption((option) => option
      .setName("query")
      .setDescription("What to search the web for")
      .setRequired(true)
      .setMaxLength(limits.maxQueryChars)),
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
      .setMaxLength(limits.emojiNoteChars)),
  new SlashCommandBuilder()
    .setName("retry")
    .setDescription("Answer the latest message here as if it just arrived (admins)")
    .setDMPermission(false)
    .setDefaultMemberPermissions(PermissionFlagsBits.Administrator),
];

export type CommandDeps = {
  store: Store;
  ready(guildId: string): boolean;
  /** Runs a never-aborted forced-search turn in `channel`; resolves once the answer is posted. */
  search(channel: GuildTextBasedChannel, query: string, requester: string): Promise<void>;
  /** Queues the newest human message in `channel` as a fresh trigger; false when there is none. */
  retry(channel: GuildTextBasedChannel): Promise<boolean>;
};

// Server admins can widen a command's default permissions in Integrations; admin commands check again.
const isAdmin = (interaction: ChatInputCommandInteraction<"cached">) => interaction.memberPermissions.has(PermissionFlagsBits.Administrator);

function memoryCommand(interaction: ChatInputCommandInteraction, people: People): string {
  const userId = interaction.user.id;
  if (interaction.options.getSubcommand() === "show") {
    const facts = people.facts(userId);
    if (!facts.length) return "I don't remember anything about you.";
    let text = "";
    for (const [index, { id, fact }] of facts.entries()) {
      const line = `#${id} ${fact}\n`;
      if (text.length + line.length > limits.splitAt) return `${text}…and ${facts.length - index} more`;
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
  const scope = emojiScope(emoji);
  store.emojiNotes(scope).set(emoji.id, { name: emoji.name, description: use, byAdmin: true });
  return `Saved${scope === APP_EMOJI_SCOPE ? " for every server" : ""}. Axophyte now reads ${emoji} as: ${use}`;
}

/** Lists Axophyte's own emoji too, which admins can't pick from their own emoji menu. */
export async function handleAutocomplete(interaction: AutocompleteInteraction): Promise<void> {
  if (!interaction.inCachedGuild() || interaction.commandName !== "emoji") return interaction.respond([]);
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
  // A queued model request can outlive Discord's 15-minute interaction token.
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
  if (interaction.commandName === "retry") {
    await respond(!isAdmin(interaction) ? "Only server admins can use /retry."
      : await deps.retry(channel) ? "Answering the latest message again." : "No message to answer here.");
    return;
  }
  if (interaction.commandName !== "search") {
    await respond("Unknown command.");
    return;
  }
  const requester = interaction.member.displayName;
  try {
    const query = interaction.options.getString("query", true);
    await deps.search(channel, query, requester);
    await respond("Answer posted below.");
  } catch {
    console.error("search command failed");
    await respond("Search failed — try again later.");
  }
}
