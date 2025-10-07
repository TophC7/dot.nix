{ lib, ... }:
rec {
  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;

  # Get hosts data without secrets (hosts are loaded first, have no dependencies)
  # Usage: lib.custom.getHostsData pkgs
  getHostsData =
    pkgs:
    let
      # Evaluate exactly like NixOS would (spec + implementation)
      evaluated = lib.evalModules {
        modules = [
          # Provide assertions option that evalModules expects
          { options.assertions = lib.mkOption { type = lib.types.listOf lib.types.unspecified; default = []; }; }
          # Import spec first, then implementation
          (relativeToRoot "modules/global/host-spec.nix")
          (relativeToRoot "lib/hosts.nix")
        ];
        specialArgs = {
          inherit pkgs lib;
        };
      };
    in
    evaluated.config.hostSpec;

  # Get configuration for a specific host by name
  # Usage: lib.custom.getHostConfig pkgs "nexus"
  getHostConfig =
    pkgs: hostName:
    let
      hostsData = getHostsData pkgs;
    in
    hostsData.${hostName} or null;

  # Get all host configurations
  # Usage: lib.custom.getAllHostConfigs pkgs
  getAllHostConfigs = pkgs: getHostsData pkgs;

  # Scans the given directory for NixOS modules and imports them.
  scanPaths =
    path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
          (_type == "directory") # include directories
          || (
            (path != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" path) # include .nix files
          )
        ) (builtins.readDir path)
      )
    );

  # Generate an Apprise URL for sending notifications
  # Can be called with smtp config and recipient:
  # mkAppriseUrl smtpConfig recipient
  # Or with individual parameters:
  # mkAppriseUrl { user = "user"; password = "pass"; host = "smtp.example.com"; from = "sender@example.com"; } "recipient@example.com"
  mkAppriseUrl =
    smtp: recipient:
    let
      smtpUser = if builtins.isAttrs smtp then smtp.user else smtp;
      smtpPass = if builtins.isAttrs smtp then smtp.password else recipient;
      smtpHost = if builtins.isAttrs smtp then smtp.host else "";
      smtpFrom = if builtins.isAttrs smtp then smtp.from else "";
      to = if builtins.isAttrs smtp then recipient else smtp.user;
    in
    "mailtos://_?user=${smtpUser}&pass=${smtpPass}&smtp=${smtpHost}&from=${smtpFrom}&to=${to}";

  # Get the primary monitor from a list of monitors
  # Falls back to first monitor if no primary is set
  getPrimaryMonitor =
    monitors:
    let
      primaryMonitors = builtins.filter (m: m.primary or false) monitors;
    in
    if builtins.length primaryMonitors > 0 then
      builtins.head primaryMonitors
    else if builtins.length monitors > 0 then
      builtins.head monitors
    else
      null;
}
