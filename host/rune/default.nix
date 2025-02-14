{
  modulesPath,
  config,
  pkgs,
  hostName,
  ...
}:
{
  ## MODULES & IMPORTS ##
  imports = [
    # Common Modules
    ../../common/ssh

    # Import hardware configuration.
    ./hardware.nix

    # Modules
    ./modules/fish
    ./modules/steam
    ./modules/gnome
  ];

  ## NETWORKING ##
  networking.networkmanager.enable = true;

  ## ENVIORMENT & PACKAGES ##
  environment.systemPackages = with pkgs; [
    asdf-vm
    ddcutil
    git
    micro
    nixfmt-rfc-style
    openssh
    ranger
    sshfs
    wezterm
    wget
  ];

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.nix-ld.enable = true;

  environment.variables = {
    HOSTNAME = hostName;
    GTK_THEME = "Gruvbox-Dark";
  };
}
