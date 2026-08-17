{
  config,
  dotNixRoot,
  flakeRoot,
  inputs,
  ...
}:
let
  isoPackage = name: config.flake.nixosConfigurations.${name}.config.system.build.isoImage;
in
{
  mix = {
    hostSpecExtensions = [ (dotNixRoot + "/mix/hostSpec.nix") ];

    secrets = {
      file = flakeRoot + "/mix/not-secrets.nix";
      skipValidation = true; # This file intentionally contains only public live-ISO credentials.
    };

    usersHomeDir = flakeRoot + "/home/users";
    specialArgs = { inherit flakeRoot; };

    coreModules = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
      (dotNixRoot + "/modules/hosts/core")
      (flakeRoot + "/mix/core.nix")
      ({ host, ... }: {
        imports = [
          (flakeRoot + "/hosts/${if host.isServer then "server" else "desktop"}.nix")
        ];
      })
    ];

    coreHomeModules = [ (dotNixRoot + "/modules/home/core") ];

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
