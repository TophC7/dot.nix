import {
  ChannelType,
  Client,
  Events,
  GatewayIntentBits,
} from "discord.js";
import type { GuildTextBasedChannel, Message } from "discord.js";
import { COMMANDS, handleAutocomplete, handleCommand } from "./commands";
import type { CommandDeps } from "./commands";
import { config } from "./config";
import { APP_EMOJI_SCOPE } from "./discord/emoji";
import { limits } from "./limits";
import { allowedMentions } from "./discord/reply";
import { openStore } from "./memory/store";
import { Scheduler } from "./schedule";
import { describeEmoji, pruneNotes, runTurn } from "./turn";
import { EmojiDescriptions } from "./memory/emoji";

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent,
    GatewayIntentBits.GuildMembers, GatewayIntentBits.GuildMessageTyping, GatewayIntentBits.GuildExpressions,
  ],
  allowedMentions,
});
const store = openStore(config.dbPath);
const activeThreads = store.activeThreads();
const inactiveThreads = new Set<string>();
/** Configured servers whose member cache is complete; Axophyte ignores the rest. */
const ready = new Set<string>();
let stopping = false;
/** Settles once member caches are complete; turns wait on it before checking visibility. */
let membersFresh: Promise<unknown> = Promise.resolve();
const scheduler = new Scheduler(async (key, triggers, signal, commit) => {
  const channel = client.channels.cache.get(key);
  if (!channel?.isTextBased() || channel.isDMBased()) return;
  await membersFresh;
  // A failed member refresh drops the server from `ready`; queued turns there must not trust stale visibility.
  if (!ready.has(channel.guildId)) return;
  const forum = inForum(channel);
  const thread = !forum && channel.isThread() && activeThreads.has(channel.id);
  schedulePrunes(channel.guildId, await runTurn(store, { channel, forum, thread, triggers }, { signal, onCommit: commit }));
});
const emojiDescriptions = new EmojiDescriptions(store, scheduler, describeEmoji,
  (scope) => !stopping && (scope === APP_EMOJI_SCOPE ? ready.size > 0 : ready.has(scope)));
const commandDeps: CommandDeps = {
  store,
  ready: (guildId) => ready.has(guildId),
  retry: async (channel) => {
    // Discord returns newest first; history reloads as usual, as if the message just arrived.
    const latest = (await channel.messages.fetch({ limit: limits.retryScanMessages })).find(humanPost);
    if (latest) scheduler.message(channel.id, latest.author.id, latest.id);
    return !!latest;
  },
};

function inForum(channel: GuildTextBasedChannel): boolean {
  const forumId = config.servers.get(channel.guildId);
  return !!forumId && channel.isThread() && channel.parentId === forumId;
}
async function isThreadActive(channel: GuildTextBasedChannel): Promise<boolean> {
  if (!channel.isThread() || inForum(channel)) return false;
  if (activeThreads.has(channel.id)) return true;
  if (inactiveThreads.has(channel.id)) return false;
  const starter = await channel.fetchStarterMessage().catch(() => null);
  if (starter?.author.id === client.user?.id) {
    activeThreads.add(channel.id);
    store.trackThread(channel.id);
    void channel.join().catch(() => {});
    return true;
  }
  inactiveThreads.add(channel.id);
  return false;
}


/** A person's own chat message: no bots, webhooks, or system notices. */
function humanPost(message: Message): boolean {
  return !message.author.bot && message.webhookId === null && !message.system;
}

async function shutdown(code: number): Promise<void> {
  if (stopping) return;
  stopping = true;
  ready.clear();
  try { await client.destroy(); }
  catch { console.error("Discord client shutdown failed"); }
  try { store.close(); }
  catch { console.error("memory store shutdown failed"); }
  process.exit(code);
}

function schedulePrunes(guildId: string, userIds: string[]): void {
  for (const userId of userIds) {
    void scheduler.command(() => pruneNotes(store.people(guildId), userId)).catch(() => console.error("memory prune failed"));
  }
}

client.once(Events.ClientReady, (connected) => {
  // ponytail: no gateway events for application emoji; new uploads show up after a restart.
  const ownEmojiFresh = connected.application.emojis.fetch().then(() => true, (error: unknown) => {
    console.error("own emoji refresh failed", error);
    return false;
  });
  // One broken server (bot removed, forum deleted) must not take the others down.
  void Promise.all([...config.servers].map(async ([guildId, forumId]) => {
    try {
      const guild = await connected.guilds.fetch(guildId);
      if (forumId) {
        const forum = await connected.channels.fetch(forumId);
        if (forum?.type !== ChannelType.GuildForum || forum.guildId !== guildId) throw new Error("forum not found");
      }
      // A failed emoji refresh skips reconciliation, not the server's chat startup.
      const [, , emojiFresh] = await Promise.all([
        guild.members.fetch(),
        guild.commands.set(COMMANDS),
        guild.emojis.fetch().then(() => true, (error: unknown) => {
          console.error(`server ${guildId} emoji refresh failed`, error);
          return false;
        }),
      ]);
      if (!stopping) {
        ready.add(guildId);
        if (emojiFresh && await ownEmojiFresh) emojiDescriptions.seed(guildId, guild.emojis.cache, connected.application.emojis.cache);
      }
    } catch (error) {
      console.error(`server ${guildId} skipped: not joined, forum ${forumId} not a forum there, or startup failed`, error);
    }
  })).then(async () => {
    if (stopping) return;
    // Nothing usable (e.g. network down at boot): exit so systemd retries.
    if (!ready.size) return shutdown(1);
    console.info(`ready as ${connected.user.tag} in ${ready.size}/${config.servers.size} servers`);
    if (await ownEmojiFresh) emojiDescriptions.seed(APP_EMOJI_SCOPE, connected.application.emojis.cache);
  });
});

// A re-identify can miss member and role updates; refetch before trusting visibility again.
client.on(Events.ShardReady, () => {
  if (!ready.size) return; // First connect: ClientReady fetches.
  membersFresh = Promise.allSettled([...ready].map(async (guildId) => {
    const guild = client.guilds.cache.get(guildId);
    if (!guild) {
      ready.delete(guildId);
      throw new Error(`server ${guildId} missing from cache`);
    }
    try {
      await guild.members.fetch();
    } catch (error) {
      ready.delete(guildId);
      throw error;
    }
  })).then((results) => {
    for (const r of results) {
      if (r.status === "rejected") console.error("member refresh failed:", r.reason);
    }
    if (!ready.size) {
      console.error("all servers failed member refresh");
      void shutdown(1);
    }
  });
});

client.on(Events.GuildDelete, (guild) => {
  ready.delete(guild.id);
});

client.on(Events.GuildEmojiCreate, (emoji) => emojiDescriptions.enqueue(emoji));
client.on(Events.GuildEmojiUpdate, (_old, emoji) => emojiDescriptions.enqueue(emoji));
client.on(Events.GuildEmojiDelete, (emoji) => emojiDescriptions.delete(emoji));

client.on(Events.ThreadCreate, async (thread, newlyCreated) => {
  if (!ready.has(thread.guildId)) return;
  if (newlyCreated && inForum(thread) && thread.ownerId) {
    scheduler.message(thread.id, thread.ownerId, thread.id);
    return;
  }
  if (!inForum(thread) && thread.isThread()) {
    const starter = await thread.fetchStarterMessage().catch(() => null);
    if (starter?.author.id === client.user?.id) {
      activeThreads.add(thread.id);
      inactiveThreads.delete(thread.id);
      store.trackThread(thread.id);
      void thread.join().catch(() => {});
    }
  }
});

client.on(Events.MessageCreate, async (message) => {
  if (!message.inGuild() || !ready.has(message.guildId)) return;
  if (!humanPost(message)) return;
  const channel = message.channel;
  if (inForum(channel)) {
    // The starter message was already triggered by ThreadCreate.
    if (message.id !== channel.id) scheduler.message(channel.id, message.author.id, message.id);
    return;
  }
  const botId = client.user!.id;
  const botRole = message.mentions.roles.some((role) => role.tags?.botId === botId || role.id === message.guild?.members.me?.roles.botRole?.id);
  const mentioned = message.mentions.users.has(botId) || botRole || message.mentions.repliedUser?.id === botId;
  if (channel.isThread()) {
    if (mentioned) {
      activeThreads.add(channel.id);
      inactiveThreads.delete(channel.id);
      store.trackThread(channel.id);
      void channel.join().catch(() => {});
      scheduler.message(channel.id, message.author.id, message.id);
      return;
    }
    if (await isThreadActive(channel)) {
      scheduler.message(channel.id, message.author.id, message.id);
      return;
    }
    return;
  }
  if (mentioned || scheduler.follows(channel.id, message.author.id)) {
    scheduler.message(channel.id, message.author.id, message.id);
  }
});

client.on(Events.TypingStart, (typing) => scheduler.typing(typing.channel.id, typing.user.id));

client.on(Events.InteractionCreate, (interaction) => {
  if (interaction.isChatInputCommand()) {
    void handleCommand(interaction, commandDeps).catch(() => console.error("Discord interaction failed"));
  } else if (interaction.isAutocomplete()) {
    void handleAutocomplete(interaction).catch(() => console.error("Discord autocomplete failed"));
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
