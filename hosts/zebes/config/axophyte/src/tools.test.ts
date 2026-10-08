import { expect, test } from "bun:test";
import type { ToolCall } from "./memory";
import { TurnAborted } from "./model-context";
import { runToolCall, type Tool, type ToolContext } from "./tools";

const call: ToolCall = { id: "call-1", type: "function", function: { name: "web_search", arguments: "{}" } };
const ctx = { signal: new AbortController().signal } as ToolContext;

function fakeTool(run: Tool["run"]): Tool {
  return { budget: 2, schema: { type: "function", function: { name: "web_search", description: "", parameters: {} } }, run };
}

// Budgets cap paid Tavily credits per turn.
test("budget exhaustion stops calls before they run", async () => {
  let runs = 0;
  const tools = [fakeTool(async () => { runs++; return { content: "ok" }; })];
  const used = new Map<string, number>();
  for (let i = 0; i < 2; i++) await runToolCall(call, tools, used, ctx);
  expect(await runToolCall(call, tools, used, ctx)).toEqual({ content: '{"error":"web_search limit reached"}' });
  expect(runs).toBe(2);
});

// A swallowed abort would keep a superseded turn running and posting.
test("aborts propagate instead of becoming tool errors", async () => {
  const tools = [fakeTool(async () => { throw new TurnAborted(); })];
  await expect(runToolCall(call, tools, new Map(), ctx)).rejects.toBeInstanceOf(TurnAborted);
});
