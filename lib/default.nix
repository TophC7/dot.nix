{ lib, ... }:
{
  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;

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
}
