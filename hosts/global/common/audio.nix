{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nix-gaming.nixosModules.pipewireLowLatency
  ];

  services.pulseaudio = {
    enable = false;
    package = pkgs.pulseaudioFull;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
    lowLatency.enable = true;
  };

  # services.easyeffects = {
  #   enable = true;
  # };

  # environment.systemPackages = with pkgs; [
  #   gnomeExtensions.easyeffects-preset-selector
  # ];
}
