# Links every catalog skill into one harness's skill root, e.g. `.codex/skills`.
lib: root:
lib.mapAttrs' (name: _: {
  name = "${root}/${name}";
  value.source = ./_catalog/skills + "/${name}";
}) (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./_catalog/skills))
