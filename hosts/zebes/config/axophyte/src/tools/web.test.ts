import { afterEach, describe, expect, mock, spyOn, test } from "bun:test";
import { webSearchTool } from "./web";

afterEach(() => mock.restore());

const search = (query: string) => webSearchTool("test-key").run({ query }, new AbortController().signal);

describe("Tavily search", () => {
  test("pins basic one-credit search, disables upgrades and bounds results and snippets", async () => {
    const results = [
      { title: "First", url: "https://example.com/first", content: "Description" },
      { title: "Second", url: "https://example.com/second", content: "x".repeat(700) },
      ...Array.from({ length: 5 }, (_, i) => ({
        title: `Extra ${i}`, url: `https://example.com/${i}`, content: "Extra snippet",
      })),
    ];
    // Bun's fetch type includes preconnect; retain it on the spy implementation.
    spyOn(globalThis, "fetch").mockImplementation(Object.assign(async (...[input, init]: Parameters<typeof fetch>) => {
      expect(String(input)).toBe("https://api.tavily.com/search");
      expect(init?.method).toBe("POST");
      expect(JSON.parse(String(init?.body))).toEqual({
        query: "q".repeat(400),
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
    expect((await search("q".repeat(500))).content).toBe(
      results.slice(0, 5).map(({ title, url, content }, i) => `[${i + 1}] ${title}\n${url}\n${content.slice(0, 600)}`).join("\n\n"),
    );
  });

  test("rate and key-plan limits expose only status, never consume error bodies", async () => {
    for (const status of [429, 432]) {
      const response = new Response("private upstream details: test-key", { status });
      spyOn(globalThis, "fetch").mockImplementation(Object.assign(async () => response, { preconnect: fetch.preconnect }));
      await expect(search("query")).rejects.toMatchObject({ message: `search failed (HTTP ${status})` });
      expect(response.bodyUsed).toBe(false);
    }
  });
});
