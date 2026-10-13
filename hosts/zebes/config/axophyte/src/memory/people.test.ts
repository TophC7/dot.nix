import { expect, test } from "bun:test";
import { parsePruned } from "./people";

test("pruned notes must shrink, fit, and not be empty", () => {
  expect(parsePruned("- he/him\n* [#4] lives in Lisbon\n\n[#7] likes Rust", 100)).toEqual(["he/him", "lives in Lisbon", "likes Rust"]);
  expect(parsePruned("\n  \n- ", 100)).toBeNull();
  expect(parsePruned("a much longer rewrite than before", 10)).toBeNull();
  expect(parsePruned(Array.from({ length: 8 }, () => "x".repeat(300)).join("\n"), 5000)).toBeNull();
});
