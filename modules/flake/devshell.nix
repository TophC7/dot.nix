{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      devShells.default = pkgs.mkShell {
        packages =
          with pkgs;
          [
            # Basic nix tools
            nix
            nixos-rebuild
            home-manager
            nh
            # Git and git-crypt
            git
            git-crypt
            gnupg
            gpg-tui
            # Shells
            fish
            bash
            # Config tools
            dconf2nix
            compose2nix
            # Network tools
            bind
            curl
            iperf3
            mtr
            netcat-gnu
            nmap
            tcpdump
            traceroute
            wget
            whois
            wireshark-cli # tshark
            # System tools
            coreutils
            findutils
            gzip
            zstd
            # Text editors
            micro
            # Diagnostics
            inxi
            pciutils
            usbutils
            lshw
            # AI
            github-copilot-cli
          ]
          ++ [
            inputs.yay.packages.${system}.default # My yay.nix tool
          ];

        NIX_CONFIG = "experimental-features = nix-command flakes";

        shellHook = ''
          clear
          echo "Development shell initialized"
          echo -e "Run '\033[1;34myay rebuild\033[0m' to rebuild your system"

          # Set FLAKE to the current working directory
          export FLAKE="$PWD"
          echo -e "FLAKE environment variable is set to: \033[1;34m$FLAKE\033[0m"
        '';
      };
    };
}
