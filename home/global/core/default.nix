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
      EDITOR = "micro";
      FLAKE = lib.mkDefault "${homeDir}/git/Nix/dot.nix";
      MANPAGER = "batman";
      SHELL = lib.getExe shell;
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

  # Core pkgs with no configs
  home.packages = builtins.attrValues {
    inherit (pkgs)
      btop # resource monitor
      coreutils # basic gnu utils
      delta # diffing
      difftastic # diffing
      direnv # environment per directory
      dust # disk usage
      eza # ls replacement
      gh # github cli
      jq # json parser
      man-pages
      man-pages-posix
      nixfmt-rfc-style # nix formatter
      nixpkgs-review # nix review tool
      nmap # network scanner
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

  ## NIX NIX NIX ##
  home.file =
    let
      nixConfig = pkgs.writeText "config.nix" ''
        {
          allowUnfree = true;
          permittedInsecurePackages = [
            "ventoy-gtk3-1.1.05"
          ];
        }
      '';
    in
    {
      ".config/nixpkgs/config.nix" = {
        source = nixConfig;
      };
    };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
