{
  config,
  inputs,
  lib,
  ...
}:
{
  programs.ssh = {
    enable = true;
    # Avoids infinite hang if control socket connection interrupted. ex: vpn goes down/up
    serverAliveCountMax = 3;
    serverAliveInterval = 5;
    addKeysToAgent = "yes";

    extraConfig = ''
      IdentityFile ~/.ssh/pve
        UpdateHostKeys ask
    '';

    matchBlocks = {
      "git.ryot.foo" = {
        identityFile = "~/git/.ssh/git";
      };
    };
  };
}
