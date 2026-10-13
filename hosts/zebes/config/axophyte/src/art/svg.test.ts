import { describe, expect, test } from "bun:test";
import { EXAMPLE_SVG } from "./artist";
import { checkSvg, extractSvg } from "./svg";

const svg = (body: string) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800">${body}</svg>`;

// Model SVG is shaped by Discord users and resvg reads local files: anything external must be refused.
describe("checkSvg", () => {
  test.each([
    ["local image", svg('<image href="/etc/x.png"/>')],
    ["xlink file URL", svg('<use xlink:href="file:///x"/>')],
    ["remote paint server", svg('<rect fill="url(https://x/y)"/>')],
    ["quoted local paint server", svg("<rect fill=\"url('/x')\"/>")],
    ["entity declaration", `<!DOCTYPE svg [<!ENTITY a "b">]>${svg("")}`],
    ["CSS import", svg('<style>@import "x.css";</style>')],
  ])("refuses %s", (_name, input) => {
    expect(checkSvg(input)).not.toBeNull();
  });

  test("accepts in-file references", () => {
    expect(checkSvg(EXAMPLE_SVG)).toBeNull();
    expect(checkSvg(svg('<defs><g id="leaf"/></defs><use href="#leaf"/><rect fill="url(#sky)"/>'))).toBeNull();
    expect(checkSvg(svg("<rect fill=\"url('#sky')\"/><style>.a{fill:url( \"#sky\")}</style>"))).toBeNull();
  });
});

// The draft reply holds a plan plus code; a wrong pick renders the wrong (or a half-written) drawing.
test("extractSvg takes the last fenced SVG and rejects unfinished ones", () => {
  const text = `PLAN\n1. Scene: a sun\n\`\`\`svg\n${svg("<circle r=\"1\"/>")}\n\`\`\`\nBetter:\n\`\`\`svg\n${svg("<circle r=\"2\"/>")}\n\`\`\``;
  expect(extractSvg(text)).toBe(svg("<circle r=\"2\"/>"));
  expect(extractSvg("```svg\n<svg xmlns=\"http://www.w3.org/2000/svg\"><rect/>")).toBeNull();
});
