function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`missing env ${name}`);
  return value;
}

/** Guild ID → Axophyte's forum there, or null when it only answers mentions and replies. */
function servers(json: string): Map<string, string | null> {
  const parsed: unknown = JSON.parse(json);
  const entries = parsed && typeof parsed === "object" && !Array.isArray(parsed) ? Object.entries(parsed) : [];
  if (!entries.length || entries.some(([, forum]) => forum !== null && typeof forum !== "string")) {
    throw new Error("AXOPHYTE_SERVERS must map guild IDs to forum IDs or null");
  }
  return new Map(entries);
}

export const config = {
  discordToken: required("AXOPHYTE_DISCORD_TOKEN"),
  tavilyKey: required("AXOPHYTE_TAVILY_KEY"),
  servers: servers(required("AXOPHYTE_SERVERS")),
  llamaUrl: required("AXOPHYTE_LLAMA_URL").replace(/\/+$/, ""),
  defaultModel: required("AXOPHYTE_DEFAULT_MODEL"),
  dbPath: process.env.STATE_DIRECTORY
    ? `${process.env.STATE_DIRECTORY}/axophyte.sqlite`
    : "./axophyte.sqlite",
};
