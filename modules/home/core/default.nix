# Core Home Manager modules - required for all users
#
# With mix.nix, this is imported via mix.coreHomeModules.
# Auto-discovers sibling modules via lib.fs.scanPaths.
#
# Available in specialArgs:
#   - host (host.user, host.desktop, host.hostName, etc.)
#   - inputs
#   - secrets (if configured via mix.secrets)
#
{
  config,
  lib,
  pkgs,
  host,
  inputs,
  flakeRoot,
  ...
}:
let
  user = host.user;
in
{
  imports = lib.flatten [
    (lib.fs.scanPaths ./.)
    # Desktop environment (if enabled)
    (lib.optional (host.desktop != null) ../common/desktop)
    # Fastfetch from mix.nix
    inputs.mix-nix.homeManagerModules.fastfetch
  ];

  # Fastfetch config - logo auto-discovered from user's home.directory
  mix.fastfetch = {
    enable = true;
    weather.location = "Richmond";
    logo.directory = lib.fs.relativeTo flakeRoot "hosts/${host.hostName}";
  };

  services.ssh-agent.enable = true;

  home = {
    username = lib.mkDefault user.name;
    stateVersion = lib.mkDefault "25.11";
    sessionPath = [
      "~/.local/bin"
    ];
    sessionVariables = {
      EDITOR = lib.mkDefault "micro";
      VISUAL = lib.mkDefault "micro";
      FLAKE = lib.mkDefault "/repo/Nix/dot.nix";
      SHELL = lib.getExe user.shell;
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
      nmap # network scannero
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
            "mbedtls-2.28.10"
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
