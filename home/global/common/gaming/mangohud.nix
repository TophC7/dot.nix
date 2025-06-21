{
  lib,
  ...
}:
{
  programs.mangohud = {
    enable = true;
    settings = {
      position = "top-right";
      cpu_stats = true;
      gpu_stats = true;
      fps = true;
      font_size = 12;
      cellpadding_y = -0.070;
      background_alpha = lib.mkForce 0.5;
      alpha = lib.mkForce 0.75;
    };
  };
}
