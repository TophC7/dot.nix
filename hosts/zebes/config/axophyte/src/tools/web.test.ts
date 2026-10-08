import { afterEach, describe, expect, mock, spyOn, test } from "bun:test";
import { limits } from "../limits";
import { tavilySearch } from "./web";

afterEach(() => mock.restore());

describe("Tavily adapter", () => {
  test("pins basic one-credit search, disables upgrades and bounds results and snippets", async () => {
    const results = [
      { title: "First", url: "https://example.com/first", content: "Description" },
      { title: "Second", url: "https://example.com/second", content: "x".repeat(700) },
      ...Array.from({ length: limits.searchResultCount }, (_, i) => ({
        title: `Extra ${i}`, url: `https://example.com/${i}`, content: "Extra snippet",
      })),
    ];
    // Bun's fetch type includes preconnect; retain it on the spy implementation.
    spyOn(globalThis, "fetch").mockImplementation(Object.assign(async (...[input, init]: Parameters<typeof fetch>) => {
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
      expect(headers.get("Authorization")).toBe("Bearer test-key");
      expect(init?.redirect).toBe("error");
      expect(init?.signal).toBeInstanceOf(AbortSignal);
      return Response.json({ results });
    }, { preconnect: fetch.preconnect }));
    expect(await tavilySearch("q".repeat(500), "test-key")).toEqual(
      results.slice(0, 5).map(({ title, url, content }) => ({ title, url, snippet: content.slice(0, 600) })),
    );
  });

  test("rate and key-plan limits expose only status, never consume error bodies", async () => {
    for (const status of [429, 432]) {
      const response = new Response("private upstream details: test-key", { status });
      spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => response, { preconnect: fetch.preconnect }));
      await expect(tavilySearch("query", "test-key"))
        .rejects.toMatchObject({ message: `search failed (HTTP ${status})` });
      expect(response.bodyUsed).toBe(false);
    }
  });
});
