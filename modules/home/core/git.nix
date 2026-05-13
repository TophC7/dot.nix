# git is core no matter what but additional settings may could be added made in optional/foo   eg: development.nix
{
  pkgs,
  lib,
  host,
  secrets ? { },
  ...
}:
let
  user = host.user;
  userSecrets = secrets.users.${user.name} or { };
in
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

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

    delta = {
      enable = true;
      options = {
        features = "side-by-side line-numbers hyperlinks commit-decoration";
      };
    };

    settings = {
      user = {
        name = userSecrets.fullName or user.name;
        email = userSecrets.email or "${user.name}@localhost";
      };

      core = {
        # pre-emptively ignore mac crap
        excludesFile = builtins.toFile "global-gitignore" ''
          .DS_Store
          .DS_Store?
          ._*
          .Spotlight-V100
          .Trashes
          ehthumbs.db
          Thumbs.db
          node_modules
          # Sworm
          .sworm/
          !.sworm/*.json
          # NFS
          *.nfs*
        '';
        attributesfile = builtins.toFile "global-gitattributes" ''
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
      };

      url = lib.optionalAttrs (!(host.isMinimal or false)) {
        # Only force ssh if it's not minimal
        "ssh://git@github.com" = {
          pushInsteadOf = "https://github.com";
        };
        "ssh://git@git.ryot.foo" = {
          pushInsteadOf = "https://git.ryot.foo";
        };
      };

      init = {
        defaultBranch = "main";
      };
    };
  };

}
