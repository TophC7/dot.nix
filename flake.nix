{
  description = "Toph's Nix-Config";

  inputs = {
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    ## NixOS ##

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    hardware = {
      url = "github:nixos/nixos-hardware";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    mix-nix = {
      # url = "github:tophc7/mix.nix";
      url = "path:/repo/Nix/mix.nix";
      inputs = {
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    ## VM tools ##

    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    ## Theming ##

    arroz-nix = {
      # url = "github:tophc7/arroz.nix";
      url = "path:/repo/Nix/arroz.nix";
      inputs = {
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
        hyprnavi-psm.follows = "hyprnavi-psm";
        matugen.follows = "matugen";
        mix-nix.follows = "mix-nix";
        nixpkgs.follows = "nixpkgs-unstable";
        stylix.follows = "stylix";
      };
    };

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    matugen = {
      url = "github:/InioX/Matugen";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ## Gaming ##

    play = {
      # url = "github:tophc7/play.nix";
      url = "path:/repo/Nix/play.nix";
      inputs = {
        chaotic.follows = "chaotic";
        home-manager.follows = "home-manager";
        mix-nix.follows = "mix-nix";
        nixpkgs.follows = "nixpkgs-unstable";
      };
    };

    ## Misc ##

    fresh = {
      url = "github:sinelaw/fresh";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    solaar = {
      url = "github:Svenum/Solaar-Flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    yay = {
      url = "github:tophc7/yay.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-ai = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    hyprnavi-psm = {
      # url = "github:TophC7/hyprnavi-psm";
      url = "path:/repo/rust/hyprnavi";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
