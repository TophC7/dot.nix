import { clip } from "../text";
import { defineTool, stringArg, toolError } from "./tool";
import type { Tool } from "./tool";

const SEARCH_RESULT_COUNT = 5;
const MAX_QUERY_CHARS = 400;
const MAX_PAGE_CHARS = 12_000;

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

export function webSearchTool(key: string): Tool {
  return defineTool({
    name: "web_search",
    budget: 3,
    description: "Search the web when someone asks you to look something up, for anything recent or current (news, releases, prices, versions), and to verify real-world facts, works, tracklists, chronologies, specs, trivia, or claims.",
    properties: { query: { type: "string" } },
    required: ["query"],
    status: (args) => `🔎 searching “${stringArg(args, "query", 100) ?? ""}”…`,
    async run(args, signal) {
      const query = stringArg(args, "query", MAX_QUERY_CHARS);
      if (!query) return toolError("invalid arguments");
      const data = await tavily<{ results?: TavilyResult[] }>("search", {
        query,
        search_depth: "basic",
        auto_parameters: false,
        max_results: SEARCH_RESULT_COUNT,
        include_answer: false,
        include_raw_content: false,
      }, key, 15_000, signal);
      // Servers can ignore max_results.
      const hits = (data.results ?? []).slice(0, SEARCH_RESULT_COUNT);
      return {
        content: hits.length
          ? hits.map((hit, index) => `[${index + 1}] ${hit.title}\n${hit.url}\n${(hit.content ?? "").slice(0, 600)}`).join("\n\n")
          : "No results.",
        footer: `-# 🔎 Searched “${query}”${hits.length ? ` · ${hits.slice(0, 3).map((hit) => `<${hit.url}>`).join(" · ")}` : " · no results"}`,
      };
    },
  });
}

export function openUrlTool(key: string): Tool {
  return defineTool({
    name: "open_url",
    budget: 3,
    description: "Read a web page. Optional focus: a question; returns only the relevant parts.",
    properties: {
      url: { type: "string" },
      focus: { type: "string" },
    },
    required: ["url"],
    status: (args) => `🔗 reading <${stringArg(args, "url", 300) ?? ""}>…`,
    async run(args, signal) {
      const raw = stringArg(args, "url", 2049);
      const url = URL.parse(raw ?? "");
      if (!url || (url.protocol !== "http:" && url.protocol !== "https:") || url.href.length > 2048) return toolError("invalid url");
      const focus = stringArg(args, "focus", MAX_QUERY_CHARS);
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
      return { content: clip(page, MAX_PAGE_CHARS), footer: `-# 🔗 Opened <${url.href}>` };
    },
  });
}
