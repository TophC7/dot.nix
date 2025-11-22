{ pkgs, ... }:
{
  home.packages = with pkgs; [
    lsfg-vk
    lsfg-vk-ui
  ];

  # TODO: Add toml configurations for games
}
