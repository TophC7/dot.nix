_: {
  monitors = [
    {
      name = "DP-5"; # Dell U2417H - 1080p Monitor (LEFT side, portrait)
      primary = false;
      width = 1920;
      height = 1080;
      refreshRate = 60;
      x = 0; # Left-most monitor
      y = 0;
      scale = 1.0;
      transform = 3; # 270° rotation for portrait mode
      enabled = true;
    }
    {
      name = "DP-3"; # ASUSTek PG42UQ - 4K Gaming Monitor (RIGHT side, primary)
      primary = true;
      width = 3840;
      height = 2160;
      refreshRate = 120;
      x = 1080; # Positioned to the right of DP-5 (1920x1080 rotated = 1080 wide)
      y = 0;
      scale = 1.0;
      transform = 0;
      enabled = true;
    }
  ];
}
