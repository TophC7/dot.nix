{
  modulesPath,
  config,
  pkgs,
  hostName,
  user,
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
    ./modules/steam
    ./modules/gnome
  ];

  ## USERS ##
  users.mutableUsers = false;
  users.users."${user}" = {
    isNormalUser = true;
    createHome = true;
    description = "${user}";
    homeMode = "750";
    home = "/home/${user}";
    password = "198913";
    extraGroups = [
      "networkmanager"
      "wheel"
      "i2c"
    ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClZstYoT64zHnGfE7LMYNiQPN5/gmCt382lC+Ji8lrH PVE"
    ];
  };

  ## NETWORKING ##
  networking.networkmanager.enable = true;

  ## ENVIORMENT & PACKAGES ##
  environment.systemPackages = with pkgs; [
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

  programs.java = {
    enable = true;
    package = pkgs.jdk;
  };

  environment.variables = {
    HOSTNAME = hostName;
    GTK_THEME = "Gruvbox-Dark";
  };
}
