let
  publicKey = ""; # Add a key for passwordless SSH access.
in
{
  users.nixos = {
    hashedPassword = "$6$rounds=656000$5ehID8CrGOgiG4Ms$MiS68cPnrREv1URzlCcyFnJntVhWMKAnY7ZNaEvgEG36vV1KBnQHyv6HkPmOeh8aGOljYOR0aWFg.irg6ahT3."; # nixos
    email = "admin@localhost";
    handle = "nixos";
    fullName = "NixOS Live User";
    ssh.publicKeys = if publicKey == "" then [ ] else [ publicKey ];
  };
}
