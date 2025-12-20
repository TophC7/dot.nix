{
  description = "Toph's Nix-Config";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # Bleeding edge packages from Chaotic-AUR

    ## NixOS ##

    hardware = {
      url = "github:nixos/nixos-hardware";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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

    # nixtheplanet.url = "github:matthewcroughan/nixtheplanet";
    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    ## Theming ##

    rose-pine-hyprcursor = {
      url = "github:ndom91/rose-pine-hyprcursor";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    matugen = {
      url = "github:/InioX/Matugen";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ## Gaming Packages ##
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

    ## Misc Packages ##

    solaar = {
      url = "github:Svenum/Solaar-Flake";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-ai = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    ## NIRI ##

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.dgop.follows = "dgop";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
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
          ./mix
          ./devshell.nix
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      };
}
