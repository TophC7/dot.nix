{ lib, ... }:
{
  # Bridge configuration with explicit network settings to prevent connectivity loss
  networking = {
    # Disable NetworkManager (conflicts with manual bridge config)
    networkmanager.enable = lib.mkForce false;
    # Create the bridge
    bridges.br0 = {
      interfaces = [
        "enp34s0" # Main NIC
        "enp37s0" # 4-port NIC port 1
        "enp38s0" # 4-port NIC port 2
        "enp39s0" # 4-port NIC port 3
        "enp40s0" # 4-port NIC port 4
      ];
    };

    # Explicitly configure the bridge with nimbus's current network settings
    interfaces.br0 = {
      useDHCP = false; # Don't use DHCP
      ipv4.addresses = [
        {
          address = "10.2.2.2"; # Nimbus's static IP
          prefixLength = 24;
        }
      ];
    };

    # Set the default gateway
    defaultGateway = {
      address = "10.2.2.1"; # Router's IP
      interface = "br0";
    };

    # Set DNS servers
    nameservers = [
      "10.2.2.1"
    ];

    # Disable DHCP on the physical interface
    interfaces.enp34s0.useDHCP = false;
  };

  # Ensure the bridge module is loaded
  boot.kernelModules = [ "bridge" ];
}
