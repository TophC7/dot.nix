{
  pkgs,
  ...
}:
{
  ## Packages with no needed configs ##
  home.packages = with pkgs; [
    # Web Dev
    gh
  ];
}
