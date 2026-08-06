{
  inputs,
  host,
  lib,
  pkgs,
  ...
}:
let
  codexCli = inputs.llm-agents.packages.${host.system}.codex;
  skillDirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./_catalog/skills);

  skillLinks = lib.mapAttrs' (name: _: {
    name = ".codex/skills/${name}";
    value = {
      source = ./_catalog/skills + "/${name}";
    };
  }) skillDirs;

in
{
  imports = [ inputs.codex-desktop-linux.homeManagerModules.default ];

  home.packages = [ codexCli ];

  programs.codexDesktopLinux = lib.mkIf (!(host.isServer or false)) {
    enable = true;
    cliPackage = codexCli;
  };

  home.file = {
    ".codex/AGENTS.md".source = ./AGENTS.md;
  }
  // skillLinks;
}
