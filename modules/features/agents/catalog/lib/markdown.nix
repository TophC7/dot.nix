# Prompt files: `+++` TOML frontmatter, one blank line, then the prompt text.
# TOML because Nix parses it natively; YAML would need a build-time parser.
{ lib }:
rec {
  read =
    path:
    let
      text = builtins.readFile path;
      parts = lib.splitString "\n+++\n\n" (lib.removePrefix "+++\n" text);
    in
    if !(lib.hasPrefix "+++\n" text) || builtins.length parts < 2 then
      throw "${toString path}: expected +++ TOML frontmatter followed by a blank line"
    else
      builtins.fromTOML (builtins.head parts)
      // {
        body = lib.concatStringsSep "\n+++\n\n" (builtins.tail parts);
      };

  # Attrset keyed by file stem. `name` defaults to the stem; frontmatter may
  # override it with a display name (macros), so `id` keeps the stem.
  readDir =
    dir:
    lib.mapAttrs'
      (
        file: _:
        let
          id = lib.removeSuffix ".md" file;
        in
        lib.nameValuePair id (
          {
            inherit id;
            name = id;
          }
          // read (dir + "/${file}")
        )
      )
      (
        lib.filterAttrs (file: type: type == "regular" && lib.hasSuffix ".md" file) (builtins.readDir dir)
      );
}
