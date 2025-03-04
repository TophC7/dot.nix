{
  description = "Minimal NixOS configuration for bootstrapping systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      # NOTE: Change when installing, hacky but whatever
      username = "toph";
      ARM = "aarch64-linux"; # ARM systems
      X86 = "x86_64-linux"; # x86_64 systems

      minimalSpecialArgs = {
        inherit inputs outputs;
        lib = nixpkgs.lib.extend (
          self: super: { custom = import /home/${username}/git/dot.nix/lib { inherit (nixpkgs) lib; }; }
        );
      };

      # This mkHost is way better: https://github.com/linyinfeng/dotfiles/blob/8785bdb188504cfda3daae9c3f70a6935e35c4df/flake/hosts.nix#L358
      newConfig =
        name: system:
        (nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = minimalSpecialArgs;
          modules = [
            ./minimal-configuration.nix
            /home/${username}/git/dot.nix/hosts/nixos/${name}/hardware.nix
            { networking.hostName = name; }
          ];
        });
    in
    {
      nixosConfigurations = {
        # host = newConfig "name"
        vm = newConfig "vm" X86;
        rune = newConfig "rune" X86;
      };
    };
}
