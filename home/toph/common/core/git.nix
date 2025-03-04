# git is core no matter what but additional settings may could be added made in optional/foo   eg: development.nix
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;

    userName = "[REDACTED]";
    userEmail = "[REDACTED]";

    ignores = [
      ".csvignore"
      # nix
      "*.drv"
      "result"
      # python
      "*.py?"
      "__pycache__/"
      ".venv/"
      # direnv
      ".direnv"
    ];

    # Anytime I use auth, I want to use my yubikey. But I don't want to always be having to touch it
    # for things that don't need it. So I have to hardcode repos that require auth, and default to ssh for
    # actions that require auth.
    extraConfig = {
      core.pager = "delta";
      delta = {
        enable = true;
        features = [
          "side-by-side"
          "line-numbers"
          "hyperlinks"
          "line-numbers"
          "commit-decoration"
        ];
      };

      url = lib.optionalAttrs (!config.hostSpec.isMinimal) {
        # Only force ssh if it's not minimal
        "ssh://git@github.com" = {
          pushInsteadOf = "https://github.com";
        };
        "ssh://git@ryot.foo.com" = {
          pushInsteadOf = "https://git.ryot.foo";
        };
      };

      # pre-emptively ignore mac crap
      core.excludeFiles = builtins.toFile "global-gitignore" ''
        .DS_Store
        .DS_Store?
        ._*
        .Spotlight-V100
        .Trashes
        ehthumbs.db
        Thumbs.db
        node_modules
      '';
      core.attributesfile = builtins.toFile "global-gitattributes" ''
        Cargo.lock -diff
        flake.lock -diff
        *.drawio -diff
        *.svg -diff
        *.json diff=json
        *.bin diff=hex difftool=hex
        *.dat diff=hex difftool=hex
        *aarch64.bin diff=objdump-aarch64 difftool=objdump-aarch64
        *arm.bin diff=objdump-arm difftool=objdump-arm
        *x64.bin diff=objdump-x86_64 difftool=objdump-x64
        *x86.bin diff=objdump-x86 difftool=objdump-x86
      '';

      extraConfig = {
        init = {
          defaultBranch = "main";
        };
      };
    };
  };

}
