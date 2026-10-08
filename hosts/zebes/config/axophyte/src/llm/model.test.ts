import { expect, test } from "bun:test";
import { limits } from "../limits";
import { effectiveContextSize, ModelError, modelSession, promptBudget, type ModelChoice } from "./model";

const small: ModelChoice = { id: "small", contextSize: 65536 };

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

test("selection races use the same sole not-loaded retry", async () => {
  let picks = 0;
  const session = await modelSession(async () => {
    if (++picks === 1) throw new ModelError("not_loaded", "unloaded before props");
    return small;
  });
  expect(session.choice).toEqual(small);
  await expect(session.call(async () => { throw new ModelError("not_loaded", "unloaded again"); })).rejects.toBeInstanceOf(ModelError);
  expect(picks).toBe(2);
});

