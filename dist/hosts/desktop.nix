{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  hostSpec = config.hostSpec;
  username = "nixos";
  user = config.secretsSpec.users.${username};

  calamares-nixos-autostart = pkgs.makeAutostartItem {
    name = "io.calamares.calamares";
    package = pkgs.calamares-nixos;
  };
in
{
  imports = [
    "${inputs.dot-nix}/hosts/global/core"
    "${inputs.dot-nix}/hosts/global/common/gnome.nix" # desktop
    "${inputs.dot-nix}/hosts/global/common/plymouth.nix" # fancy boot screen
  ];

  hostSpec = {
    hostName = "nixos";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = false;
    isMinimal = false;
  };

  # Whitelist wheel users to do anything
  # This is useful for things like pkexec
  #
  # WARNING: this is dangerous for systems
  # outside the installation-cd and shouldn't
  # be used anywhere else.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = with pkgs; [
    # Calamares for graphical installation
    libsForQt5.kpmcore
    calamares-nixos
    calamares-nixos-autostart
    calamares-nixos-extensions
    # Get list of locales
    glibcLocales
  ];

  # Support choosing from any locale
  i18n.supportedLocales = [ "all" ];

  home-manager = lib.mkForce {
    extraSpecialArgs = {
      inherit pkgs inputs;
      inherit (config) secretsSpec hostSpec;
    };
    users = {
      root.home.stateVersion = "24.05"; # Avoid error
      ${username} = {
        imports = [
          (import ../home {
            inherit
              config
              hostSpec
              inputs
              lib
              pkgs
              ;
          })
        ];
      };
    };
  };
}
