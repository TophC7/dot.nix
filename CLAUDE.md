# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is Toph's NixOS & Home Manager configuration repository (dot.nix) - a modular, multi-user/host configuration using Nix flakes. The repository manages multiple systems across x86_64 and aarch64 architectures with a focus on reproducibility and modularity.

## Common Development Commands

### Flake Commands
```bash
# Check configuration validity
nix flake check

# Build specific host configuration
nix build .#nixosConfigurations.hostname.config.system.build.toplevel

# Enter development shell
nix develop

# Update flake inputs
nix flake update

# Show flake outputs
nix flake show
```

### Testing Changes
Always verify configurations before applying:
1. Run `nix flake check` to validate syntax
2. Build the configuration without switching to test
3. Check generated scripts in `/nix/store/` when debugging runtime behavior

## Architecture and Structure

### Layered Configuration System
1. **Global Core** (`hosts/global/core/`): Essential settings for all hosts
2. **Global Common** (`hosts/global/common/`): Optional shared features
3. **Host-Specific** (`hosts/{x86,arm}/<hostname>/`): Per-host configurations
4. **User Environments** (`home/`): Home Manager configurations

### Host Configuration Pattern
Each host configuration is located at `hosts/{x86,arm}/<hostname>/default.nix` and uses a standardized specification:
```nix
{
  hostname = "example";
  username = "toph";
  email = "email@domain.com";
  desktop = "gnome";  # or false for servers
  isARM = false;
  isServer = false;
  isMinimal = false;
}
```

### Directory Structure
```
hosts/
├── x86/          # Intel/AMD 64-bit systems
│   ├── rune/
│   │   ├── default.nix    # Host specification
│   │   ├── hardware.nix   # Hardware configuration
│   │   └── config/        # Optional service configs
│   └── ...
├── arm/          # ARM64 systems
│   └── caenus/
└── global/       # Shared configurations
    ├── core/     # Essential modules
    └── common/   # Optional features
```

## Development Guidelines

### NixOS Development Principles
- Understand the distinction between build-time (Nix evaluation) and runtime behavior
- Configuration precedence: wrapper-specific → global defaults → system defaults
- Always consider: "Is this a Nix configuration issue or a runtime script issue?"
- Modular design: each component should handle its specific concerns cleanly
- Test configuration changes with `nix flake check` before explaining solutions
- Respect existing working patterns - don't "fix" what isn't broken
- When extending functionality and refactoring is not the current goal, maintain backward compatibility

### Shell Script Requirements
- Prioritize Fish shell usage unless explicitly stated otherwise
- For shebangs, use `#!${lib.getExe pkgs.fish}` instead of hardcoded paths
- ALL shell commands, examples, and testing instructions MUST use Fish syntax
- Avoid Bash/sh unless necessary, and explain why if required

### Debugging Protocol
- ALWAYS verify the current state before proposing changes
- Trace data flow: Nix evaluation → runtime execution → actual behavior
- When reporting issues, analyze: error messages, generated scripts, command output
- Before "fixing" anything, confirm the root cause, not just symptoms
- Use tools to examine actual generated scripts and runtime behavior
- If multiple issues appear related, prioritize understanding the fundamental architecture

### Code Standards
- Follow Nix language standards and conventions strictly
- Prioritize "the Nix way" - alternative solutions need clear advantages
- Simplify configurations and make them modular for future extensions
- Ensure compatibility with key applications: Docker, NFS, Borg, Snapraid, Cloudflared, Adguard
- Desktop environments: GNOME, Gamescope, Steam integration

## Key Technologies and Integrations

### Storage and Backup Systems
- **MergerFS**: Centralized storage pool at `/pool`
- **SnapRAID**: Parity-based data protection
- **BorgBackup**: Automated backups with Apprise notifications
- **NFS**: Network file sharing across hosts

### Container Management
- **Docker**: Primary container runtime
- **Komodo**: Web UI for Docker stack management
- **compose2nix**: Convert Docker Compose files to NixOS service
- **Pangolin**: Reverse proxy management

### Gaming Configuration
- **Steam**: With Proton and GameMode integration
- **Gamescope**: Compositor for gaming
- **Emulator Save Backups**: Automated with inotify
- **AMD GPU Support**: Using LACT for hardware control

### Security Features
- **git-crypt**: For secrets management
- **ACME**: Let's Encrypt certificates with DNS challenges
- **Cloudflare Tunnels**: Zero trust access
- **SSH Key Management**: Automated deployment

## Repository-Specific Patterns

### Custom Library Functions
Located in `lib/default.nix`:
- `relativeToRoot`: Path management relative to project root
- `scanPaths`: Automatic NixOS module discovery and importing
- `mkAppriseUrl`: Notification URL generation for monitoring
- `getPrimaryMonitor`: Monitor configuration helpers

### Package Overlay System
Custom packages in `pkgs/` are automatically available. Notable packages:
- `borgtui`: Terminal UI for Borg backups
- `journey`: Package management utility
- `microsoft-edit`: Patched Microsoft editor
- `snapraid-runner`: SnapRAID automation

### Environment Variables
- `FLAKE`: Automatically set to repository path in dev shell

## Important Notes

1. **Encrypted Secrets**: The `secrets.nix` file uses git-crypt - do not commit unencrypted secrets
2. **Multi-Architecture**: Always consider both x86_64 and aarch64 when making changes
3. **Host Discovery**: New hosts are automatically detected when added to `hosts/{x86,arm}/`
4. **User Theming**: Stylix integration provides consistent theming across all applications
5. **Service Dependencies**: Many services depend on the storage pool - ensure `/pool` is available

## Troubleshooting

When debugging issues:
1. Check generated wrapper scripts in `/nix/store/`
2. Verify environment variables AND command-line arguments
3. Consider nested execution contexts (e.g., gamescope sessions)
4. Use `journalctl -xeu service-name` for systemd service logs
5. For Docker services, check both NixOS service and container logs