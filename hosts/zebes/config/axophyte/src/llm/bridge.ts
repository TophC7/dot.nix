import type { Api, AssistantMessage, Context, ImageContent, Model, TextContent, Tool } from "@earendil-works/pi-ai";
import type { ChatMessage, ChatResult } from "./protocol";
import { ModelError } from "./model";
import { object } from "./protocol";

export function sdkContext(messages: ChatMessage[], tools: unknown[] | undefined, model: Model<Api>): Context {
  const names = new Map<string, string>();
  const context: Context = { messages: [] };
  for (const message of messages) {
    if (message.role === "assistant") {
      for (const call of message.tool_calls ?? []) names.set(call.id, call.function.name);
      if (message.nativeAssistant) {
        // Never reconstruct these blocks: Gemini signatures and Codex IDs are opaque protocol state.
        context.messages.push(message.nativeAssistant);
      } else {
        const assistant: AssistantMessage = {
          role: "assistant", content: [], api: model.api, provider: model.provider, model: model.id,
          usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
          stopReason: message.tool_calls?.length ? "toolUse" : "stop", timestamp: 0,
        };
        if (message.content) assistant.content.push({ type: "text", text: message.content });
        for (const call of message.tool_calls ?? []) {
          assistant.content.push({ type: "toolCall", id: call.id, name: call.function.name, arguments: JSON.parse(call.function.arguments) });
        }
        context.messages.push(assistant);
      }
    } else if (message.role === "tool") {
      const toolName = names.get(message.tool_call_id);
      if (!toolName) throw new ModelError("unavailable", "Invalid tool result context");
      context.messages.push({ role: "toolResult", toolCallId: message.tool_call_id, toolName, content: [{ type: "text", text: message.content }], isError: false, timestamp: 0 });
    } else if (message.role === "system") {
      const text = typeof message.content === "string" ? message.content : message.content.filter((part) => part.type === "text").map((part) => part.text).join("\n");
      context.messages.push({ role: "system", content: text, timestamp: 0 });
    } else {
      const content: (TextContent | ImageContent)[] = [];
      if (typeof message.content === "string") content.push({ type: "text", text: message.content });
      else for (const part of message.content) {
        if (part.type === "text") content.push(part);
        else if (!model.input.includes("image")) content.push({ type: "text", text: "[Image omitted: the selected model cannot see images.]" });
        else {
          const image = /^data:(image\/(?:png|jpeg|webp|gif));base64,([A-Za-z0-9+/=]+)$/.exec(part.image_url.url);
          if (!image) throw new ModelError("unavailable", "Unsupported image input");
          content.push({ type: "image", mimeType: image[1]!, data: image[2]! });
        }
      }
      context.messages.push({ role: "user", content, timestamp: 0 });
    }
  }
  if (tools) context.tools = tools.map((schema) => {
    if (!object(schema) || !object(schema.function) || typeof schema.function.name !== "string"
      || typeof schema.function.description !== "string" || !object(schema.function.parameters)) {
      throw new ModelError("unavailable", "Invalid tool schema");
    }
    return { name: schema.function.name, description: schema.function.description, parameters: schema.function.parameters } as Tool;
  });
  return context;
}

export function chatResult(message: AssistantMessage): ChatResult {
  const text: string[] = [];
  const toolCalls: ChatResult["toolCalls"] = [];
  for (const block of message.content) {
    if (block.type === "text") text.push(block.text);
    else if (block.type === "toolCall") toolCalls.push({
      id: block.id, type: "function", function: { name: block.name, arguments: JSON.stringify(block.arguments) },
    });
  }
  return {
    content: text.join(""),
    toolCalls,
    finishReason: message.stopReason,
    nativeAssistant: message,
  };
}

/** Conservative estimate: UTF-8 bytes (not chars/4), framing, and 8192 tokens per inline image. */
export function estimatedTokens(messages: ChatMessage[], tools?: unknown[], supportsImages = true): number {
  const bytes = (text: string) => Buffer.byteLength(text, "utf8");
  let tokens = 256 + (tools ? bytes(JSON.stringify(tools)) : 0);
  for (const message of messages) {
    tokens += 128;
    if (message.role === "assistant" && message.nativeAssistant) {
      for (const block of message.nativeAssistant.content) {
        if (block.type === "text") tokens += bytes(block.text);
        else if (block.type === "thinking") tokens += bytes(block.thinking);
        else tokens += bytes(JSON.stringify(block.arguments)) + bytes(block.name) + 64;
      }
    } else {
      if (typeof message.content === "string") tokens += bytes(message.content);
      else if (Array.isArray(message.content)) for (const part of message.content) {
        tokens += part.type === "text" ? bytes(part.text) : supportsImages ? 8192 : 64;
      }
      if (message.role === "assistant") tokens += bytes(JSON.stringify(message.tool_calls ?? []));
    }
  }
  return tokens;
}

export function hasImages(messages: ChatMessage[]): boolean {
  return messages.some((message) => Array.isArray(message.content) && message.content.some((part) => part.type === "image_url"));
}
