import { config } from "./config";
import { effectiveContextSize, limits, THINKING_CONTROL_MODELS } from "./limits";
import { readChatStream, type ChatResult, type ReadChunk } from "./llama-stream";
import type { ChatMessage } from "./memory";
import { ModelError, TurnAborted, type ModelChoice } from "./model-context";

export type ChatBody = {
  messages: ChatMessage[];
  tools?: unknown[];
  max_tokens: number;
  chat_template_kwargs?: Record<string, unknown>;
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
  if (signal?.aborted) throw new TurnAborted();
  const controller = new AbortController();
  let timer: ReturnType<typeof setTimeout> | undefined;
  let timedOut = false;
  let reader: { read: ReadChunk; cancel(): Promise<void>; releaseLock(): void } | undefined;
  function resetDeadline(): void {
    clearTimeout(timer);
    timer = setTimeout(() => {
      timedOut = true;
      controller.abort();
    }, limits.llmIdleTimeoutMs);
  }
  resetDeadline();
  signal?.addEventListener("abort", () => controller.abort(), { once: true });
  try {
    const response = await fetch(`${config.llamaUrl}${path}`, {
      method: body === undefined ? "GET" : "POST",
      headers: body === undefined ? { Accept: "application/json" } : {
        Accept: "application/json, text/event-stream",
        "Content-Type": "application/json",
      },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: controller.signal,
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
        try { errorBody = await readJson(readChunk); } catch {
          if (timedOut) throw new ModelError("timeout", "model response timed out");
        }
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

function chatPath(choice: ModelChoice, suffix = ""): string {
  return `/v1/chat/completions${suffix}${choice.autoload ? "" : "?autoload=false"}`;
}

export async function pickModel(signal?: AbortSignal): Promise<ModelChoice> {
  const selected = await request("/v1/models", undefined, async (readChunk) => {
    const response = await readJson<{ data?: { id?: unknown; status?: { value?: unknown } }[] } | null>(readChunk);
    if (!Array.isArray(response?.data) || response.data.some((entry) =>
      !entry || typeof entry.id !== "string" || !entry.id || typeof entry.status?.value !== "string"
    )) throw new ModelError("unavailable", "model server returned an invalid model list");
    const loaded = response.data.find((entry) => entry.status?.value === "loaded");
    if (loaded) return { id: loaded.id as string, autoload: false };
    const loading = response.data.find((entry) => entry.status?.value === "loading");
    return loading
      ? { id: loading.id as string, autoload: true }
      : { id: config.defaultModel, autoload: true };
  }, signal);
  return request(`/props?model=${encodeURIComponent(selected.id)}${selected.autoload ? "" : "&autoload=false"}`, undefined, async (readChunk) => {
    const props = await readJson<{ default_generation_settings?: { n_ctx?: unknown } } | null>(readChunk);
    return { ...selected, contextSize: effectiveContextSize(props?.default_generation_settings?.n_ctx) };
  }, signal);
}

export async function countTokens(
  choice: ModelChoice,
  body: { messages: ChatMessage[]; tools?: unknown[] },
  signal?: AbortSignal,
): Promise<number> {
  return request(chatPath(choice, "/input_tokens"), { ...body, model: choice.id }, async (readChunk) => {
    const response = await readJson<{ input_tokens?: unknown } | null>(readChunk);
    const count = response?.input_tokens;
    if (typeof count !== "number" || !Number.isSafeInteger(count) || count < 0) {
      throw new ModelError("unavailable", "model server returned an invalid token count");
    }
    return count;
  }, signal);
}

export async function streamChat(
  choice: ModelChoice,
  body: ChatBody,
  onContent: (delta: string) => void,
  signal?: AbortSignal,
): Promise<ChatResult> {
  return request(chatPath(choice), {
    ...body, model: choice.id, stream: true, parallel_tool_calls: false,
  }, (readChunk) => readChatStream(readChunk, onContent), signal);
}

export async function complete(choice: ModelChoice, body: ChatBody, signal?: AbortSignal): Promise<string> {
  return request(chatPath(choice), { ...body, model: choice.id, stream: false }, async (readChunk) => {
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

export function thinkingKwargs(modelId: string, purpose: "answer" | "summary"): Record<string, unknown> | undefined {
  if (THINKING_CONTROL_MODELS[modelId] !== true) return undefined;
  return { chat_template_kwargs: purpose === "answer"
    ? { reasoning_effort: "low" }
    : { enable_thinking: false } };
}
