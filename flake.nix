{
  description = "Toph's Nix-Config";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # Bleeding edge packages from Chaotic-AUR

    ## NixOS ##

    hardware = {
      url = "github:nixos/nixos-hardware";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ## VM tools ##

    # nixtheplanet.url = "github:matthewcroughan/nixtheplanet";
    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    ## Theming ##

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
    };

    stylix.url = "github:danth/stylix";

    ## Gaming Packages ##

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    play = {
      url = "github:tophc7/play.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        chaotic.follows = "chaotic";
      };
    };

    ## Misc Packages ##

    # nixcord.url = "github:kaylorben/nixcord";
    # spicetify-nix = {
    #   url = "github:Gerg-L/spicetify-nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    solaar = {
      url = "github:Svenum/Solaar-Flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    snapraid-aio = {
      url = "github:tophc7/snapraid-aio.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    yay = {
      url = "github:tophc7/yay.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];

      imports = [
        ./modules/flake/overlays.nix
        ./modules/flake/nixos.nix
        ./modules/flake/packages.nix
        ./modules/flake/devshell.nix
      ];
    };
}
