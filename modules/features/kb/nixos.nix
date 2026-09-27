{ pkgs, ... }:
{
  # Allows vial to identify the keyboard
  services.udev.packages = with pkgs; [
    via
    nrf-udev
    stlink
  ];

  services.udev.extraRules = ''
    # ZMK Keyboards - accessible by ryot group
    SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{idProduct}=="615e", MODE="0660", GROUP="ryot"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="615e", MODE="0660", GROUP="ryot"

    # Nice!Nano bootloader (Adafruit)
    SUBSYSTEM=="usb", ATTR{idVendor}=="239a", MODE="0660", GROUP="ryot"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="239a", MODE="0660", GROUP="ryot"

    # Nordic Semiconductor (nRF52)
    SUBSYSTEM=="usb", ATTR{idVendor}=="1915", MODE="0660", GROUP="ryot"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1915", MODE="0660", GROUP="ryot"

    # Serial/TTY devices for bootloader programming
    KERNEL=="ttyACM*", ATTRS{idVendor}=="1d50", MODE="0660", GROUP="ryot"
    KERNEL=="ttyACM*", ATTRS{idVendor}=="239a", MODE="0660", GROUP="ryot"
    KERNEL=="ttyUSB*", ATTRS{idVendor}=="1d50", MODE="0660", GROUP="ryot"

    # UF2 mass storage bootloaders
    KERNEL=="sd*", SUBSYSTEMS=="usb", ATTRS{idVendor}=="239a", MODE="0660", GROUP="ryot"
    KERNEL=="sd*", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1915", MODE="0660", GROUP="ryot"

    # HID raw devices
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1d50", MODE="0660", GROUP="ryot"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="239a", MODE="0660", GROUP="ryot"
  '';
}
