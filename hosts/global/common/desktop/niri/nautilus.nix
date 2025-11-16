{ config, pkgs, ... }:
{
  # Nuatilus and its tools
  environment.systemPackages = with pkgs; [
    code-nautilus
    file-roller
    gnome-epub-thumbnailer
    nautilus
    papers
    sushi
    turtle
  ];

  programs.nautilus-open-any-terminal.enable = true;
}
