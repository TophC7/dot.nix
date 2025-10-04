{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfgWg = config.secretsSpec.network.${config.hostSpec.hostName}.wg or null;
  nexusPublicKey = config.secretsSpec.network.nexus.wg.publicKey;
in
{
  config = lib.mkIf (cfgWg != null) {
    # WireGuard VPN for homelab network access
    networking.wg-quick.interfaces.wg-homelab = {
      autostart = true;
      address = [ cfgWg.address ];
      dns = [
        "10.100.0.1"
      ];
      # Configure search domains (handle both systemd-resolved and traditional resolvconf)
      postUp = ''
        # Try systemd-resolved first (modern systems)
        if ${pkgs.systemd}/bin/systemctl is-active --quiet systemd-resolved; then
          ${pkgs.systemd}/bin/resolvectl domain wg-homelab "~ryot.local" "~ryot.foo" || true
        # Fall back to traditional resolvconf
        elif [ -x /run/current-system/sw/bin/resolvconf ]; then
          echo "search ryot.local ryot.foo" | /run/current-system/sw/bin/resolvconf -a wg-homelab.dns -m 0 || true
        fi
      '';
      postDown = ''
        # Clean up resolvconf entry if it was added
        if [ -x /run/current-system/sw/bin/resolvconf ]; then
          /run/current-system/sw/bin/resolvconf -d wg-homelab.dns 2>/dev/null || true
        fi
      '';
      privateKey = cfgWg.privateKey;
      peers = [
        {
          publicKey = nexusPublicKey;
          endpoint = cfgWg.endpoint;
          allowedIPs = [
            "10.100.0.0/24" # VPN subnet (includes DNS at 10.100.0.1)
            "104.40.1.0/24" # Pangolin network
            "104.40.2.0/24" # NIMBUS network
            "104.40.3.0/24" # ZEBES network
            "104.40.4.0/24" # RUNE network
            "13.19.89.0/24" # HAZE network
          ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
