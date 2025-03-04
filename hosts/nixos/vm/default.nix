###############################################################
#
#  VM - Testing Virtual Machine
#  NixOS running in VM
#
###############################################################

{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  username = "toph";
in
{
  imports = lib.flatten [

    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/common/core"

      ## Optional Configs ##
      "hosts/common/optional/audio.nix" # pipewire and cli controls
      "hosts/common/optional/gnome.nix" # desktop
      # "hosts/common/optional/plymouth.nix" # fancy boot screen

      ## Misc Inputs ##

      ## VM Specific ##
      "hosts/users/${username}" # Not the best solution but I always have just one user so ¯\_(ツ)_/¯
    ])

  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "vm";
    username = username;
    handle = "tophC7";
    password = "[REDACTED]";
    [REDACTED];
    email = "[REDACTED]";
    userFullName = "[REDACTED]";
    isARM = false;
  };

  networking = {
    enableIPv6 = false;
  };

  ## System-wide packages ##
  environment.systemPackages = with pkgs; [
    openssh
    ranger
    sshfs
    wget

  ];

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
