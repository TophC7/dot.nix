import { expect, test } from "bun:test";
import { clip, clippedText } from "./text";

test("clipping preserves whole astral characters at the UTF-16 cutoff", () => {
  expect(clip("  a😀b  ", 2)).toBe("a\n[truncated]");
  expect(clip("a😀b", 3)).toBe("a😀\n[truncated]");
  expect(clip(" 😀 ", 2)).toBe("😀");
});

test("stream clipping matches full UTF-8 decoding across fragmentation and trailing whitespace", async () => {
  const encoder = new TextEncoder();
  const cases = [
    "", " \t\r\n\u00a0 ", "\ufeff  α😀b \n", "a   ", "a   b", "a😀b",
    ` \t${" ".repeat(32)}é😀\n${" ".repeat(80)}`,
    `ab${" \t".repeat(40)}z  `,
  ];
  const inputs = [...cases.map((text) => encoder.encode(text)), new Uint8Array([32, 0xe2, 0x82])];
  for (const bytes of inputs) {
    for (const width of [1, 2, 5, bytes.length || 1]) {
      for (const max of [0, 1, 2, 3, 5, 100]) {
        let offset = 0;
        const stream = new ReadableStream<Uint8Array>({
          pull(controller) {
            if (offset === bytes.length) return controller.close();
            controller.enqueue(bytes.subarray(offset, offset + width));
            offset = Math.min(offset + width, bytes.length);
          },
        });
        expect(await clippedText(stream, max)).toBe(clip(new TextDecoder().decode(bytes), max));
      }
    }
  }
});

test("stream clipping drains beyond its retained prefix without treating trailing spaces as truncation", async () => {
  for (const suffix of ["", "z"]) {
    let pulled = 0;
    const stream = new ReadableStream<Uint8Array>({
      pull(controller) {
        if (pulled++ === 0) controller.enqueue(new TextEncoder().encode("  abc"));
        else if (pulled <= 128) controller.enqueue(new Uint8Array(4096).fill(32));
        else if (pulled === 129 && suffix) controller.enqueue(new TextEncoder().encode(suffix));
        else controller.close();
      },
    });
    expect(await clippedText(stream, 3)).toBe(suffix ? "abc\n[truncated]" : "abc");
    expect(pulled).toBeGreaterThan(128);
  }
});
