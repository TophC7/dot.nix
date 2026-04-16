#
# Claude Code configuration module orchestrator.
# Auto-discovers sibling modules via lib.fs.scanPaths.
#
{
  pkgs,
  lib,
  inputs,
  host,
  ...
}:
{
  imports = lib.fs.scanPaths ./.;

  # Install claude-code package
  home.packages =
    let
      system = host.system;
      # CLAUDE: Temporary pin to v2.1.111 until numtide/llm-agents.nix bumps upstream.
      # Remove this override once the flake input catches up.
      claude-code-version = "2.1.111";
      claude-code-hashes = {
        x86_64-linux = "sha256-XU35cAQLD4OqxDSuVAtAkSakd4o3noybTHk1YOO/oGA=";
        aarch64-linux = "sha256-mTdoZr9+w2cULTvlSMFxhKefMKlzGEQe6aAPeOUSRuc=";
      };
      claude-code-platform =
        {
          x86_64-linux = "linux-x64";
          aarch64-linux = "linux-arm64";
        }
        .${system};
      claude-code = inputs.llm-agents.packages.${system}.claude-code.overrideAttrs (_: {
        version = claude-code-version;
        src = pkgs.fetchurl {
          url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${claude-code-version}/${claude-code-platform}/claude";
          hash = claude-code-hashes.${system};
        };
      });
      yume = pkgs.yume.override {
        claude = claude-code;
      };
    in
    [
      claude-code
      yume
      inputs.mix-nix.packages.${system}.catnip-desktop
      inputs.llm-agents.packages.${system}.copilot-cli
      inputs.llm-agents.packages.${system}.gemini-cli
      inputs.llm-agents.packages.${system}.codex
      pkgs.crush
      pkgs.t3code
      pkgs.t3code-desktop

    ];
}
