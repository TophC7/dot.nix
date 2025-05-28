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
  username = "cesar";
  user = config.secretsSpec.users.${username};
in
{
  imports = lib.flatten [

    ## Hardware ##
    ./hardware.nix

    (map lib.custom.relativeToRoot [
      ## Required Configs ##
      "hosts/global/core"

      ## Optional Configs ##
      "hosts/global/common/audio.nix" # pipewire and cli controls
      "hosts/global/common/gnome.nix" # desktop
      # "hosts/global/common/plymouth.nix" # fancy boot screen

      ## Misc Inputs ##
    ])

  ];

  ## Host Specifications ##
  hostSpec = {
    hostName = "vm";
    username = username;
    hashedPassword = user.hashedPassword;
    email = user.email;
    handle = user.handle;
    userFullName = user.fullName;
    isServer = true;
  };

  networking = {
    enableIPv6 = false;
  };

  # VM guest additions to improve host-guest interaction
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;
  virtualisation.vmware.guest.enable = pkgs.stdenv.hostPlatform.isx86;
  virtualisation.hypervGuest.enable = true;
  services.xe-guest-utilities.enable = pkgs.stdenv.hostPlatform.isx86;
  # The VirtualBox guest additions rely on an out-of-tree kernel module
  # which lags behind kernel releases, potentially causing broken builds.
  virtualisation.virtualbox.guest.enable = false;

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
