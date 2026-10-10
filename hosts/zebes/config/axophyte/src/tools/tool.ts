import { limits } from "../limits";
import { object } from "../llm/protocol";
import type { ToolCall } from "../llm/protocol";
import { TurnAborted } from "../llm/model";

type ToolSchema = {
  type: "function";
  function: { name: string; description: string; parameters: Record<string, unknown> };
};
type ToolResult = { content: string; footer?: string };
export type Tool = {
  schema: ToolSchema;
  budget: number;
  run(args: Record<string, unknown>, signal: AbortSignal): Promise<ToolResult>;
};

export function defineTool(spec: {
  name: keyof typeof limits.toolBudgets;
  description: string;
  properties: Record<string, unknown>;
  required: string[];
  run: Tool["run"];
}): Tool {
  const { name, description, properties, required, run } = spec;
  return {
    budget: limits.toolBudgets[name],
    schema: { type: "function", function: { name, description, parameters: { type: "object", properties, required } } },
    run,
  };
}

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
  signal: AbortSignal,
): Promise<ToolResult> {
  const name = call.function.name;
  const tool = tools.find((candidate) => candidate.schema.function.name === name);
  if (!tool) return toolError(`unknown tool ${name}`);
  let args: unknown;
  try { args = JSON.parse(call.function.arguments); } catch { return toolError("invalid arguments"); }
  if (!object(args)) return toolError("invalid arguments");
  const count = used.get(name) ?? 0;
  if (count >= tool.budget) return toolError(`${name} limit reached; answer with what you have`);
  used.set(name, count + 1);
  try {
    return await tool.run(args, signal);
  } catch (error) {
    if (error instanceof TurnAborted || signal.aborted) throw new TurnAborted();
    return toolError(error instanceof Error ? error.message : String(error));
  }
}
