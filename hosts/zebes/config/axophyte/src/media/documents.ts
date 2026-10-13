import { PROCESS_TIMEOUT_MS, runText } from "./exec";
import { documentExtensions } from "./media";

const PDF_PAGES = 30;
export const DOCUMENT_CHARS = 8000;

export function sniffText(bytes: Uint8Array): string | null {
  try {
    const text = new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }).decode(bytes);
    return text.includes("\u0000") ? null : text;
  } catch {
    return null;
  }
}

export async function documentText(input: string, kind: "pdf" | "document", ext: string): Promise<string | null> {
  // ponytail: pptx/xlsx need pandoc >= 3.8.3; nixpkgs has 3.7.
  if (kind === "document" && !documentExtensions.includes(ext)) return null;
  return runText(kind === "pdf"
    ? ["pdftotext", "-q", "-enc", "UTF-8", "-l", String(PDF_PAGES), input, "-"]
    : ["pandoc", "--sandbox", "-f", ext, "-t", "plain", "--wrap=none", input],
  PROCESS_TIMEOUT_MS, DOCUMENT_CHARS);
}
