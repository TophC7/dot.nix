_: {
  monitors = [
    {
      name = "HDMI-A-1"; # LG TV SSCR2 - 4K 120 Hz (left)
      primary = true;
      width = 3840;
      height = 2160;
      refreshRate = 120;
      x = 0;
      y = 0;
      scale = 1.25;
      transform = 0;
      enabled = true;
    }
    {
      name = "DP-5"; # ASUSTek PG42UQ - 4K 120 Hz (right, primary)
      primary = false;
      width = 3840;
      height = 2160;
      refreshRate = 120;
      x = 3072;
      y = 0;
      scale = 1.25;
      transform = 0;
      enabled = true;
    }
    {
      name = "HDMI-A-2"; # Detached virtual 2K display for Sunshine streaming
      primary = false;
      width = 2560;
      height = 1440;
      refreshRate = 60;
      x = 0;
      y = 3072;
      scale = 1.0;
      transform = 0;
      enabled = false;
    }
  ];
}
