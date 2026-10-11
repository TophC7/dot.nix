// Hands the catalog macros to the web client face (lib/client.js).
export function apply(ctx, config) {
  ctx.on("webserver/index-inject", (tags) => tags.push({
    kind: "global",
    name: "__TOPH_WORKFLOW_MACROS__",
    value: config.macros,
  }));
}
