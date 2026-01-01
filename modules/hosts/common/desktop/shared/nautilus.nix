# Nautilus file manager and related tools
{ pkgs, ... }:
{
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
