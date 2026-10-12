function truncated(text: string, max: number): string {
  let end = max;
  // Keep the cutoff in UTF-16 units, but never leave half an astral character.
  if (end > 0 && /[\uD800-\uDBFF]/.test(text[end - 1]!) && /[\uDC00-\uDFFF]/.test(text[end] ?? "")) end--;
  return `${text.slice(0, end)}\n[truncated]`;
}

export function clip(text: string, max: number): string {
  const trimmed = text.trim();
  return trimmed.length > max ? truncated(trimmed, max) : trimmed;
}

export async function clippedText(stream: ReadableStream<Uint8Array>, max: number): Promise<string> {
  const reader = stream.getReader();
  const decoder = new TextDecoder();
  let prefix = "";
  let length = 0;
  let lastNonWhitespace = 0;
  const consume = (chunk: string) => {
    if (length === 0) chunk = chunk.trimStart();
    if (!chunk) return;
    // Retain only the cutoff and one code unit of surrogate-pair lookahead.
    if (prefix.length < max + 1) prefix += chunk.slice(0, max + 1 - prefix.length);
    const end = chunk.trimEnd().length;
    if (end > 0) lastNonWhitespace = length + end;
    length += chunk.length;
  };
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      consume(decoder.decode(value, { stream: true }));
    }
    consume(decoder.decode());
    return lastNonWhitespace > max ? truncated(prefix, max) : prefix.slice(0, lastNonWhitespace);
  } finally {
    reader.releaseLock();
  }
}
