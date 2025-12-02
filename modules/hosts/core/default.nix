# Core NixOS modules - required for all hosts
#
# With mix.nix, this is imported via mix.coreModules.
# Auto-discovers sibling modules via lib.fs.scanPaths.
#
# Available in specialArgs:
#   - host (host.user, host.desktop, host.hostName, etc.)
#   - inputs
#   - secrets (if configured via mix.secrets)
#
{
  inputs,
  config,
  host,
  lib,
  pkgs,
  secrets ? { },
  ...
}:
let
  yay = inputs.yay.packages.${host.system}.default;
in
{
  imports = lib.flatten [
    (lib.fs.scanPaths ./.)
    # Desktop environment (if enabled)
    (lib.optional (host.desktop != null) ../common/desktop)
  ];

  # System-wide packages, root accessible
  environment.systemPackages = with pkgs; [
    cachix
    curl
    ethtool
    git
    git-crypt
    gpg-tui
    jq
    micro
    openssh
    pciutils
    sshfs
    superfile
    wget
    yay
    yazi
  ];

  # Enable print to PDF.
  services.printing.enable = true;

  ## Nixpkgs config ##
  nixpkgs.config = {
    allowUnfree = true;
    allowUnfreePredicate = _: true;
    permittedInsecurePackages = [
      "mbedtls-2.28.10"
    ];
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
      Defaults lecture = never
      Defaults pwfeedback
      Defaults timestamp_timeout=120
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
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      connect-timeout = 5;
      log-lines = 25;
      min-free = 128000000; # 128MB
      max-free = 1000000000; # 1GB

      trusted-users = [ "@wheel" ];
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
        "https://cache.ryot.foo?priority=1"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        secrets.service.cache.pub
      ]
      ++ lib.optional (secrets ? service && secrets.service ? cache) secrets.service.cache.pub;
    };
  };
}
