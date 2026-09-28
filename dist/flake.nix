{
  description = "NixOS installation media based on the current dot.nix modules";

  # Keep these aligned with inputs referenced by ../modules. mix-nix tracks the
  # published repo so CI can build this flake.
  inputs = {
    nixpkgs.follows = "mix-nix/nixpkgs";

    mix-nix.url = "github:tophc7/mix.nix";
    flake-parts.follows = "mix-nix/flake-parts";

    home-manager.follows = "mix-nix/home-manager";

    bonk = {
      url = "github:tophc7/bonk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:tophc7/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pana = {
      url = "github:tophc7/pana";
      inputs.mix-nix.follows = "mix-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.niri.follows = "niri";
    };

    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nautilus-my-computer = {
      url = "github:yannmasoch/nautilus-my-computer?dir=packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sworm = {
      url = "github:tophc7/sworm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (inputs.mix-nix) lib;
      dotNixRoot = ../.;
    in
    flake-parts.lib.mkFlake
      {
        inherit inputs;
        specialArgs = {
          inherit lib dotNixRoot;
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
