import {
  ChannelType,
  cleanContent,
  PermissionFlagsBits,
  type APIThreadChannel,
  type Guild,
  type GuildBasedChannel,
  type GuildTextBasedChannel,
  type NonThreadGuildBasedChannel,
} from "discord.js";

// Privacy invariant: content from a source channel may reach the model only when
// every member who can see the reply channel can also read that source. Who asks
// (owner, admin) never widens this.
export type Place = { id: string; privateThread: boolean; canRead(memberId: string): boolean };

export function discloses(source: Place, replyChannelId: string, audience: string[]): boolean {
  if (source.id === replyChannelId) return true;
  if (source.privateThread) return false;
  return audience.every((id) => source.canRead(id));
}

function place(id: string, privateThread: boolean, base: NonThreadGuildBasedChannel): Place {
  return {
    id,
    privateThread,
    canRead(memberId) {
      const member = base.guild.members.cache.get(memberId);
      return !!member && !!base.permissionsFor(member)?.has([PermissionFlagsBits.ViewChannel, PermissionFlagsBits.ReadMessageHistory]);
    },
  };
}

// Threads inherit their parent's permissions; an unknown parent is never disclosable.
export function placeOf(channel: GuildBasedChannel): Place | null {
  const base = channel.isThread() ? channel.parent : channel;
  return base ? place(channel.id, channel.type === ChannelType.PrivateThread, base) : null;
}

// Search payloads may name archived threads the gateway cache never saw.
export function placeFromApi(guild: Guild, channelId: string, threads: APIThreadChannel[]): Place | null {
  const cached = guild.channels.cache.get(channelId);
  if (cached) return placeOf(cached);
  const thread = threads.find((candidate) => candidate.id === channelId);
  if (!thread?.parent_id) return null;
  const parent = guild.channels.cache.get(thread.parent_id);
  return parent && !parent.isThread() ? place(channelId, thread.type === ChannelType.PrivateThread, parent) : null;
}

// Threads count everyone who can view the parent: exact for public threads, a
// superset (so stricter) for private ones.
export function audienceOf(channel: GuildTextBasedChannel): string[] {
  const base = channel.isThread() ? channel.parent : channel;
  const members = channel.guild.members.cache;
  // Unknown parent: assume everyone is watching, the strictest audience.
  if (!base) return [...members.keys()];
  return [...members.filter((member) => !!base.permissionsFor(member)?.has(PermissionFlagsBits.ViewChannel)).keys()];
}

// Public = readable by every member, so learning there can be shown anywhere.
export function isPublic(channel: GuildBasedChannel): boolean {
  const source = placeOf(channel);
  return !!source && discloses(source, "", [...channel.guild.members.cache.keys()]);
}

// cleanContent names any cached channel; names of non-public channels stay hidden.
export function cleanText(content: string, channel: GuildTextBasedChannel): string {
  const masked = content.replace(/<#(\d+)>/g, (token, id: string) => {
    const target = channel.guild.channels.cache.get(id);
    return target && (id === channel.id || isPublic(target)) ? token : "#private-channel";
  });
  return cleanContent(masked, channel);
}
