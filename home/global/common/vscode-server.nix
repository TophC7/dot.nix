{ pkgs, inputs, ... }:
{

  imports = [ inputs.vscode-server.homeModules.default ];

  ## ALLOWS VS CODE SERVER ##
  services.vscode-server.enable = true;
  services.vscode-server.enableFHS = true;
  # programs.nix-ld = {
  #   enable = true;
  #   package = pkgs.nix-ld-rs;
  # };
}
