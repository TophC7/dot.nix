# Host-specific audio device renaming for rune
_: {
  services.pipewire.wireplumber.extraConfig = {
    "50-device-rename" = {
      "monitor.alsa.rules" = [
        # Family 17h/19h/1ah HD Audio Controller → Beyerdynamic
        {
          matches = [ { "device.name" = "alsa_card.pci-0000_13_00.6"; } ];
          actions.update-props."device.description" = "Beyerdynamic";
        }
        {
          matches = [ { "node.name" = "~alsa_output.pci-0000_13_00.6*"; } ];
          actions.update-props."node.description" = "Beyerdynamic";
        }
        {
          matches = [ { "node.name" = "~alsa_input.pci-0000_13_00.6*"; } ];
          actions.update-props."node.description" = "Beyerdynamic Mic";
        }

        # Navi 48 HDMI/DP Audio Controller → ROG
        {
          matches = [ { "device.name" = "alsa_card.pci-0000_03_00.1"; } ];
          actions.update-props."device.description" = "ROG";
        }
        {
          matches = [ { "node.name" = "~alsa_output.pci-0000_03_00.1*"; } ];
          actions.update-props."node.description" = "ROG";
        }

        # Radeon HD Audio [Rembrandt/Strix] → HDMI
        # TODO: Get exact PCI address with: wpctl inspect 53 | grep device.name
        {
          matches = [ { "device.name" = "~alsa_card.pci-0000_*_00.1"; } ];
          actions.update-props."device.description" = "HDMI";
        }
        {
          matches = [ { "node.name" = "~alsa_output.pci-0000_*_00.1*"; } ];
          actions.update-props."node.description" = "HDMI";
        }
      ];
    };
  };
}
