# IMPORTANT: This is used by NixOS and nix-darwin so options must exist in both!
{
  inputs,
  outputs,
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  yay = inputs.yay.packages.${pkgs.system}.default;
in
{
  imports = lib.flatten [
    inputs.home-manager.nixosModules.home-manager
    (lib.custom.scanPaths ./.)

    (map lib.custom.relativeToRoot [
      "modules/global"
      "modules/nixos"
    ])

    # Desktop environment (if enabled)
    (lib.optional (host.gnome or false || host.niri or false) (lib.custom.relativeToRoot "hosts/global/common/desktop"))
  ];

  # System-wide packages, root accessible
  environment.systemPackages = with pkgs; [
    cachix
    curl
    git
    git-crypt
    gpg-tui
    jq
    micro
    openssh
    sshfs
    superfile
    wget
    yay # my yay teehee
    yazi
  ];

  # Enable print to PDF.
  services.printing.enable = true;
  # Force home-manager to use global packages
  home-manager.useGlobalPkgs = true;
  # If there is a conflict file that is backed up, use this extension
  home-manager.backupFileExtension = "homeManagerBackupFileExtension";

  ## Overlays ##
  nixpkgs = {
    overlays = [
      outputs.overlays.default
    ];
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  ## Localization ##
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  time.timeZone = lib.mkDefault "America/New_York";
  networking.timeServers = [ "pool.ntp.org" ];

  ## Nix Helper ##
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 20d --keep 20";
    flake = "/repo/Nix/dot.nix/";
  };

  ## SUDO and Terminal ##
  environment.enableAllTerminfo = true;
  hardware.enableAllFirmware = true;

  security.sudo = {
    extraConfig = ''
      Defaults lecture = never # rollback results in sudo lectures after each reboot, it's somewhat useless anyway
      Defaults pwfeedback # password input feedback - makes typed password visible as asterisks
      Defaults timestamp_timeout=120 # only ask for password every 2h
      # Keep SSH_AUTH_SOCK so that pam_ssh_agent_auth.so can do its magic.
      Defaults env_keep+=SSH_AUTH_SOCK
    '';
  };

  ## Primary shell enablement ##
  programs.fish.enable = true;
  environment.shells = with pkgs; [
    bash
    fish
  ];

  ## NIX NIX NIX ##
  documentation.nixos.enable = lib.mkForce false;
  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # See https://jackson.dev/post/nix-reasonable-defaults/
      connect-timeout = 5;
      log-lines = 25;
      min-free = 128000000; # 128MB
      max-free = 1000000000; # 1GB

      trusted-users = [ "@wheel" ];
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      warn-dirty = false;

      allow-import-from-derivation = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Binary cache substituters
      substituters = [
        "https://cache.nixos.org"
        "https://chaotic-nyx.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      ];
    };
  };
}
