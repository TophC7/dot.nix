{
  description = "NixOS installation media based on the current dot.nix modules";

  # Keep these aligned with inputs referenced by ../modules. dist stays CI-safe
  # by using public sources instead of the root flake's local development URLs.
  inputs = {
    nixpkgs.follows = "mix-nix/nixpkgs";

    mix-nix.url = "github:tophc7/mix.nix";
    flake-parts.follows = "mix-nix/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fresh = {
      url = "github:sinelaw/fresh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bonk = {
      url = "github:tophc7/bonk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:tophc7/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nautilus-my-computer = {
      url = "github:yannmasoch/nautilus-my-computer?dir=packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms-actions = {
      url = "github:AvengeMedia/dms-plugins";
      flake = false;
    };

    dms-easyeffects = {
      url = "github:jonkristian/dms-easyeffects";
      flake = false;
    };

    dms-quick-tote = {
      url = "github:JDKamalakar/DMS-Quick_Tote";
      flake = false;
    };

    dms-clipboard-plus = {
      url = "github:Dadangdut33/dms-plugins";
      flake = false;
    };

    dms-github-heatmap = {
      url = "github:JDKamalakar/DMS-GitHub_HeatMap";
      flake = false;
    };

    dms-amd-gpu-monitor = {
      url = "github:JDKamalakar/DMS-AMD_GPU_Monitor_Revive";
      flake = false;
    };

    dms-cat-widget = {
      url = "github:xi-ve/cat-dms";
      flake = false;
    };

    dms-plugins = {
      url = "git+https://git.ryot.foo/toph/dms-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anker-c200 = {
      url = "git+https://git.ryot.foo/toph/anker-powerconf-c200-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (inputs.mix-nix) lib;
      flakeRoot = ./.;
      dotNixRoot = ../.;
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs = {
          inherit lib flakeRoot dotNixRoot;
        };
      }
      {
        imports = [
          inputs.mix-nix.flakeModules.default
          ./mix
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
}
