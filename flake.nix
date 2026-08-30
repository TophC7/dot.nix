{
  description = "Toph's Nix-Config";

  inputs = {
    # Derive nixpkgs from mix-nix for cache coherence
    # This ensures mix.nix packages use cached builds
    nixpkgs.follows = "mix-nix/nixpkgs";
    nixpkgs-stable.follows = "mix-nix/nixpkgs-stable";

    ## NixOS ##

    flake-parts.url = "github:hercules-ci/flake-parts";
    systems-linux.url = "github:nix-systems/default-linux";

    hardware = {
      url = "github:nixos/nixos-hardware";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
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

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
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

    pana = {
      url = "git+file:///repo/rust/pana";
      inputs.mix-nix.follows = "mix-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.matugen.follows = "matugen";
      inputs.niri.follows = "niri";
    };

    anker-c200 = {
      url = "git+https://git.ryot.foo/toph/anker-powerconf-c200-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:tophc7/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nautilus-my-computer = {
      url = "github:yannmasoch/nautilus-my-computer?dir=packaging/nix";
      inputs.nixpkgs.follows = "nixpkgs";
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

    bedrock-on-linux = {
      url = "github:Wyze3306/BedrockOnLinux";
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

    ## Creative ##

    affinity-nix = {
      url = "github:mrshmllow/affinity-nix";
    };

    ## Misc ##

    bonk = {
      # url = "github:tophc7/bonk";
      url = "git+file:///repo/rust/bonk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Keep llm-agents' pinned nixpkgs: Numtide's prebuilt binaries are keyed to it.
    llm-agents.url = "github:numtide/llm-agents.nix";

    sworm = {
      # url = "github:TophC7/Sworm";
      url = "git+file:///home/toph/Development/sworm";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.bun2nix.inputs.systems.follows = "systems-linux";
    };

    omp-nix = {
      url = "git+file:///repo/Nix/omp.nix";
      # No nixpkgs override: upstream omp pins its own nixpkgs for `packages.omp`
      # either way, and leaving omp.nix self-locking keeps the context-mode we
      # consume identical to the one nimbus builds from that repo directly.
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
