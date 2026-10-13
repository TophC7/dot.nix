import { expect, test } from "bun:test";
import { createModels } from "@earendil-works/pi-ai";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import { googleProvider } from "@earendil-works/pi-ai/providers/google";
import { deepseekProvider } from "@earendil-works/pi-ai/providers/deepseek";
import { chatResult, estimatedTokens, sdkContext } from "./bridge";
import type { ChatMessage } from "./protocol";

const models = createModels();
models.setProvider(googleProvider());
models.setProvider(deepseekProvider());

test("tool continuation retains opaque provider payload without exposing reasoning", () => {
  const model = models.getModels("google")[0]!;
  const native: AssistantMessage = {
    role: "assistant", api: model.api, provider: model.provider, model: model.id,
    responseId: "opaque-response-id", timestamp: 1, stopReason: "toolUse",
    usage: { input: 1, output: 1, cacheRead: 0, cacheWrite: 0, totalTokens: 2, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
    content: [
      { type: "thinking", thinking: "private reasoning", thinkingSignature: "opaque-thinking-signature" },
      { type: "text", text: "Visible answer", textSignature: "opaque-text-id" },
      { type: "toolCall", id: "call-id|provider-id", name: "lookup", arguments: { value: "a\\b", nested: [1, true] }, thoughtSignature: "opaque-tool-signature" },
    ],
  };
  const result = chatResult(native);
  expect(result.content).toBe("Visible answer");
  expect(JSON.parse(result.toolCalls[0]!.function.arguments)).toEqual({ value: "a\\b", nested: [1, true] });
  const messages: ChatMessage[] = [
    { role: "assistant", content: result.content, tool_calls: result.toolCalls, nativeAssistant: result.nativeAssistant },
    { role: "tool", tool_call_id: result.toolCalls[0]!.id, content: '{"result":"unchanged"}' },
  ];
  const context = sdkContext(messages, undefined, model);
  expect(context.messages[0]).toBe(native);
  expect(context.messages[1]).toMatchObject({ role: "toolResult", toolName: "lookup", toolCallId: "call-id|provider-id", content: [{ type: "text", text: '{"result":"unchanged"}' }] });
});

test("text-only provider omits image bytes truthfully and budget ignores base64 size", () => {
  const model = models.getModels("deepseek").find((model) => !model.input.includes("image"))!;
  const images = (size: number): ChatMessage[] => [{ role: "user", content: [{ type: "text", text: "What is this?" }, { type: "image_url", image_url: { url: `data:image/png;base64,${"A".repeat(size)}` } }] }];
  const context = sdkContext(images(100_000), undefined, model);
  expect(JSON.stringify(context)).not.toContain("base64");
  expect(JSON.stringify(context)).toContain("cannot see images");
  expect(estimatedTokens(images(4))).toBe(estimatedTokens(images(100_000)));
  expect(estimatedTokens(images(4), undefined, false)).toBeLessThan(estimatedTokens(images(4)));
});
