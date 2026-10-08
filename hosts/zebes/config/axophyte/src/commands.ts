import { MessageFlags, SlashCommandBuilder, type ChatInputCommandInteraction, type GuildTextBasedChannel } from "discord.js";
import { config } from "./config";
import { limits } from "./limits";
import type { Store } from "./memory/store";

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
];

export type CommandDeps = {
  store: Store;
  ready(): boolean;
  /** Runs a never-aborted forced-search turn in `channel`; resolves once the answer is posted. */
  search(channel: GuildTextBasedChannel, query: string, requester: string): Promise<void>;
};

function memoryCommand(interaction: ChatInputCommandInteraction, store: Store): string {
  const userId = interaction.user.id;
  if (interaction.options.getSubcommand() === "show") {
    const facts = store.facts(userId);
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
  if (item === "all") return `Forgot everything (${store.forgetAll(userId)} notes).`;
  if (!/^#?\d{1,15}$/.test(item)) return "Use a note number from /memory show, or all.";
  const id = Number(item.replace("#", ""));
  return store.forgetFact(userId, id) ? `Forgot #${id}.` : `No note #${id} of yours.`;
}

export async function handleCommand(interaction: ChatInputCommandInteraction, deps: CommandDeps): Promise<void> {
  const channel = interaction.channel;
  if (!interaction.inCachedGuild() || interaction.guildId !== config.guildId || !channel || channel.isDMBased()) {
    await interaction.reply({ content: "Use this in a server channel.", flags: MessageFlags.Ephemeral });
    return;
  }
  await interaction.deferReply({ flags: MessageFlags.Ephemeral });
  // A queued model request can outlive Discord's 15-minute interaction token.
  const respond = (content: string) => interaction.editReply(content).catch(() => {});
  if (!deps.ready()) {
    await respond("Axophyte is not ready yet. Try again in a moment.");
    return;
  }
  if (interaction.commandName === "memory") {
    await respond(memoryCommand(interaction, deps.store));
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
