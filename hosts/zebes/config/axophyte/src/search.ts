import { limits } from "./limits";
import type { ToolCall } from "./memory";

export const WEB_SEARCH_TOOL = {
  type: "function",
  function: {
    name: "web_search",
    description: "Search the web for current or factual information. Returns titles, URLs and snippets.",
    parameters: {
      type: "object",
      properties: { query: { type: "string", description: "Search query" } },
      required: ["query"],
    },
  },
} as const;

export type SearchHit = { title: string; url: string; snippet: string };

type TavilyResult = {
  title: string;
  url: string;
  content?: string;
};

export async function tavilySearch(
  query: string,
  key: string,
  fetchFn: (input: Parameters<typeof fetch>[0], init?: Parameters<typeof fetch>[1]) => Promise<Response> = fetch,
): Promise<SearchHit[]> {
  const response = await fetchFn("https://api.tavily.com/search", {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${key}`,
    },
    body: JSON.stringify({
      query: query.slice(0, limits.maxQueryChars),
      search_depth: "basic",
      auto_parameters: false,
      max_results: limits.searchResultCount,
      include_answer: false,
      include_raw_content: false,
    }),
    redirect: "error",
    signal: AbortSignal.timeout(15_000),
  });
  if (!response.ok) throw new Error(`search failed (HTTP ${response.status})`);
  const data = (await response.json()) as { results?: TavilyResult[] };
  return (data.results ?? []).slice(0, limits.searchResultCount).map((hit) => ({
    title: hit.title,
    url: hit.url,
    snippet: (hit.content ?? "").slice(0, 600),
  }));
}

export function formatHits(query: string, hits: SearchHit[]): string {
  if (!hits.length) return "No results.";
  return `Results for "${query}":\n${hits
    .map((hit, index) => `[${index + 1}] ${hit.title}\n${hit.url}\n${hit.snippet}`)
    .join("\n\n")}`;
}

export async function runToolCall(
  call: ToolCall,
  search: (q: string) => Promise<SearchHit[]>,
): Promise<{ content: string; query: string | null; hits: SearchHit[] }> {
  if (call.function.name !== "web_search") {
    return {
      content: JSON.stringify({ error: `unknown tool ${call.function.name}` }),
      query: null,
      hits: [],
    };
  }
  let query: string;
  try {
    const args: unknown = JSON.parse(call.function.arguments);
    if (
      typeof args !== "object" ||
      args === null ||
      !("query" in args) ||
      typeof args.query !== "string" ||
      !args.query.trim()
    ) {
      throw new Error("invalid arguments");
    }
    query = args.query.trim().slice(0, limits.maxQueryChars);
  } catch {
    return { content: '{"error":"invalid arguments"}', query: null, hits: [] };
  }
  try {
    const hits = await search(query);
    return { content: formatHits(query, hits), query, hits };
  } catch (error) {
    return {
      content: JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      query,
      hits: [],
    };
  }
}
