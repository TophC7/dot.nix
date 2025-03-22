{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      extraPkgs = with pkgs; [
        fzf
      ];

      agsPkgs = with inputs.ags.packages.${pkgs.system}; [
        apps
        bluetooth
        greet
        hyprland
        mpris
        network
        notifd
        tray
        wireplumber
      ];
    in
    {
      packages.${system} = {
        default = inputs.ags.lib.bundle {
          inherit pkgs;
          src = ./.;
          name = "yash"; # name of executable
          entry = "app.ts";
          gtk4 = true;

          # additional libraries and executables to add to gjs' runtime
          extraPackages = extraPkgs ++ agsPkgs;
        };
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.wrapGAppsHook
            pkgs.gobject-introspection
            (inputs.ags.packages.${system}.agsFull.override {
              extraPackages = [
                # include extra libs here to add to the gjs runtime environment
                pkgs.libgtop
              ];
            })
          ] ++ extraPkgs;

          buildInputs = [
            inputs.astal.packages.${system}.default
            pkgs.pnpm
          ];
        };
      };
    };
}
