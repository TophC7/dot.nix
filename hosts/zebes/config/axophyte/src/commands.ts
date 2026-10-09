import { MessageFlags, PermissionFlagsBits, SlashCommandBuilder, type ChatInputCommandInteraction, type GuildTextBasedChannel } from "discord.js";
import { config } from "./config";
import { limits } from "./limits";
import type { EmojiNotes, People, Store } from "./memory/store";

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
    .setDescription("Tell Axophyte what one of this server's emoji means here (admins)")
    .setDMPermission(false)
    .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
    .addStringOption((option) => option
      .setName("emoji")
      .setDescription("A custom emoji from this server")
      .setRequired(true)
      .setMaxLength(100))
    .addStringOption((option) => option
      .setName("use")
      .setDescription("What it means or when people use it here")
      .setRequired(true)
      .setMaxLength(limits.emojiNoteChars)),
];

export type CommandDeps = {
  store: Store;
  ready(guildId: string): boolean;
  /** Runs a never-aborted forced-search turn in `channel`; resolves once the answer is posted. */
  search(channel: GuildTextBasedChannel, query: string, requester: string): Promise<void>;
};

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

function emojiCommand(interaction: ChatInputCommandInteraction<"cached">, notes: EmojiNotes): string {
  // Server admins can widen a command's default permissions in Integrations; this stays admin-only.
  if (!interaction.memberPermissions.has(PermissionFlagsBits.Administrator)) return "Only server admins can set emoji meanings.";
  const raw = interaction.options.getString("emoji", true).trim();
  const emojis = interaction.guild.emojis.cache;
  const id = /<a?:\w+:(\d+)>/.exec(raw)?.[1];
  const emoji = id ? emojis.get(id) : emojis.find((candidate) => candidate.name === raw.replace(/^:|:$/g, ""));
  if (!emoji?.name) return "Pick one of this server's custom emoji.";
  const use = interaction.options.getString("use", true).trim();
  if (!use) return "Emoji meaning cannot be empty.";
  notes.set(emoji.id, { name: emoji.name, description: use, byAdmin: true });
  return `Saved. Axophyte now reads ${emoji} as: ${use}`;
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
    await respond(emojiCommand(interaction, deps.store.emojiNotes(interaction.guildId)));
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
