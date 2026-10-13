import { throwIfAborted, TurnAborted } from "../abort";
import { config } from "../config";
import { readChatStream } from "./protocol";
import type { ChatMessage, ChatResult, ReadChunk } from "./protocol";
import { effectiveContextSize, ModelError, modelSession } from "./model";
import type { ModelChoice } from "./model";

const IDLE_TIMEOUT_MS = 600_000;
const CHAT = "/v1/chat/completions";

type ChatBody = {
  messages: ChatMessage[];
  tools?: unknown[];
  max_tokens: number;
};

async function readJson<T>(readChunk: ReadChunk): Promise<T> {
  const decoder = new TextDecoder("utf-8", { fatal: true });
  let text = "";
  for (;;) {
    const chunk = await readChunk();
    if (chunk.done) break;
    text += decoder.decode(chunk.value, { stream: true });
  }
  text += decoder.decode();
  return JSON.parse(text) as T;
}

// One idle deadline covers HTTP queue waits, response bodies, and streamed chunks.
async function request<T>(
  path: string,
  body: Record<string, unknown> | undefined,
  consume: (readChunk: ReadChunk) => Promise<T>,
  signal?: AbortSignal,
): Promise<T> {
  throwIfAborted(signal);
  const controller = new AbortController();
  let timer: ReturnType<typeof setTimeout> | undefined;
  let timedOut = false;
  let reader: { read: ReadChunk; cancel(): Promise<void>; releaseLock(): void } | undefined;
  function resetDeadline(): void {
    clearTimeout(timer);
    timer = setTimeout(() => {
      timedOut = true;
      controller.abort();
    }, IDLE_TIMEOUT_MS);
  }
  resetDeadline();
  try {
    const response = await fetch(`${config.llamaUrl}${path}`, {
      method: body === undefined ? "GET" : "POST",
      headers: body === undefined ? { Accept: "application/json" } : {
        Accept: "application/json, text/event-stream",
        "Content-Type": "application/json",
      },
      body: body === undefined ? undefined : JSON.stringify({ ...body, model: config.model }),
      signal: signal ? AbortSignal.any([controller.signal, signal]) : controller.signal,
      // Model queue waits can exceed Bun's native deadline; use our idle timer only.
      timeout: false,
    });
    reader = response.body?.getReader();
    if (!reader) throw new ModelError("unavailable", "model server returned an empty response");
    const readChunk: ReadChunk = async () => {
      const chunk = await reader!.read();
      if (!chunk.done && chunk.value.byteLength) resetDeadline();
      return chunk;
    };
    if (!response.ok) {
      if (response.status === 400) {
        let errorBody: { error?: { message?: unknown } } | null = null;
        try { errorBody = await readJson(readChunk); } catch { /* outer catch maps timeouts */ }
        const message = errorBody?.error?.message;
        if (typeof message === "string") {
          const normalized = message.toLowerCase();
          if (normalized.includes("model is not loaded")) {
            throw new ModelError("not_loaded", "model is not loaded");
          }
          if (normalized.includes("prompt is too long")) {
            throw new ModelError("too_long", "model prompt is too long");
          }
        }
      }
      throw new ModelError("unavailable", `model request failed (HTTP ${response.status})`);
    }
    return await consume(readChunk);
  } catch (error) {
    if (signal?.aborted) throw new TurnAborted();
    if (timedOut) throw new ModelError("timeout", "model response timed out");
    if (error instanceof ModelError) throw error;
    // Never surface response bodies, fetch diagnostics, or request contents.
    throw new ModelError("unavailable", "model server unavailable or returned an invalid response");
  } finally {
    clearTimeout(timer);
    controller.abort();
    if (reader) {
      try { await reader.cancel(); } catch { /* Aborted fetches may already have errored. */ }
      reader.releaseLock();
    }
  }
}

export async function requestModel(signal?: AbortSignal): Promise<ModelChoice> {
  return request(`/props?model=${encodeURIComponent(config.model)}`, undefined, async (readChunk) => {
    const props = await readJson<{ default_generation_settings?: { n_ctx?: unknown } } | null>(readChunk);
    return { contextSize: effectiveContextSize(props?.default_generation_settings?.n_ctx) };
  }, signal);
}

export async function countTokens(body: { messages: ChatMessage[]; tools?: unknown[] }, signal?: AbortSignal): Promise<number> {
  return request(`${CHAT}/input_tokens`, body, async (readChunk) => {
    const response = await readJson<{ input_tokens?: unknown } | null>(readChunk);
    const count = response?.input_tokens;
    if (typeof count !== "number" || !Number.isSafeInteger(count) || count < 0) {
      throw new ModelError("unavailable", "model server returned an invalid token count");
    }
    return count;
  }, signal);
}

export async function streamChat(body: ChatBody, onContent: (delta: string) => void, signal?: AbortSignal): Promise<ChatResult> {
  return request(CHAT, {
    ...body, chat_template_kwargs: { reasoning_effort: "low" }, stream: true, parallel_tool_calls: false,
  }, (readChunk) => readChatStream(readChunk, onContent), signal);
}

export async function complete(body: ChatBody, signal?: AbortSignal): Promise<string> {
  return request(CHAT, { ...body, chat_template_kwargs: { enable_thinking: false }, stream: false }, async (readChunk) => {
    const response = await readJson<{ choices?: { message?: { content?: unknown } }[] } | null>(readChunk);
    if (!Array.isArray(response?.choices) || !response.choices.length || !response.choices[0]?.message) {
      throw new ModelError("unavailable", "model server returned an invalid completion");
    }
    const content = response.choices[0].message.content;
    if (content != null && typeof content !== "string") {
      throw new ModelError("unavailable", "model server returned an invalid completion");
    }
    return content ?? "";
  }, signal);
}

/** One standalone completion with its own not-loaded retry, for background jobs. */
export async function ask(messages: ChatMessage[], maxTokens: number): Promise<string> {
  const session = await modelSession(requestModel);
  return session.call(() => complete({ messages, max_tokens: maxTokens }));
}
