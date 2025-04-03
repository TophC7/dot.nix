{
  # Enable gammastep for night light
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = 37.541290;
    longitude = -77.434769;
    settings = {
      general = {
        fade = 1;
        adjustment-method = "wayland";
      };
    };
  };
}
