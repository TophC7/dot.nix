#FIXME: Move attrs that will only work on linux to nixos.nix
#FIXME: if pulling in homemanager for isMinimal maybe set up conditional for some packages
{
  config,
  lib,
  pkgs,
  hostSpec,
  ...
}:
{
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "modules/common/host-spec.nix"
    ])
    ./asdf.nix
    ./bash.nix
    ./bat.nix
    ./direnv.nix
    ./fastfetch
    ./fish
    ./fonts.nix
    ./git.nix
    ./ranger.nix
    ./screen.nix
    ./ssh.nix
    ./zoxide.nix
  ];

  inherit hostSpec;

  services.ssh-agent.enable = true;

  home = {
    username = lib.mkDefault config.hostSpec.username;
    homeDirectory = lib.mkDefault config.hostSpec.home;
    stateVersion = lib.mkDefault "24.05";
    sessionPath = [
      "$HOME/.local/bin"
    ];
    sessionVariables = {
      FLAKE = "$HOME/git/dot.nix";
      SHELL = "fish";
      EDITOR = "micro";
      VISUAL = "micro";
      MANPAGER = "batman"; # see ./cli/bat.nix
    };
    preferXdgDirectories = true; # whether to make programs use XDG directories whenever supported

  };

  #TODO(xdg): maybe move this to its own xdg.nix?
  # xdg packages are pulled in below
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      # desktop = "${config.home.homeDirectory}/.desktop";
      # documents = "${config.home.homeDirectory}/doc";
      # download = "${config.home.homeDirectory}/downloads";
      # music = "${config.home.homeDirectory}/media/audio";
      # pictures = "${config.home.homeDirectory}/media/images";
      # videos = "${config.home.homeDirectory}/media/video";
      # publicshare = "/var/empty"; #using this option with null or "/var/empty" barfs so it is set properly in extraConfig below
      # templates = "/var/empty"; #using this option with null or "/var/empty" barfs so it is set properly in extraConfig below

      extraConfig = {
        # publicshare and templates defined as null here instead of as options because
        XDG_PUBLICSHARE_DIR = "/var/empty";
        XDG_TEMPLATES_DIR = "/var/empty";
      };
    };
  };

  home.packages = builtins.attrValues {
    inherit (pkgs)
      # Packages that don't have custom configs go here
      btop # resource monitor
      coreutils # basic gnu utils
      curl
      eza # ls replacement
      dust # disk usage
      pre-commit # git hooks
      p7zip # compression & encryption
      unzip # zip extraction
      unrar # rar extraction
      wget # downloader
      xdg-utils # provide cli tools such as `xdg-mime` and `xdg-open`
      xdg-user-dirs
      zip # zip compression
      ;
  };

  programs.nix-index = {
    enable = true;
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
