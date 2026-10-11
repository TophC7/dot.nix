# Helpers adapters use to turn catalog prompts into harness-native files.
{ lib }:
let
  # JSON is a subset of YAML, so toJSON quotes and escapes scalars and also emits
  # valid flow sequences for list-valued fields such as an agent's `tools`. The
  # Codex adapter uses it for TOML strings, where the same escaping holds.
  scalar = builtins.toJSON;
in
{
  # Frontmatter only parses when the opening delimiter sits on line 1.
  withFrontmatter =
    fields: body:
    "---\n"
    + lib.concatLines (lib.mapAttrsToList (key: value: "${key}: ${scalar value}") fields)
    + "---\n\n"
    + lib.removeSuffix "\n" body
    + "\n";

  render =
    vars: label: body:
    let
      rendered = builtins.replaceStrings (builtins.attrNames vars) (builtins.attrValues vars) body;
    in
    if lib.hasInfix "{{" rendered then
      throw "catalog: unresolved placeholder in ${label}"
    else
      rendered;

  schemaContract = schema: ''
    Finish with exactly one fenced `json` block holding a single object that matches this JSON Type Definition schema (`properties` are required, `optionalProperties` may be omitted, `elements` is an array of the given shape, `enum` lists the allowed strings). Put nothing after it.

    ```json
    ${builtins.toJSON schema}
    ```
  '';

  mapTools =
    harness: table: caps:
    lib.concatMap (
      cap:
      if builtins.hasAttr cap table then
        table.${cap}
      else
        throw "${harness}: unmapped tool capability ${cap}"
    ) caps;
}
