import type { Guild, GuildTextBasedChannel } from "discord.js";
import type { HistoryMessage, ToolCall } from "./memory";
import { TurnAborted } from "./model-context";
import type { Store } from "./store";

export type ToolSchema = {
  type: "function";
  function: { name: string; description: string; parameters: Record<string, unknown> };
};
export type ToolResult = { content: string; footer?: string };
export type ToolContext = {
  signal: AbortSignal;
  store: Store;
  guild: Guild;
  /** The reply channel; everything disclosed must be visible to its whole audience. */
  channel: GuildTextBasedChannel;
  botId: string;
  /** Trigger messages by tag (m1…); notes may only be written about their authors. */
  latest: Map<string, HistoryMessage>;
  /** Marks the turn as having lasting effects, so a newer message no longer aborts it. */
  commit(): void;
  /** Member IDs that can see `channel`, memoised per turn. */
  audience(): string[];
  /** Server search refs (h1…) so the model never handles raw IDs. */
  hits: Map<string, { channelId: string; messageId: string }>;
  /** User IDs whose notes changed this turn and may need pruning. */
  touched: Set<string>;
};
export type Tool = {
  schema: ToolSchema;
  budget: number;
  run(args: Record<string, unknown>, ctx: ToolContext): Promise<ToolResult>;
};

export function stringArg(args: Record<string, unknown>, key: string, max: number): string | null {
  const value = args[key];
  if (typeof value !== "string" || !value.trim()) return null;
  return value.trim().slice(0, max);
}

export const toolError = (message: string): ToolResult => ({ content: JSON.stringify({ error: message }) });

export async function runToolCall(
  call: ToolCall,
  tools: Tool[],
  used: Map<string, number>,
  ctx: ToolContext,
): Promise<ToolResult> {
  const name = call.function.name;
  const tool = tools.find((candidate) => candidate.schema.function.name === name);
  if (!tool) return toolError(`unknown tool ${name}`);
  let args: unknown;
  try { args = JSON.parse(call.function.arguments); } catch { return toolError("invalid arguments"); }
  if (typeof args !== "object" || args === null || Array.isArray(args)) return toolError("invalid arguments");
  const count = used.get(name) ?? 0;
  if (count >= tool.budget) return toolError(`${name} limit reached`);
  used.set(name, count + 1);
  try {
    return await tool.run(args as Record<string, unknown>, ctx);
  } catch (error) {
    if (error instanceof TurnAborted || ctx.signal.aborted) throw new TurnAborted();
    return toolError(error instanceof Error ? error.message : String(error));
  }
}
