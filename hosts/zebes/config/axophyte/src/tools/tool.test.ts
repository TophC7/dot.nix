import { expect, test } from "bun:test";
import type { ToolCall } from "../llm/protocol";
import { TurnAborted } from "../llm/model";
import { runToolCall } from "./tool";
import type { Tool } from "./tool";

const call: ToolCall = { id: "call-1", type: "function", function: { name: "web_search", arguments: "{}" } };
const signal = new AbortController().signal;

function fakeTool(run: Tool["run"]): Tool {
  return { budget: 2, schema: { type: "function", function: { name: "web_search", description: "", parameters: {} } }, run };
}

// Budgets cap paid Tavily credits per turn.
test("budget exhaustion stops calls before they run", async () => {
  let runs = 0;
  const tools = [fakeTool(async () => { runs++; return { content: "ok" }; })];
  const used = new Map<string, number>();
  for (let i = 0; i < 2; i++) await runToolCall(call, tools, used, signal);
  expect(JSON.parse((await runToolCall(call, tools, used, signal)).content)).toHaveProperty("error");
  expect(runs).toBe(2);
});

// A swallowed abort would keep a superseded turn running and posting.
test("aborts propagate instead of becoming tool errors", async () => {
  const tools = [fakeTool(async () => { throw new TurnAborted(); })];
  await expect(runToolCall(call, tools, new Map(), signal)).rejects.toBeInstanceOf(TurnAborted);
});
