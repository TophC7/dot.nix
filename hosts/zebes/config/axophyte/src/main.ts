import {
  ChannelType,
  Events,
  MessageFlags,
  MessageType,
  SlashCommandBuilder,
  type ChatInputCommandInteraction,
  type GuildTextBasedChannel,
} from "discord.js";
import { Burst } from "./burst";
import { config } from "./config";
import type { Source } from "./context";
import { createClient } from "./discord";
import { isConversationMessage } from "./discord-text";
import { limits } from "./limits";
import { TurnQueue } from "./queue";
import { closeStore, pruneNotes, runTurn, store } from "./turn";

const COMMANDS = [
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

const client = createClient();
const queue = new TurnQueue();
const burst = new Burst((key) => queue.message(key, () => job(key)));
let ready = false;
let stopping = false;
/** Settles once the member cache is complete; turns wait on it before checking visibility. */
let membersFresh: Promise<unknown> = Promise.resolve();

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

function sourceFor(channel: GuildTextBasedChannel, triggers: Set<string>): Source {
  return channel.isThread() && channel.parentId === config.forumId
    ? { kind: "forum", thread: channel, triggers }
    : { kind: "channel", channel, triggers };
}

function schedulePrunes(userIds: string[]): void {
  for (const userId of userIds) {
    void queue.command(() => pruneNotes(userId)).catch(() => console.error("memory prune failed"));
  }
}

async function job(key: string): Promise<void> {
  // The gate reopened after this job was queued; its own fire will run the turn.
  if (burst.pending(key)) return;
  const triggers = burst.take(key);
  const channel = client.channels.cache.get(key);
  if (!channel?.isTextBased() || channel.isDMBased()) return;
  const controller = new AbortController();
  let started = false;
  const unregister = burst.running(key, triggers, controller, () => started);
  try {
    await membersFresh;
    const source = sourceFor(channel, new Set(triggers.keys()));
    schedulePrunes(await runTurn(source, { signal: controller.signal, onCommit: () => { started = true; } }));
  } finally {
    unregister();
  }
}

client.once(Events.ClientReady, (connected) => {
  void (async () => {
    const forum = await connected.channels.fetch(config.forumId);
    if (!forum || forum.type !== ChannelType.GuildForum || forum.guildId !== config.guildId) {
      console.error(`forum ${config.forumId} not found or not a forum in guild ${config.guildId}`);
      await shutdown(1);
      return;
    }
    // Visibility checks need every member; discord.js keeps this cache current afterwards.
    await forum.guild.members.fetch();
    await connected.application.commands.set(COMMANDS, config.guildId);
    if (stopping) return;
    ready = true;
    console.info(`ready as ${connected.user.tag}`);
  })().catch(() => {
    console.error("Discord startup failed");
    void shutdown(1);
  });
});

// A re-identify can miss member and role updates; refetch before trusting visibility again.
client.on(Events.ShardReady, () => {
  if (!ready) return; // First connect: ClientReady fetches.
  const guild = client.guilds.cache.get(config.guildId);
  membersFresh = (guild ? guild.members.fetch() : Promise.reject(new Error("guild missing"))).catch(() => {
    console.error("member refresh failed");
    void shutdown(1);
  });
});

client.on(Events.ThreadCreate, (thread, newlyCreated) => {
  if (ready && newlyCreated && thread.guildId === config.guildId && thread.parentId === config.forumId && thread.ownerId) {
    burst.message(thread.id, thread.ownerId, thread.id);
  }
});

client.on(Events.MessageCreate, (message) => {
  if (!ready || !message.inGuild() || message.guildId !== config.guildId) return;
  if (message.author.bot || message.webhookId !== null) return;
  if (message.type !== MessageType.Default && message.type !== MessageType.Reply) return;
  const channel = message.channel;
  if (channel.isThread() && channel.parentId === config.forumId) {
    if (isConversationMessage({
      guildId: message.guildId,
      channelId: channel.id,
      id: message.id,
      parentId: channel.parentId,
      isThread: true,
      authorIsBot: message.author.bot,
      webhookId: message.webhookId,
      type: message.type,
    }, config.guildId, config.forumId)) burst.message(channel.id, message.author.id, message.id);
    return;
  }
  // Direct mentions and replies to Axophyte only; @everyone and role pings never match.
  const botId = client.user!.id;
  if (message.mentions.users.has(botId) || message.mentions.repliedUser?.id === botId || burst.follows(channel.id, message.author.id)) {
    burst.message(channel.id, message.author.id, message.id);
  }
});

client.on(Events.TypingStart, (typing) => burst.typing(typing.channel.id, typing.user.id));

function memoryCommand(interaction: ChatInputCommandInteraction): string {
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

async function handleCommand(interaction: ChatInputCommandInteraction): Promise<void> {
  const channel = interaction.channel;
  if (!interaction.inCachedGuild() || interaction.guildId !== config.guildId || !channel || channel.isDMBased()) {
    await interaction.reply({ content: "Use this in a server channel.", flags: MessageFlags.Ephemeral });
    return;
  }
  await interaction.deferReply({ flags: MessageFlags.Ephemeral });
  // A queued model request can outlive Discord's 15-minute interaction token.
  const respond = (content: string) => interaction.editReply(content).catch(() => {});
  if (!ready) {
    await respond("Axophyte is not ready yet. Try again in a moment.");
    return;
  }
  if (interaction.commandName === "memory") {
    await respond(memoryCommand(interaction));
    return;
  }
  if (interaction.commandName !== "search") {
    await respond("Unknown command.");
    return;
  }
  const requester = interaction.member.displayName;
  try {
    const query = interaction.options.getString("query", true);
    const source = sourceFor(channel, new Set());
    // Explicit commands are never gated or aborted by the burst gate.
    const touched = await queue.command(async () => {
      await membersFresh;
      return runTurn(source, { forcedSearch: { query, requester }, signal: new AbortController().signal });
    });
    schedulePrunes(touched);
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
  console.error("Discord login failed; check bot token and enabled intents (Message Content, Server Members)");
  void shutdown(1);
});
