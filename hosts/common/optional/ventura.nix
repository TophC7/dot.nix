{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixtheplanet.nixosModules.macos-ventura
  ];

  services.macos-ventura = {
    enable = true;
    package = pkgs.makeDarwinImage { diskSizeBytes = 80000000000; };
    openFirewall = true;
    vncListenAddr = "0.0.0.0";
    autoStart = false;
    extraQemuFlags = [
      "-spice"
      "port=5930,addr=127.0.0.1,disable-ticketing"
    ];
  };
}
