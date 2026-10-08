export { limits, THINKING_CONTROL_MODELS } from "./limits";

function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`missing env ${name}`);
  return value;
}

export const config = {
  discordToken: required("AXOPHYTE_DISCORD_TOKEN"),
  tavilyKey: required("AXOPHYTE_TAVILY_KEY"),
  guildId: required("AXOPHYTE_GUILD_ID"),
  forumId: required("AXOPHYTE_FORUM_ID"),
  llamaUrl: required("AXOPHYTE_LLAMA_URL").replace(/\/+$/, ""),
  defaultModel: required("AXOPHYTE_DEFAULT_MODEL"),
  dbPath: process.env.STATE_DIRECTORY
    ? `${process.env.STATE_DIRECTORY}/axophyte.sqlite`
    : "./axophyte.sqlite",
};
