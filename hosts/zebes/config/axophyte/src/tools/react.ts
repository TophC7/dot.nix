import type { GuildTextBasedChannel } from "discord.js";
import { tagged } from "../conversation/history";
import type { HistoryMessage } from "../conversation/history";
import { reactionEmoji } from "../discord/emoji";
import { TurnAborted } from "../llm/model";
import { defineTool, stringArg, toolError } from "./tool";
import type { Tool } from "./tool";

export function reactTool(
  channel: GuildTextBasedChannel,
  latest: HistoryMessage[],
  onCommit: () => void,
  onReact: (reply: boolean) => void,
): Tool {
  return defineTool({
    name: "react",
    description: "React to a tagged message with an emoji: a server emoji as :name: or a regular emoji. Set reply to say whether you also want to write a message.",
    properties: {
      message: { type: "string", description: "Message tag, e.g. m1" },
      emoji: { type: "string", description: "Server emoji as :name: or name, or a regular unicode emoji" },
      reply: { type: "boolean", description: "true to write a message as well; false if the reaction is your whole reply" },
    },
    required: ["message", "emoji", "reply"],
    async run(args, signal) {
      const message = tagged(latest, stringArg(args, "message", 10) ?? "");
      if (typeof message === "string") return toolError(message);
      const emoji = stringArg(args, "emoji", 100);
      if (!emoji || typeof args.reply !== "boolean") return toolError("invalid arguments");
      const resolved = reactionEmoji(emoji, channel.guild);
      if (signal.aborted) throw new TurnAborted();
      onCommit();
      // Discord rejections throw; runToolCall turns them into tool errors, so onReact only follows success.
      await channel.messages.react(message.id, resolved);
      onReact(args.reply);
      return { content: JSON.stringify({ reacted: true }) };
    },
  });
}
