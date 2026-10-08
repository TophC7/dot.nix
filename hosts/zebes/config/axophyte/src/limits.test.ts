import { expect, test } from "bun:test";
import { effectiveContextSize, limits, promptBudget } from "./limits";

test("runtime context reserves answer output and headroom, not training capacity", () => {
  expect(promptBudget(effectiveContextSize(131072))).toBe(121856);
  expect(promptBudget(effectiveContextSize(65536))).toBe(56320);
  expect(promptBudget(65536, limits.summaryMaxTokens)).toBe(58368);
  expect(promptBudget(9217)).toBe(1);
});

test("missing, invalid, or insufficient runtime context fails closed", () => {
  for (const value of [undefined, null, "131072", 0, -1, NaN, Infinity, 131072.5, Number.MAX_SAFE_INTEGER + 1, 9216, 8192]) {
    expect(() => effectiveContextSize(value)).toThrow();
  }
});
