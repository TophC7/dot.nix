import { describe, expect, test } from "bun:test";
import { limits } from "./limits";
import type { ToolCall } from "./memory";
import { tavilySearch, formatHits, runToolCall, type SearchHit } from "./search";

function call(name: string, args: string): ToolCall {
  return { id: "call-1", type: "function", function: { name, arguments: args } };
}

const hits: SearchHit[] = [
  { title: "First", url: "https://example.com/first", snippet: "First snippet" },
  { title: "Second", url: "https://example.com/second", snippet: "Second snippet" },
];

describe("web search tool boundary", () => {
  test("unknown tools and malformed arguments never invoke search", async () => {
    let searches = 0;
    const search = async () => { searches++; return hits; };
    const unknown = await runToolCall(call("read_file", '{"query":"test"}'), search);
    expect(unknown).toEqual({ content: '{"error":"unknown tool read_file"}', query: null, hits: [] });
    for (const args of ["not JSON", "null", "[]", "{}", '{"query":123}', '{"query":""}', '{"query":"   "}']) {
      expect(await runToolCall(call("web_search", args), search)).toEqual({
        content: '{"error":"invalid arguments"}', query: null, hits: [],
      });
    }
    expect(searches).toBe(0);
  });

  test("search failures become error content with query retained", async () => {
    const result = await runToolCall(call("web_search", '{"query":"kernel release"}'), async () => {
      throw new Error("search failed (HTTP 429)");
    });
    expect(result).toEqual({
      content: '{"error":"search failed (HTTP 429)"}', query: "kernel release", hits: [],
    });
  });

  test("valid searches return formatted hits and enforce query cap", async () => {
    const query = "q".repeat(limits.maxQueryChars + 20);
    const result = await runToolCall(call("web_search", JSON.stringify({ query })), async (q) => {
      expect(q).toBe(query.slice(0, limits.maxQueryChars));
      return hits;
    });
    expect(result.query).toBe(query.slice(0, limits.maxQueryChars));
    expect(result.hits).toEqual(hits);
    expect(result.content).toBe(formatHits(result.query!, hits));
  });

  test("formatted results expose each title, URL and snippet; empty results explicit", () => {
    const text = formatHits("a query", hits);
    expect(text.startsWith('Results for "a query":')).toBe(true);
    for (const [index, hit] of hits.entries()) {
      expect(text).toContain(`[${index + 1}] ${hit.title}\n${hit.url}\n${hit.snippet}`);
    }
    expect(formatHits("nothing", [])).toBe("No results.");
  });
});

describe("Tavily adapter", () => {
  test("pins basic one-credit search, disables upgrades and bounds results and snippets", async () => {
    const results = [
      { title: "First", url: hits[0]!.url, content: "Description" },
      { title: "Second", url: hits[1]!.url, content: "x".repeat(700) },
      ...Array.from({ length: limits.searchResultCount }, (_, i) => ({
        title: `Extra ${i}`, url: `https://example.com/${i}`, content: "Extra snippet",
      })),
    ];
    const fetchFn = async (input: Parameters<typeof fetch>[0], init?: Parameters<typeof fetch>[1]) => {
      expect(String(input)).toBe("https://api.tavily.com/search");
      expect(init?.method).toBe("POST");
      expect(JSON.parse(String(init?.body))).toEqual({
        query: "q".repeat(limits.maxQueryChars),
        search_depth: "basic",
        auto_parameters: false,
        max_results: 5,
        include_answer: false,
        include_raw_content: false,
      });
      const headers = new Headers(init?.headers);
      expect(headers.get("Accept")).toBe("application/json");
      expect(headers.get("Content-Type")).toBe("application/json");
      expect(headers.get("Authorization")).toBe("Bearer test-key");
      expect(init?.redirect).toBe("error");
      expect(init?.signal).toBeInstanceOf(AbortSignal);
      return Response.json({ results });
    };
    expect(await tavilySearch("q".repeat(500), "test-key", fetchFn)).toEqual(
      results.slice(0, 5).map(({ title, url, content }) => ({ title, url, snippet: content.slice(0, 600) })),
    );
  });

  test("missing results are empty", async () => {
    expect(await tavilySearch("query", "test-key", async () => Response.json({}))).toEqual([]);
  });

  test("rate and key-plan limits expose only status, never consume error bodies", async () => {
    for (const status of [429, 432]) {
      const response = new Response("private upstream details: test-key", { status });
      await expect(tavilySearch("query", "test-key", async () => response))
        .rejects.toMatchObject({ message: `search failed (HTTP ${status})` });
      expect(response.bodyUsed).toBe(false);
    }
  });
});
