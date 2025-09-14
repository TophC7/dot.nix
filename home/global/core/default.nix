{
  config,
  lib,
  pkgs,
  hostSpec,
  ...
}:
let
  username = hostSpec.username;
  homeDir = hostSpec.home;
  shell = hostSpec.shell or pkgs.fish;
in
{
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "modules/global"
      "modules/home"
    ])
    (lib.custom.scanPaths ./.)
  ];

  services.ssh-agent.enable = true;

  home = {
    username = lib.mkDefault username;
    homeDirectory = lib.mkDefault homeDir;
    stateVersion = lib.mkDefault "24.05";
    sessionPath = [
      "${homeDir}/.local/bin"
    ];
    sessionVariables = {
      EDITOR = lib.mkDefault "micro";
      VISUAL = lib.mkDefault "micro";
      FLAKE = lib.mkDefault "/repo/Nix/dot.nix";
      SHELL = lib.getExe shell;
    };
    preferXdgDirectories = true; # whether to make programs use XDG directories whenever supported
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      extraConfig = {
        # publicshare and templates defined as null here instead of as options because
        XDG_PUBLICSHARE_DIR = "/var/empty";
        XDG_TEMPLATES_DIR = "/var/empty";
      };
    };
  };

  # Core pkgs with no configs
  home.packages = builtins.attrValues {
    inherit (pkgs)
      coreutils # basic gnu utils
      direnv # environment per directory
      dust # disk usage
      eza # ls replacement
      lazyjournal # journalctl viewer
      nmap # network scanner
      trashy # trash cli
      unrar # rar extraction
      unzip # zip extraction
      zip # zip compression
      ;
  };

  programs.nix-index = {
    enable = true;
  };

  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
    };
  };

  programs.home-manager.enable = true;

  ## NIX NIX NIX ##
  home.file =
    let
      nixConfig = pkgs.writeText "config.nix" ''
        {
          allowUnfree = true;
          fallback = true;
          connect-timeout = 10;
          permittedInsecurePackages = [
            "minecraft"
            "ventoy-gtk3-1.1.05"
            "modrinth-app"
            "claude-code"
          ];
        }
      '';
    in
    {
      ".config/nixpkgs/config_source" = {
        source = nixConfig;
        onChange = ''
          cp $HOME/.config/nixpkgs/config_source $HOME/.config/nixpkgs/config.nix
          chmod 644 $HOME/.config/nixpkgs/config.nix
        '';
      };
    };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
