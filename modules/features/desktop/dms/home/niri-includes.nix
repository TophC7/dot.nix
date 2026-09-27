{ lib, ... }:
let
  includeOrder = [
    "alttab"
    "binds"
    "colors"
    "cursor"
    "layout"
    "outputs"
    "windowrules"
    "wpblur"
  ];

  ensureFile = name: ''
    if [ ! -f "$HOME/.config/niri/dms/${name}.kdl" ]; then
      touch "$HOME/.config/niri/dms/${name}.kdl"
    fi
  '';
in
{
  home.activation.createDmsNiriIncludes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/niri/dms"
    ${lib.concatMapStringsSep "\n" ensureFile includeOrder}
  '';
}
