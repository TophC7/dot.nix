_: {
  xdg.desktopEntries = {
    nixvm = {
      name = "NixOS VM";
      comment = "Testing VM";
      exec = ''fish -c "sudo virsh start nixos; remmina -c (sudo virsh -q domdisplay nixos)"'';
      icon = "nix-snowflake";
      type = "Application";
      terminal = false;
      categories = [
        "System"
        "Application"
      ];
    };

    win11 = {
      name = "Windows 11";
      comment = "Windows 11 VM";
      exec = ''fish -c "sudo virsh start win11; remmina -c (sudo virsh -q domdisplay win11)"'';
      icon = "windows95";
      type = "Application";
      terminal = false;
      categories = [
        "System"
        "Application"
      ];
    };

    code = {
      name = "Visual Studio Code";
      comment = "Code Editing. Redefined.";
      exec = "code %F";
      icon = "vscode";
      type = "Application";
      terminal = false;
      startupNotify = true;
      genericName = "Text Editor";
      categories = [
        "Utility"
        "TextEditor"
        "Development"
        "IDE"
      ];
      mimeType = [
        "text/plain"
        "inode/directory"
      ];
      actions = {
        new-empty-window = {
          name = "New Empty Window";
          exec = "code --new-window %F";
          icon = "vscode";
        };
        code-x11 = {
          name = "Code - X11";
          exec = "code --ozone-platform=x11 %F";
          icon = "vscode";
        };
      };
    };
  };
}
