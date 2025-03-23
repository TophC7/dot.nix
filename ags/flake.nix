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

      nativeBuildInputs = with pkgs; [
        blueprint-compiler
        dart-sass
        esbuild
        fzf
        gobject-introspection
        libgtop
        meson
        ninja
        pkg-config
        wrapGAppsHook4
        gtk4
        gjs
      ];

      agsPkgs = with inputs.ags.packages.${pkgs.system}; [
        apps
        astal4
        bluetooth
        greet
        hyprland
        io
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
          extraPackages = nativeBuildInputs ++ agsPkgs;
        };

        # TO GEN TYPES, ags types is FUCKED
        # npx -y @ts-for-gir/cli generate --ignoreVersionConflicts --outdir ./@girs -g /nix/store/gq0k2imad3ijd0ih87aiinj617wyh34f-gir-dirs/share/gir-1.0
        # subtree script to manage git subtree pushes and pulls. Personal use feel free to remove
        subtree = pkgs.writeScriptBin "subtree" ''
          #!/usr/bin/env fish

          if test (count $argv) -ne 1
              echo "Usage: $argv0 push|pull"
              exit 1
          end

          set action $argv[1]
          set subtree_path "ags"
          set remote "yash-origin"
          set branch "main"

          cd (git rev-parse --show-toplevel)
          switch $action
              case push
                  set changes (git status --porcelain "$subtree_path")
                  if test -n "$changes"
                      set_color yellow; echo " Cannot push. There are uncommitted changes in $subtree_path."
                      exit 1
                  end
                  git subtree push --prefix="$subtree_path" $remote $branch
              case pull
                  git subtree pull --prefix="$subtree_path" $remote $branch
              case commit
                  set changes (git status --porcelain "$subtree_path")
                  if test -z "$changes"
                      echo "No changes to commit in $subtree_path."
                      exit 0
                  end
                  echo " Enter commit message:"
                  read commit_message
                  if test -z "$commit_message"
                      echo "Commit message cannot be empty."
                      exit 1
                  end
                  git add "$subtree_path"
                  git commit -m "$commit_message"
              case '*'
                  echo "Unknown argument. Use push or pull."
                  exit 1
          end
        '';
      };

      devShells.${system} = {
        default = pkgs.mkShell {
          nativeBuildInputs = [
            (inputs.ags.packages.${system}.agsFull.override {
              extraPackages = nativeBuildInputs;
            })
          ];

          packages = [
            pkgs.gjs
            pkgs.pnpm
            pkgs.nodejs
            self.packages.${system}.subtree
            inputs.ags.packages.${system}.agsFull
            inputs.astal.packages.${system}.default
          ] ++ nativeBuildInputs;
        };
      };
    };
}
