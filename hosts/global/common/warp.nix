{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    cloudflare-warp
    gnomeExtensions.cloudflare-warp-toggle # QS toggle
  ];

  systemd = {
    packages = [ pkgs.cloudflare-warp ];
    targets.multi-user.wants = [ "warp-svc.service" ]; # Autostart Warp service
  };
}
