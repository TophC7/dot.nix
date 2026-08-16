{ lib, ... }:
{
  console = {
    enable = true;
    keyMap = "us";
  };

  # installation-cd defines initial passwords; dot.nix owns the final hashes.
  users.users.nixos.initialHashedPassword = lib.mkForce null;
  users.users.root.initialHashedPassword = lib.mkForce null;
}
