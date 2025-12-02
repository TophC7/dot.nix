{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      ddcutil
      ;
  };

  hardware.i2c.enable = true;
  services.udev = {
    enable = true;
    extraRules = ''
      KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
    '';
  };
}
