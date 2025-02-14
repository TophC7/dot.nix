{
  config,
  pkgs,
  admin,
  ...
}:
{

  # Enable dconf (System Management Tool)
  programs.dconf.enable = true;

  # Add user to libvirtd group
  users.users.${admin}.extraGroups = [ "libvirtd" ];

  # Install necessary packages
  environment.systemPackages = with pkgs; [
    qemu
    qemu_kvm
    spice
    spice-gtk
    spice-protocol
    virtiofsd
    win-spice
    win-virtio
  ];

  networking.firewall = {
    allowedTCPPortRanges = [
      # spice
      {
        from = 5900;
        to = 5999;
      }
    ];
    allowedTCPPorts = [
      # libvirt
      16509
    ];
  };

  programs.virt-manager.enable = true;
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = true;
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = with pkgs; [ OVMFFull.fd ];
        vhostUserPackages = with pkgs; [ virtiofsd ];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  services.spice-vdagentd.enable = true;
}
