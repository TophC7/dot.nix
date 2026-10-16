# dot.nix

## Architecture (`mix.nix` API v2)

- `mix/default.nix` + `mix/hostSpec.nix`: declarative host and user specs (`desktop` defaults to `"niri"` on non-servers, `niriShell` is `"dms"` or `"pana"`, `mounts.{fast,tank,store,hold,repo}`, `vpn`, `ip`, `isServer`, `isMinimal`).
- `modules/core/`: baseline for all hosts (`modules/core/home/` auto-wires to Home Manager `sharedModules`; `modules/core/config/` auto-loads via `lib.fs.scanPaths`).
- `modules/features/<name>/`: optional modules (`nixos.nix` and/or `home.nix`) pulled in via `lib.features [ "<name>" ]`.
- `hosts/<name>/`: per-host NixOS config (`default.nix`, `hardware.nix`, `config/`) and optional `home/`.
- `specialArgs`: modules receive `{ inputs, lib, host, secrets, flakeRoot }` where `lib` is extended with `inputs.mix-nix.lib` (`lib.features`, `lib.fs.scanPaths`, etc.).

## Conventions

- **Secrets**: `mix/secrets.nix` is `git-crypt` encrypted (schema reference in `public/secrets.example.nix`). Never commit unencrypted secrets.
- **Local flake inputs**: `flake.nix` often points Toph-owned inputs (`mix-nix`, `pana`, `play`, `wayscope`, `bonk`, `sworm`, `bard`) at `git+file:///repo/...` with the remote URL commented above. Do not switch or relock them unless asked.
- **Script shebangs**: use `#!${lib.getExe pkgs.fish}` in Nix-generated scripts.
