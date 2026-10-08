import type { ToolCall } from "./memory";

export type ChatResult = {
  content: string;
  toolCalls: ToolCall[];
  finishReason: string | null;
};

export type ReadChunk = () => Promise<
  { done: false; value: Uint8Array } | { done: true; value?: Uint8Array }
>;

function object(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

// Kept independent of runtime configuration so wire-format regressions need no server.
export async function readChatStream(readChunk: ReadChunk, onContent: (delta: string) => void): Promise<ChatResult> {
  const decoder = new TextDecoder("utf-8", { fatal: true });
  const calls = new Map<number, ToolCall>();
  let pending = "";
  let data: string[] = [];
  let done = false;
  let content = "";
  let finishReason: string | null = null;
  function invalid(): never { throw new Error("invalid model stream"); }
  function event(): void {
    if (!data.length) return;
    const text = data.join("\n");
    data = [];
    if (text.trim() === "[DONE]") { done = true; return; }
    let payload: unknown;
    try { payload = JSON.parse(text); } catch { invalid(); }
    if (!object(payload) || !Array.isArray(payload.choices)) invalid();
    if (!payload.choices.length) return; // Some servers send a final usage-only event.
    const choice = payload.choices[0];
    if (!object(choice) || !object(choice.delta)) invalid();
    if (choice.finish_reason != null) {
      if (typeof choice.finish_reason !== "string") invalid();
      finishReason = choice.finish_reason;
    }
    const delta = choice.delta;
    if (delta.content != null) {
      if (typeof delta.content !== "string") invalid();
      content += delta.content;
      if (delta.content) onContent(delta.content);
    }
    // reasoning_content is deliberately never forwarded or retained.
    if (delta.tool_calls == null) return;
    if (!Array.isArray(delta.tool_calls)) invalid();
    for (const part of delta.tool_calls) {
      if (!object(part) || !Number.isInteger(part.index) || (part.index as number) < 0) invalid();
      if (part.type != null && part.type !== "function") invalid();
      const index = part.index as number;
      let call = calls.get(index);
      if (!call) {
        call = { id: "", type: "function", function: { name: "", arguments: "" } };
        calls.set(index, call);
      }
      if (part.id != null) {
        if (typeof part.id !== "string") invalid();
        if (!call.id && part.id) call.id = part.id;
      }
      if (part.function != null) {
        if (!object(part.function)) invalid();
        const fn = part.function;
        if (fn.name != null) {
          if (typeof fn.name !== "string") invalid();
          if (!call.function.name && fn.name) call.function.name = fn.name;
        }
        if (fn.arguments != null) {
          if (typeof fn.arguments !== "string") invalid();
          call.function.arguments += fn.arguments;
        }
      }
    }
  }

  function line(text: string): void {
    if (text.endsWith("\r")) text = text.slice(0, -1);
    if (!text) event();
    else if (text === "data") data.push("");
    else if (text.startsWith("data:")) {
      const value = text.slice(5);
      data.push(value.startsWith(" ") ? value.slice(1) : value);
    }
  }

  while (!done) {
    const chunk = await readChunk();
    pending += chunk.done ? decoder.decode() : decoder.decode(chunk.value, { stream: true });
    let end: number;
    while (!done && (end = pending.indexOf("\n")) !== -1) {
      line(pending.slice(0, end));
      pending = pending.slice(end + 1);
    }
    if (chunk.done) {
      if (!done && pending) line(pending);
      if (!done) event();
      if (!done) throw new Error("model stream ended before completion");
      break;
    }
  }
  const toolCalls = [...calls.entries()].sort(([a], [b]) => a - b).map(([, call]) => call);
  if (toolCalls.some((call) => !call.id || !call.function.name)) invalid();
  return { content, toolCalls, finishReason };
}
