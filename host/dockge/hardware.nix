{
  # Treats the system as a container.
  boot.isContainer = true;

  # TODO: SSHFS
  # fileSystems."/" = {
  #   device = "/dev/sda1";
  #   fsType = "ext4";
  # };

  # Set your system kind (needed for flakes)
  nixpkgs.hostPlatform = "x86_64-linux";
}