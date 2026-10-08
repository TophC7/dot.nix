import { afterAll, describe, expect, test } from "bun:test";
import { ChannelType, Client, PermissionFlagsBits, type Guild, type GuildBasedChannel } from "discord.js";
import { discloses, isPublic, placeOf, type Place } from "./visibility";

function source(readers: string[], privateThread = false): Place {
  return { id: "source", privateThread, canRead: (id) => readers.includes(id) };
}

test("discloses only what every audience member can already read", () => {
  expect(discloses(source([]), "source", ["anyone"])).toBe(true);
  expect(discloses(source(["owner", "member"], true), "reply", ["owner", "member"])).toBe(false);
  // The owner asking in a public channel never widens the audience.
  expect(discloses(source(["owner"]), "reply", ["owner", "member"])).toBe(false);
  expect(discloses(source(["owner", "member", "extra"]), "reply", ["owner", "member"])).toBe(true);
});

describe("placeOf with discord.js permissions", () => {
  const client = new Client({ intents: [] });
  afterAll(() => client.destroy());
  const view = String(PermissionFlagsBits.ViewChannel | PermissionFlagsBits.ReadMessageHistory);
  const user = (id: string) => ({ id, username: id, discriminator: "0", global_name: null, avatar: null });
  // No public constructor builds a cached guild from raw gateway data.
  const guild = (client.guilds as unknown as { _add(data: unknown): Guild })._add({
    id: "1", name: "test", owner_id: "99", icon: null, features: [], unavailable: false,
    roles: [
      { id: "1", name: "@everyone", permissions: view, position: 0, color: 0, hoist: false, managed: false, mentionable: false, flags: 0 },
      { id: "2", name: "staff", permissions: "0", position: 1, color: 0, hoist: false, managed: false, mentionable: false, flags: 0 },
    ],
    channels: [
      { id: "10", type: ChannelType.GuildText, name: "general", position: 0, permission_overwrites: [] },
      {
        id: "11", type: ChannelType.GuildText, name: "staff", position: 1, permission_overwrites: [
          { id: "1", type: 0, allow: "0", deny: String(PermissionFlagsBits.ViewChannel) },
          { id: "2", type: 0, allow: String(PermissionFlagsBits.ViewChannel), deny: "0" },
        ],
      },
    ],
    threads: [
      { id: "20", type: ChannelType.PublicThread, name: "staff thread", parent_id: "11", guild_id: "1", thread_metadata: { archived: false, auto_archive_duration: 60, archive_timestamp: new Date().toISOString(), locked: false } },
      { id: "21", type: ChannelType.PrivateThread, name: "secret", parent_id: "10", guild_id: "1", thread_metadata: { archived: false, auto_archive_duration: 60, archive_timestamp: new Date().toISOString(), locked: false } },
    ],
    members: [
      { user: user("100"), roles: ["2"], joined_at: new Date().toISOString(), deaf: false, mute: false, flags: 0 },
      { user: user("101"), roles: [], joined_at: new Date().toISOString(), deaf: false, mute: false, flags: 0 },
    ],
  });
  const channel = (id: string) => guild.channels.cache.get(id) as GuildBasedChannel;

  test("overwrites decide who can read; threads inherit their parent", () => {
    const staff = placeOf(channel("11"))!;
    expect(staff.canRead("100")).toBe(true);
    expect(staff.canRead("101")).toBe(false);
    const thread = placeOf(channel("20"))!;
    expect(thread.canRead("100")).toBe(true);
    expect(thread.canRead("101")).toBe(false);
    expect(discloses(thread, "10", ["100", "101"])).toBe(false);
    expect(discloses(placeOf(channel("10"))!, "11", ["100"])).toBe(true);
  });

  test("only channels every member can read are public", () => {
    expect(isPublic(channel("10"))).toBe(true);
    expect(isPublic(channel("11"))).toBe(false);
    expect(isPublic(channel("20"))).toBe(false);
    expect(isPublic(channel("21"))).toBe(false);
  });
});
