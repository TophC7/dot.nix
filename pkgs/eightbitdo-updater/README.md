# 8BitDo Updater

Windows firmware updater for 8BitDo controllers, running under Wine.

## Required udev Rules

For the updater to communicate with 8BitDo controllers, the following udev rules must be added to your system configuration:

```nix
services.udev.extraRules = ''
  # 8BitDo boot HID interface (bootloader mode - shared across multiple 8BitDo devices)
  # This interface is exposed when the device is in manual update mode
  SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2dc8", ATTRS{idProduct}=="3208", TAG+="uaccess"

  # 8BitDo Ultimate 2 Controller - HID interface
  # Allows the updater tool to detect and automatically put the controller in bootloader mode
  SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2dc8", ATTRS{idProduct}=="310b", TAG+="uaccess"
'';
```

### Product IDs

- `3208`: Boot HID interface (bootloader/manual update mode - shared across 8BitDo devices)
- `310b`: 8BitDo Ultimate 2 Controller (normal mode)

Without these rules, the Wine-based updater cannot access the HID interface required for firmware updates.

## Usage

1. Add the udev rules to your NixOS configuration
2. Rebuild your system
3. Connect your controller via USB
4. For manual update mode: Hold LB+RB while connecting
5. Run `8bitdo-updater`