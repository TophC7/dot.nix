import { expect, test } from "bun:test";
import { readChatStream } from "./protocol";

async function decode(text: string, width: number, onContent: (text: string) => void = () => {}) {
  const bytes = new TextEncoder().encode(text);
  let offset = 0;
  const reader = new ReadableStream<Uint8Array>({
    pull(controller) {
      if (offset === bytes.length) { controller.close(); return; }
      const end = Math.min(offset + width, bytes.length);
      controller.enqueue(bytes.subarray(offset, end));
      offset = end;
    },
  }).getReader();
  try {
    return await readChatStream(() => reader.read(), onContent);
  } finally {
    await reader.cancel();
    reader.releaseLock();
  }
}

test("SSE fragmentation preserves UTF-8, CRLF, content and indexed tool calls, never reasoning", async () => {
  const fixture = ': heartbeat\r\n\r\n' +
    'data: {"choices":[{"delta":{"reasoning_content":"private thinking","content":"Hi 🐙"}}]}\r\n\r\n' +
    'event: message\n' +
    'data: {"choices":[\n' +
    'data: {"delta":{"tool_calls":[{"index":1,"id":"second","type":"function","function":{"name":"web_search","arguments":"{\\"query\\":\\""}},{"index":0,"id":"first","function":{"name":"web_search","arguments":"{\\"query\\":\\"Ni"}}]}}]}\n\n' +
    'data: {"choices":[{"delta":{"content":"!","reasoning_content":"also private","tool_calls":[{"index":0,"id":"ignored","function":{"name":"ignored","arguments":"xOS\\"}"}},{"index":1,"function":{"arguments":"kernel\\"}"}}]},"finish_reason":"tool_calls"}]}\r\n\r\n' +
    'data: {"choices":[],"usage":{"prompt_tokens":1}}\n\n' +
    'data: [DONE]\r\n\r\n' +
    'data: not consumed\n\n';
  for (const width of [1, 7, 4096]) {
    const deltas: string[] = [];
    expect(await decode(fixture, width, (delta) => deltas.push(delta))).toEqual({
      content: "Hi 🐙!",
      toolCalls: [
        { id: "first", type: "function", function: { name: "web_search", arguments: '{"query":"NixOS"}' } },
        { id: "second", type: "function", function: { name: "web_search", arguments: '{"query":"kernel"}' } },
      ],
      finishReason: "tool_calls",
    });
    expect(deltas).toEqual(["Hi 🐙", "!"]);
  }
});

test("truncated or malformed streams fail instead of silently completing", async () => {
  await expect(decode('data: {"choices":[{"delta":{"content":"partial"}}]}\n\n', 1))
    .rejects.toThrow("model stream ended before completion");
  await expect(decode('data: sensitive malformed server text\n\ndata: [DONE]\n\n', 3))
    .rejects.toThrow("invalid model stream");
});
