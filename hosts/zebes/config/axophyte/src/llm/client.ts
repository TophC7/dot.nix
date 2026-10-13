import { createModels, isContextOverflow } from "@earendil-works/pi-ai";
import type { Api, Model } from "@earendil-works/pi-ai";
import { anthropicProvider } from "@earendil-works/pi-ai/providers/anthropic";
import { openaiCodexProvider } from "@earendil-works/pi-ai/providers/openai-codex";
import { deepseekProvider } from "@earendil-works/pi-ai/providers/deepseek";
import { googleProvider } from "@earendil-works/pi-ai/providers/google";
import { throwIfAborted, TurnAborted } from "../abort";
import { config } from "../config";
import * as llama from "./llama";
import { effectiveContextSize, IDLE_TIMEOUT_MS, MAX_OUTPUT_TOKENS, ModelError, modelSession, promptBudget } from "./model";
import type { ModelChoice } from "./model";
import type { ChatBody, ChatMessage, ChatResult } from "./protocol";
import { chatResult, estimatedTokens, hasImages, sdkContext } from "./bridge";
import { OAuthFileStore } from "./credentials";

export type ModelOption = { id: string; label: string };
export type ModelClient = Readonly<ModelOption & {
  provider: string;
  supportsImages: boolean;
  requestModel(signal?: AbortSignal): Promise<ModelChoice>;
  countTokens(body: Pick<ChatBody, "messages" | "tools">, signal?: AbortSignal): Promise<number>;
  streamChat(body: ChatBody, onContent: (delta: string) => void, signal?: AbortSignal): Promise<ChatResult>;
  complete(body: ChatBody, signal?: AbortSignal): Promise<string>;
}>;

const credentials = new OAuthFileStore();
const envKeys: Record<string, string> = { anthropic: "ANTHROPIC_API_KEY", deepseek: "DEEPSEEK_API_KEY", google: "GEMINI_API_KEY" };
const allowedEnv: Record<string, true> = Object.fromEntries(Object.values(envKeys).map((key) => [key, true]));
const models = createModels({
  credentials,
  // Do not accept SDK ambient OAuth/API-key aliases: these three providers are API billing only.
  authContext: { env: async (name) => allowedEnv[name] ? process.env[name]?.trim() || undefined : undefined, fileExists: async () => false },
});
for (const provider of [anthropicProvider(), openaiCodexProvider(), deepseekProvider(), googleProvider()]) models.setProvider(provider);

const local: ModelClient = Object.freeze({
  id: "local", label: `Local · ${config.model}`, provider: "local", supportsImages: true,
  requestModel: llama.requestModel, countTokens: llama.countTokens, streamChat: llama.streamChat, complete: llama.complete,
});
let selected = local;
let selectionGeneration = 0;

export function currentModel(): ModelClient { return selected; }

export type CodexLoginPrompt = { userCode: string; verificationUri: string };

/** Device OAuth only; issued tokens are saved even if cancellation arrives during the commit. */
export async function loginCodex(options: {
  signal: AbortSignal;
  onPrompt(prompt: CodexLoginPrompt): Promise<void>;
  /** Synchronously stop cancellation. UI failure must not discard issued tokens. */
  onSaving(): void;
}): Promise<void> {
  const controller = new AbortController();
  const signal = AbortSignal.any([options.signal, controller.signal]);
  let delivery = Promise.resolve();
  try {
    signal.throwIfAborted();
    const oauth = models.getProvider("openai-codex")?.auth?.oauth;
    if (!oauth) throw new Error("Codex OAuth unavailable");
    const credential = await oauth.login({
      signal,
      async prompt(prompt) {
        if (prompt.type !== "select" || !prompt.options.some((option) => option.id === "device_code")) {
          throw new Error("Unsupported Codex login prompt");
        }
        return "device_code";
      },
      notify(event) {
        if (event.type !== "device_code" || event.verificationUri !== "https://auth.openai.com/codex/device"
          || typeof event.userCode !== "string" || !/^[A-Za-z0-9-]{1,64}$/.test(event.userCode)) {
          throw new Error("Unsupported Codex login notification");
        }
        // SDK notifications are synchronous. Abort polling if the private prompt cannot be delivered.
        delivery = options.onPrompt(event).catch(() => { controller.abort(); });
      },
    });
    try { options.onSaving(); } catch { /* Discord UI failure must not lose issued tokens. */ }
    await credentials.modify("openai-codex", async () => credential);
  } catch {
    // Provider errors can contain codes, tokens, or response bodies.
    throw new Error("Codex login failed");
  } finally {
    controller.abort();
    // A late Discord edit must finish before the command clears the private code.
    await delivery.catch(() => {});
  }
}

export async function availableModels(): Promise<ModelOption[]> {
  const options: ModelOption[] = [{ id: local.id, label: local.label }];
  for (const provider of models.getProviders()) {
    let configured = false;
    if (provider.id === "openai-codex") {
      try { configured = (await credentials.read(provider.id))?.type === "oauth"; }
      catch { /* A broken cloud auth file must not hide the local choice or API providers. */ }
    } else configured = !!process.env[envKeys[provider.id] ?? ""]?.trim();
    if (configured) for (const model of models.getModels(provider.id)) {
      if (promptBudget(model.contextWindow) > 0 && model.maxTokens >= MAX_OUTPUT_TOKENS) {
        options.push({ id: `${provider.id}/${model.id}`, label: `${provider.id === "openai-codex" ? "Codex subscription" : provider.name} · ${model.name}` });
      }
    }
  }
  return options;
}

function cloudClient(model: Model<Api>, option: ModelOption): ModelClient {
  const supportsImages = model.input.includes("image");
  const streamChat = async (body: ChatBody, onContent: (delta: string) => void, signal?: AbortSignal, thinking = true): Promise<ChatResult> => {
    throwIfAborted(signal);
    const controller = new AbortController();
    const requestSignal = signal ? AbortSignal.any([signal, controller.signal]) : controller.signal;
    let timer: ReturnType<typeof setTimeout> | undefined;
    let timedOut = false;
    const deadline = () => {
      clearTimeout(timer);
      timer = setTimeout(() => { timedOut = true; controller.abort(); }, IDLE_TIMEOUT_MS);
    };
    deadline();
    try {
      const stream = models.streamSimple(model, sdkContext(body.messages, body.tools, model), {
        signal: requestSignal, maxTokens: Math.min(body.max_tokens, model.maxTokens),
        reasoning: thinking ? "low" : undefined, transport: "sse", timeoutMs: IDLE_TIMEOUT_MS, maxRetries: 0,
      });
      for await (const event of stream) {
        deadline();
        if (event.type === "text_delta") onContent(event.delta);
      }
      const message = await stream.result();
      if (message.stopReason === "error" || message.stopReason === "aborted") {
        if (isContextOverflow(message, model.contextWindow)) throw new ModelError("too_long", "Model prompt is too long");
        throw new ModelError("unavailable", "Selected model unavailable; check provider credentials or subscription");
      }
      return chatResult(message);
    } catch (error) {
      if (signal?.aborted) throw new TurnAborted();
      if (timedOut) throw new ModelError("timeout", "Model response timed out");
      if (error instanceof ModelError) throw error;
      // SDK failures can contain tokens, prompt excerpts, URLs, or provider response bodies.
      throw new ModelError("unavailable", "Selected model unavailable; check provider credentials or subscription");
    } finally { clearTimeout(timer); controller.abort(); }
  };
  return Object.freeze({
    ...option, provider: model.provider, supportsImages,
    async requestModel(signal?: AbortSignal) { throwIfAborted(signal); return { contextSize: effectiveContextSize(model.contextWindow) }; },
    async countTokens(body: Pick<ChatBody, "messages" | "tools">, signal?: AbortSignal) {
      throwIfAborted(signal);
      return estimatedTokens(body.messages, body.tools, supportsImages);
    },
    streamChat,
    async complete(body: ChatBody, signal?: AbortSignal) { return (await streamChat(body, () => {}, signal, false)).content; },
  });
}

export async function selectModel(id: string): Promise<ModelClient> {
  const generation = ++selectionGeneration;
  if (id === "local") { selected = local; return local; }
  const slash = id.indexOf("/");
  if (slash < 1) throw new ModelError("unavailable", "Unknown model selection");
  const model = models.getModel(id.slice(0, slash), id.slice(slash + 1));
  if (!model) throw new ModelError("unavailable", "Unknown model selection");
  const option = (await availableModels()).find((option) => option.id === id);
  if (!option) throw new ModelError("unavailable", "Model provider is not configured");
  try {
    const auth = await models.getAuth(model, { signal: AbortSignal.timeout(30_000) });
    if (!auth) throw new Error("Not configured");
  } catch {
    throw new ModelError("unavailable", "Model authentication failed; check provider credentials or log in again");
  }
  if (generation !== selectionGeneration) throw new ModelError("unavailable", "Model selection superseded by another request");
  selected = cloudClient(model, option);
  return selected;
}

/** Capture once for each background completion, including the local not-loaded retry. */
export async function ask(messages: ChatMessage[], maxTokens: number): Promise<string> {
  const model = currentModel();
  // Emoji descriptions must not invent visual details from a name when vision is unavailable.
  if (!model.supportsImages && hasImages(messages)) throw new ModelError("unavailable", "Selected model cannot see images");
  const session = await modelSession(() => model.requestModel());
  return session.call(() => model.complete({ messages, max_tokens: maxTokens }));
}
