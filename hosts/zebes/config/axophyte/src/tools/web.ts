import { limits } from "../limits";
import { defineTool, stringArg, toolError } from "./tool";
import type { Tool } from "./tool";

type SearchHit = { title: string; url: string; snippet: string };
type TavilyResult = { title: string; url: string; content?: string };
type ExtractResponse = {
  results?: { url: string; raw_content?: string }[];
  failed_results?: { url: string; error?: string }[];
};

// Only Tavily fetches pages; the bot never connects to model-chosen URLs.
async function tavily<T>(
  path: "search" | "extract",
  body: Record<string, unknown>,
  key: string,
  timeoutMs: number,
  signal: AbortSignal | undefined,
): Promise<T> {
  const timeout = AbortSignal.timeout(timeoutMs);
  const response = await fetch(`https://api.tavily.com/${path}`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${key}`,
    },
    body: JSON.stringify(body),
    redirect: "error",
    signal: signal ? AbortSignal.any([signal, timeout]) : timeout,
  });
  if (!response.ok) throw new Error(`${path} failed (HTTP ${response.status})`);
  return (await response.json()) as T;
}

export async function tavilySearch(query: string, key: string, signal?: AbortSignal): Promise<SearchHit[]> {
  const data = await tavily<{ results?: TavilyResult[] }>("search", {
    query: query.slice(0, limits.maxQueryChars),
    search_depth: "basic",
    auto_parameters: false,
    max_results: limits.searchResultCount,
    include_answer: false,
    include_raw_content: false,
  }, key, 15_000, signal);
  return (data.results ?? []).slice(0, limits.searchResultCount).map((hit) => ({
    title: hit.title,
    url: hit.url,
    snippet: (hit.content ?? "").slice(0, 600),
  }));
}

function formatHits(query: string, hits: SearchHit[]): string {
  if (!hits.length) return "No results.";
  return `Results for "${query}":\n${hits
    .map((hit, index) => `[${index + 1}] ${hit.title}\n${hit.url}\n${hit.snippet}`)
    .join("\n\n")}`;
}

export function webSearchTool(key: string): Tool {
  return defineTool({
    name: "web_search",
    description: "Search the web for current or factual information. Returns titles, URLs and snippets.",
    properties: { query: { type: "string", description: "Search query" } },
    required: ["query"],
    async run(args, signal) {
      const query = stringArg(args, "query", limits.maxQueryChars);
      if (!query) return toolError("invalid arguments");
      const hits = await tavilySearch(query, key, signal);
      return {
        content: formatHits(query, hits),
        footer: `-# 🔎 Searched “${query}”${hits.length ? ` — ${hits.slice(0, 3).map((hit) => `<${hit.url}>`).join(" · ")}` : " — no results"}`,
      };
    },
  });
}

export function openUrlTool(key: string): Tool {
  return defineTool({
    name: "open_url",
    description: "Read a specific web page. Optional focus returns only the parts relevant to that question.",
    properties: {
      url: { type: "string", description: "http(s) URL of the page" },
      focus: { type: "string", description: "Optional question to focus the extracted content on" },
    },
    required: ["url"],
    async run(args, signal) {
      const raw = stringArg(args, "url", 2049);
      const url = URL.parse(raw ?? "");
      if (!url || (url.protocol !== "http:" && url.protocol !== "https:") || url.href.length > 2048) return toolError("invalid url");
      const focus = stringArg(args, "focus", limits.maxQueryChars);
      const data = await tavily<ExtractResponse>("extract", {
        urls: [url.href],
        extract_depth: "basic",
        format: "markdown",
        timeout: 20,
        ...(focus ? { query: focus, chunks_per_source: 5 } : {}),
      }, key, 30_000, signal);
      const failed = data.failed_results?.[0];
      const page = data.results?.[0]?.raw_content;
      if (failed || page === undefined) return toolError(`could not open ${url.href}: ${failed?.error ?? "no content"}`);
      const text = page.length > limits.maxPageChars ? `${page.slice(0, limits.maxPageChars)}\n[truncated]` : page;
      return { content: `Page: ${url.href}\n\n${text}`, footer: `-# 🔗 Opened <${url.href}>` };
    },
  });
}
