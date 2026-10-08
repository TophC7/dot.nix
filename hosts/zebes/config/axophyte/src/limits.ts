export const limits = {
  maxOutputTokens: 8192,
  summaryMaxTokens: 6144,
  contextHeadroomTokens: 1024,
  maxSummaryChars: 8000,
  maxImagesPerRequest: 4,
  maxImageBytes: 10 * 1024 * 1024,
  imageMaxSide: 1536,
  maxSearchesPerTurn: 3,
  searchResultCount: 5,
  maxQueryChars: 400,
  editIntervalMs: 1200,
  splitAt: 1900,
  typingIntervalMs: 8000,
  queueNoticeMs: 60_000,
  llmIdleTimeoutMs: 600_000,
  maxHistoryMessages: 300,
} as const;

export const THINKING_CONTROL_MODELS: Record<string, true> = {
  "qwen3.8-27b": true,
};

export function promptBudget(contextSize: number, outputTokens: number = limits.maxOutputTokens): number {
  if (!Number.isSafeInteger(contextSize) || contextSize <= limits.maxOutputTokens + limits.contextHeadroomTokens) {
    throw new RangeError("model server returned an invalid or insufficient runtime context");
  }
  return contextSize - outputTokens - limits.contextHeadroomTokens;
}

export function effectiveContextSize(value: unknown): number {
  if (typeof value !== "number") throw new RangeError("model server returned no runtime context");
  promptBudget(value);
  return value;
}
