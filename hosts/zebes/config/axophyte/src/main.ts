import {
  ChannelType,
  Client,
  Events,
  GatewayIntentBits,
  MessageType,
} from "discord.js";
import type { GuildTextBasedChannel } from "discord.js";
import { COMMANDS, handleCommand } from "./commands";
import type { CommandDeps } from "./commands";
import { config } from "./config";
import type { Source } from "./conversation/load";
import { allowedMentions } from "./discord/reply";
import { openStore } from "./memory/store";
import { Scheduler } from "./schedule";
import { pruneNotes, runTurn } from "./turn";

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent,
    GatewayIntentBits.GuildMembers, GatewayIntentBits.GuildMessageTyping,
  ],
  allowedMentions,
});
const store = openStore(config.dbPath);
let ready = false;
let stopping = false;
/** Settles once the member cache is complete; turns wait on it before checking visibility. */
let membersFresh: Promise<unknown> = Promise.resolve();
const scheduler = new Scheduler(async (key, triggers, signal, commit) => {
  const channel = client.channels.cache.get(key);
  if (!channel?.isTextBased() || channel.isDMBased()) return;
  await membersFresh;
  schedulePrunes(await runTurn(store, sourceFor(channel, triggers), { signal, onCommit: commit }));
});
const commandDeps: CommandDeps = {
  store,
  ready: () => ready,
  search: async (channel, query, requester) => {
    const touched = await scheduler.command(async () => {
      await membersFresh;
      return runTurn(store, sourceFor(channel, new Set()), { forcedSearch: { query, requester }, signal: new AbortController().signal });
    });
    schedulePrunes(touched);
  },
};

const inForum = (channel: GuildTextBasedChannel) => channel.isThread() && channel.parentId === config.forumId;

async function shutdown(code: number): Promise<void> {
  if (stopping) return;
  stopping = true;
  ready = false;
  try { await client.destroy(); }
  catch { console.error("Discord client shutdown failed"); }
  try { store.close(); }
  catch { console.error("memory store shutdown failed"); }
  process.exit(code);
}

function sourceFor(channel: GuildTextBasedChannel, triggers: Set<string>): Source {
  return { channel, forum: inForum(channel), triggers };
}

function schedulePrunes(userIds: string[]): void {
  for (const userId of userIds) {
    void scheduler.command(() => pruneNotes(store, userId)).catch(() => console.error("memory prune failed"));
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
  if (ready && newlyCreated && thread.guildId === config.guildId && inForum(thread) && thread.ownerId) {
    scheduler.message(thread.id, thread.ownerId, thread.id);
  }
});

client.on(Events.MessageCreate, (message) => {
  if (!ready || !message.inGuild() || message.guildId !== config.guildId) return;
  if (message.author.bot || message.webhookId !== null) return;
  if (message.type !== MessageType.Default && message.type !== MessageType.Reply) return;
  const channel = message.channel;
  if (inForum(channel)) {
    // The starter message was already triggered by ThreadCreate.
    if (message.id !== channel.id) scheduler.message(channel.id, message.author.id, message.id);
    return;
  }
  // Direct mentions and replies to Axophyte only; @everyone and role pings never match.
  const botId = client.user!.id;
  if (message.mentions.users.has(botId) || message.mentions.repliedUser?.id === botId || scheduler.follows(channel.id, message.author.id)) {
    scheduler.message(channel.id, message.author.id, message.id);
  }
});

client.on(Events.TypingStart, (typing) => scheduler.typing(typing.channel.id, typing.user.id));

client.on(Events.InteractionCreate, (interaction) => {
  if (interaction.isChatInputCommand()) {
    void handleCommand(interaction, commandDeps).catch(() => console.error("Discord interaction failed"));
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
