#FIXME: Move attrs that will only work on linux to nixos.nix
#FIXME: if pulling in homemanager for isMinimal maybe set up conditional for some packages
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
  shell = hostSpec.shell;
in
{
  imports = lib.flatten [
    (map lib.custom.relativeToRoot [
      "modules/global"
      "modules/home"
    ])
    ./asdf.nix
    ./bash.nix # TODO: setup a nicer bash config... or zsh
    ./bat.nix
    ./direnv.nix
    ./fastfetch
    ./fish
    ./git.nix
    ./ranger.nix
    ./screen.nix
    ./ssh.nix
    ./zoxide.nix
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
      EDITOR = "micro";
      FLAKE = "${homeDir}/git/Nix/dot.nix";
      MANPAGER = "batman"; # see ./cli/bat.nix
      SHELL = shell;
      TERM = "foot";
      VISUAL = "micro";
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
      dust # disk usage
      eza # ls replacement
      jq # json parser
      p7zip # compression & encryption
      pre-commit # git hooks
      trashy # trash cli
      unrar # rar extraction
      unzip # zip extraction
      xdg-user-dirs
      xdg-utils # provide cli tools such as `xdg-mime` and `xdg-open`
      zip # zip compression
      ;
  };

  programs.nix-index = {
    enable = true;
  };

  # disable manuals as nmd fails to build often
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
