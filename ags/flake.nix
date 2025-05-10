{
  description = "AGS Shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ags,
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      extraAgsLib = with ags.packages.${system}; [
        apps
        apps
        battery
        bluetooth
        cava
        hyprland
        io
        mpris
        network
        notifd
        powerprofiles
        tray
        wireplumber
      ];

    in
    {
      packages.${system} = {
        default = ags.lib.bundle {
          inherit pkgs;
          src = ./.;
          name = "ags-shell";
          entry = "app.ts";
          gtk4 = true;

          # additional libraries and executables to add to gjs' runtime
          extraPackages = extraAgsLib ++ [ pkgs.fzf ];
        };

        # Ags hot reload
        ags-watch = pkgs.writeScriptBin "ags-watch" ''
          #!${pkgs.fish}/bin/fish

          ls **.tsx | ${pkgs.lib.getExe pkgs.entr} -r ags run -d ./ --gtk4
        '';
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          buildInputs = [
            # pkgs.typescript-language-server
            pkgs.biome
            pkgs.fish
            pkgs.glib
            pkgs.glibc
            pkgs.nodejs
            pkgs.pnpm
            self.packages.${system}.ags-watch
            # includes astal3 astal4 astal-io by default
            (ags.packages.${system}.default.override {
              extraPackages = extraAgsLib;
            })
          ];
        };
      };
    };
}
