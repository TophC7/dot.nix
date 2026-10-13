import { expect, test } from "bun:test";

const defaults: Record<string, string> = {
  AXOPHYTE_DISCORD_TOKEN: "test", AXOPHYTE_TAVILY_KEY: "test", AXOPHYTE_SERVERS: '{"test":null}',
  AXOPHYTE_LLAMA_URL: "http://localhost:1", AXOPHYTE_MODEL: "test-local",
  AXOPHYTE_WHISPER_MODEL: "/test/whisper", AXOPHYTE_SVG_FONTS: "/test/fonts",
};
const added: string[] = [];
for (const [key, value] of Object.entries(defaults)) {
  if (process.env[key] === undefined) { process.env[key] = value; added.push(key); }
}
// Deliberately exercise the loading boundary: runtime config must exist before this import.
const { availableModels, currentModel, selectModel } = await import("./client");
for (const key of added) delete process.env[key];

test("startup/local selection stays offline; invalid selection preserves the snapshot", async () => {
  expect(currentModel().id).toBe("local");
  const local = await selectModel("local");
  expect((await availableModels()).some((option) => option.id === "local")).toBe(true);
  await expect(selectModel("not-a-provider/not-a-model")).rejects.toThrow("Unknown model");
  expect(currentModel()).toBe(local);
});

test("an older asynchronous cloud selection cannot overwrite a newer local intent", async () => {
  const previous = process.env.ANTHROPIC_API_KEY;
  process.env.ANTHROPIC_API_KEY = "test-key-for-auth-presence-only";
  try {
    // API-key resolution only checks configuration; neither selection makes a provider request.
    const older = selectModel("anthropic/claude-haiku-5-5");
    const local = await selectModel("local");
    await expect(older).rejects.toThrow("superseded");
    expect(currentModel()).toBe(local);
    const cloud = await selectModel("anthropic/claude-haiku-5-5");
    expect(cloud.provider).toBe("anthropic");
    await selectModel("local");
    expect(currentModel().id).toBe("local");
  } finally {
    if (previous === undefined) delete process.env.ANTHROPIC_API_KEY;
    else process.env.ANTHROPIC_API_KEY = previous;
    await selectModel("local");
  }
});
