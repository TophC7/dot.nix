# Nautilus and its desktop-independent integrations.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Upstream omits pycairo from nautilus-python's embedded module search path.
  nautilusMyComputer =
    inputs.nautilus-my-computer.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (oldAttrs: {
        postFixup = (oldAttrs.postFixup or "") + ''
          ln -s \
            ${pkgs.python3Packages.pycairo}/${pkgs.python3.sitePackages}/cairo \
            $out/share/nautilus-python/extensions/cairo

          mkdir -p $out/share/gsettings-schemas/$name/glib-2.0
          ln -s \
            $out/share/glib-2.0/schemas \
            $out/share/gsettings-schemas/$name/glib-2.0/schemas
        '';
      });
in
{
  environment.systemPackages = with pkgs; [
    code-nautilus
    file-roller
    gnome-epub-thumbnailer
    nautilus
    nautilusMyComputer
    nautilus-python
    papers
    sushi
    turtle
  ];

  environment.pathsToLink = [ "/share/nautilus-python/extensions" ];

  programs.nautilus-open-any-terminal = {
    enable = lib.mkDefault true;
    terminal = lib.mkDefault "ghostty";
  };

  services = {
    gvfs.enable = lib.mkDefault true;
    udisks2.enable = lib.mkDefault true;
  };

  environment.sessionVariables = {
    # The upstream terminal-extension module exposes only nautilus-python here,
    # hiding every other extension linked into the system profile.
    NAUTILUS_4_EXTENSION_DIR = lib.mkForce "${config.system.path}/lib/nautilus/extensions-4";

    # Expose only package-local schemas; its whole share directory makes
    # nautilus-python discover and load the extension twice.
    XDG_DATA_DIRS = lib.mkAfter [
      "${nautilusMyComputer}/share/gsettings-schemas/${nautilusMyComputer.name}"
    ];
  };
}
