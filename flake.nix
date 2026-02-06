{
  description = "Toph's Nix-Config";

  inputs = {
    # Derive nixpkgs from mix-nix for cache coherence
    # This ensures mix.nix packages use cached builds
    nixpkgs.follows = "mix-nix/nixpkgs";
    nixpkgs-stable.follows = "mix-nix/nixpkgs-stable";

    ## NixOS ##

    flake-parts.url = "github:hercules-ci/flake-parts";

    hardware = {
      url = "github:nixos/nixos-hardware";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mix-nix = {
      # url = "github:tophc7/mix.nix";
      url = "git+file:///repo/Nix/mix.nix";
      # Don't override nixpkgs - let mix.nix control it for cache hits
    };

    ## VM tools ##

    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    ## Theming ##

    arroz-nix = {
      # url = "github:tophc7/arroz.nix";
      url = "git+file:///repo/Nix/arroz.nix";
      inputs = {
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
        hyprnavi-psm.follows = "hyprnavi-psm";
        matugen.follows = "matugen";
        mix-nix.follows = "mix-nix";
        nixpkgs.follows = "nixpkgs";
        stylix.follows = "stylix";
      };
    };

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    matugen = {
      url = "github:/InioX/Matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Gaming ##

    hytale-launcher = {
      url = "github:JPyke3/hytale-launcher-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    play = {
      # url = "github:tophc7/play.nix";
      url = "git+file:///repo/Nix/play.nix";
      inputs = {
        home-manager.follows = "home-manager";
        mix-nix.follows = "mix-nix";
        nixpkgs.follows = "nixpkgs";
      };
    };

    wayscope = {
      # url = "github:tophc7/wayscope";
      url = "git+file:///repo/rust/wayscope";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Misc ##

    fresh = {
      url = "github:sinelaw/fresh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    solaar = {
      url = "github:Svenum/Solaar-Flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bonk = {
      # url = "github:tophc7/bonk";
      url = "git+file:///repo/rust/bonk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yay = {
      # url = "github:tophc7/yay.nix";
      url = "git+file:///repo/Nix/yay.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ai = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprnavi-psm = {
      # url = "github:TophC7/hyprnavi-psm";
      url = "git+file:///repo/rust/hyprnavi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      # Extend nixpkgs lib with mix.nix utilities BEFORE entering flake-parts
      # This gives us lib.fs.*, lib.hosts.*, lib.desktop.*, etc.
      lib = inputs.mix-nix.lib;
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs = { inherit lib; };
      }
      {
        imports = [
          inputs.mix-nix.flakeModules.default
          inputs.arroz-nix.flakeModules.default # Extends mix-nix with desktop/greeter options
          ./mix
          ./devshell.nix
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
}
