# MACROSILICON C7 USB3.0 Video capture card — udev symlink + audio rename
{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "capture-card" ''
      exec vlc v4l2:///dev/capture-card :input-slave=alsa://hw:Video :live-caching=50 "$@"
    '')
  ];

  # Stable /dev/capture-card symlink (index 0 is the capture feed, index 1 is metadata)
  services.udev.extraRules = ''
    SUBSYSTEM=="video4linux", ATTRS{manufacturer}=="MACROSILICON", ATTRS{serial}=="15348582", ATTR{index}=="0", SYMLINK+="capture-card", TAG+="uaccess"
  '';

  # Friendly names in PipeWire/WirePlumber audio GUIs
  services.pipewire.wireplumber.extraConfig = {
    "51-capture-card-rename" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "device.name" = "~alsa_card.usb-MACROSILICON*"; } ];
          actions.update-props."device.description" = "Capture Card";
        }
        {
          matches = [ { "node.name" = "~alsa_input.usb-MACROSILICON*"; } ];
          actions.update-props."node.description" = "Capture Card";
        }
        {
          matches = [ { "node.name" = "~alsa_output.usb-MACROSILICON*"; } ];
          actions.update-props."node.description" = "Capture Card Out";
        }
      ];
    };
  };
}
