{
  config,
  dotNixRoot,
  ...
}:
let
  isoPackage = name: config.flake.nixosConfigurations.${name}.config.system.build.isoImage;
in
{
  mix = {
    apiVersion = 2;
    # Reuse dot.nix's modules/core and modules/features; this flake adds its own
    # modules/core (installer + ISO settings) and modules/users/nixos
    extends = dotNixRoot;
    hostSpecExtensions = [ (dotNixRoot + "/mix/hostSpec.nix") ];

    secrets = {
      file = ./not-secrets.nix;
      skipValidation = true; # This file intentionally contains only public live-ISO credentials.
    };

    users.nixos = {
      name = "nixos";
      uid = 1000;
      group = "users";
      shell = "fish";
      extraGroups = [
        "audio"
        "input"
        "networkmanager"
        "video"
        "wheel"
      ];
      email = "admin@localhost";
      handle = "nixos";
      fullName = "NixOS Live User";
    };

    hosts = {
      server-iso-arm = {
        hostName = "nixos";
        system = "aarch64-linux";
        user = "nixos";
        isServer = true;
        isMinimal = true;
      };

      desktop-iso-arm = {
        hostName = "nixos";
        system = "aarch64-linux";
        user = "nixos";
        niriShell = "pana";
      };

      server-iso-x86 = {
        hostName = "nixos";
        system = "x86_64-linux";
        user = "nixos";
        isServer = true;
        isMinimal = true;
      };

      desktop-iso-x86 = {
        hostName = "nixos";
        system = "x86_64-linux";
        user = "nixos";
        niriShell = "pana";
      };
    };
  };

  flake.packages = {
    x86_64-linux = {
      server-iso-arm = isoPackage "server-iso-arm";
      desktop-iso-arm = isoPackage "desktop-iso-arm";
      server-iso-x86 = isoPackage "server-iso-x86";
      desktop-iso-x86 = isoPackage "desktop-iso-x86";
    };

    aarch64-linux = {
      server-iso-arm = isoPackage "server-iso-arm";
      desktop-iso-arm = isoPackage "desktop-iso-arm";
    };
  };
}
