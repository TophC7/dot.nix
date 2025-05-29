{ pkgs, ... }:
{
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
