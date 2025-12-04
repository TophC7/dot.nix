{ pkgs, inputs, ... }:
{
  imports = [ inputs.mix-nix.nixosModules.oci-stacks ];

  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    oci-containers.backend = "docker";
  };

  environment.systemPackages = with pkgs; [
    lazydocker # Simple TUI
  ];
}
