import {
  ChannelType,
  Events,
  MessageFlags,
  SlashCommandBuilder,
  type ChatInputCommandInteraction,
} from "discord.js";
import { config } from "./config";
import { createClient } from "./discord";
import { isConversationMessage } from "./discord-text";
import { limits } from "./limits";
import { TurnQueue } from "./queue";
import { closeStore, runTurn } from "./turn";

const COMMANDS = [
  new SlashCommandBuilder()
    .setName("search")
    .setDescription("Search the web and answer in this post")
    .setDMPermission(false)
    .addStringOption((option) => option
      .setName("query")
      .setDescription("What to search the web for")
      .setRequired(true)
      .setMaxLength(limits.maxQueryChars)),
];

const client = createClient();
const queue = new TurnQueue();
let ready = false;
let stopping = false;

async function shutdown(code: number): Promise<void> {
  if (stopping) return;
  stopping = true;
  ready = false;
  try { await client.destroy(); }
  catch { console.error("Discord client shutdown failed"); }
  try { closeStore(); }
  catch { console.error("memory store shutdown failed"); }
  process.exit(code);
}

client.once(Events.ClientReady, (connected) => {
  void (async () => {
    const forum = await connected.channels.fetch(config.forumId);
    if (!forum || forum.type !== ChannelType.GuildForum || forum.guildId !== config.guildId) {
      console.error(`forum ${config.forumId} not found or not a forum in guild ${config.guildId}`);
      await shutdown(1);
      return;
    }
    await connected.application.commands.set(COMMANDS, config.guildId);
    if (stopping) return;
    ready = true;
    console.info(`ready as ${connected.user.tag}`);
  })().catch(() => {
    console.error("Discord startup failed");
    void shutdown(1);
  });
});

client.on(Events.ThreadCreate, (thread, newlyCreated) => {
  if (ready && newlyCreated && thread.guildId === config.guildId && thread.parentId === config.forumId) {
    queue.message(thread.id, () => runTurn(thread));
  }
});

client.on(Events.MessageCreate, (message) => {
  if (!ready) return;
  const channel = message.channel;
  if (!channel.isThread()) return;
  if (isConversationMessage({
    guildId: message.guildId,
    channelId: channel.id,
    id: message.id,
    parentId: channel.parentId,
    isThread: true,
    authorIsBot: message.author.bot,
    webhookId: message.webhookId,
    type: message.type,
  }, config.guildId, config.forumId)) {
    queue.message(channel.id, () => runTurn(channel));
  }
});

async function handleCommand(interaction: ChatInputCommandInteraction): Promise<void> {
  const thread = interaction.channel;
  if (interaction.guildId !== config.guildId || !thread?.isThread() || thread.parentId !== config.forumId) {
    await interaction.reply({ content: "Use this inside an Axophyte forum post.", flags: MessageFlags.Ephemeral });
    return;
  }
  await interaction.deferReply({ flags: MessageFlags.Ephemeral });
  // A queued model request can outlive Discord's 15-minute interaction token.
  const respond = (content: string) => interaction.editReply(content).catch(() => {});
  if (!ready) {
    await respond("Axophyte is not ready yet. Try again in a moment.");
    return;
  }
  if (interaction.commandName !== "search") {
    await respond("Unknown command.");
    return;
  }
  const member = interaction.member;
  const requester = member && "displayName" in member
    ? member.displayName
    : member?.nick ?? interaction.user.globalName ?? interaction.user.username;
  try {
    const query = interaction.options.getString("query", true);
    await queue.command(() => runTurn(thread, { forcedSearch: { query, requester } }));
    await respond("Answer posted below.");
  } catch {
    console.error("search command failed");
    await respond("Search failed — try again later.");
  }
}

client.on(Events.InteractionCreate, (interaction) => {
  if (interaction.isChatInputCommand()) {
    void handleCommand(interaction).catch(() => console.error("Discord interaction failed"));
  }
});
client.on(Events.Error, () => console.error("Discord client error"));
client.on(Events.ShardError, () => console.error("Discord gateway error"));
process.once("SIGTERM", () => { void shutdown(0); });
process.once("SIGINT", () => { void shutdown(0); });
void client.login(config.discordToken).catch(() => {
  console.error("Discord login failed; check bot token and enabled intents");
  void shutdown(1);
});
