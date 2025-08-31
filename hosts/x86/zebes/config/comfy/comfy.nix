{
  pkgs,
  lib,
  config,
  ...
}:
let
  # Based on comfyui-nix-devshell implementation
  # Adapted for NixOS service configuration with ROCm support

  python = pkgs.python312;

  # ROCm hardware dependencies for AMD GPUs
  hardware_deps = with pkgs; [
    rocmPackages.clr.icd
    rocmPackages.rocblas
    rocmPackages.hipblas
    rocmPackages.clr
  ];

  # ComfyUI Python environment
  comfyuiEnv = python.withPackages (
    ps: with ps; [
      pip
      virtualenv
      setuptools
      wheel
    ]
  );

  # Build tools and system dependencies
  systemDeps = with pkgs; [
    git
    git-lfs
    autoconf
    gnumake
    clinfo
    rocminfo
    imagemagick
    ffmpeg-full
    wget
    aria2
  ];
in
{
  # ROCm setup for AMD GPUs
  hardware.graphics.extraPackages = hardware_deps;

  # ROCm symlinks for compatibility
  systemd.tmpfiles.rules = [
    "L+ /opt/rocm - - - - ${pkgs.rocmPackages.clr}"
    # Model and output directories
    "d /store/comfyui 0755 toph users -"
    "d /store/ai-models 0755 toph users -"
    "d /store/ai-models/checkpoints 0755 toph users -"
    "d /store/ai-models/loras 0755 toph users -"
    "d /store/ai-models/vae 0755 toph users -"
    "d /store/ai-models/controlnet 0755 toph users -"
    "d /store/ai-models/clip 0755 toph users -"
    "d /store/ai-models/clip_vision 0755 toph users -"
    "d /store/ai-models/embeddings 0755 toph users -"
    "d /store/ai-outputs 0755 toph users -"
  ];

  # Environment variables for ROCm
  environment.variables = {
    # AMD GPU architecture - adjust based on your GPU
    PYTORCH_ROCM_ARCH = "gfx1100"; # RX 7000 series
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";

    # Performance optimizations
    TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL = "1";
    PYTORCH_TUNABLEOP_ENABLED = "1";

    # ComfyUI paths
    COMFYUI_MODEL_PATH = "/store/ai-models";
    HF_HOME = "/store/ai-models/huggingface";
  };

  # Install system packages
  environment.systemPackages = systemDeps ++ [ comfyuiEnv ];

  # ComfyUI systemd service
  systemd.services.comfyui = {
    description = "ComfyUI - Stable Diffusion Web UI";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    path = systemDeps ++ hardware_deps ++ [ comfyuiEnv ];

    environment = {
      LD_LIBRARY_PATH = lib.makeLibraryPath hardware_deps;
      PYTHONPATH = ""; # Clean Python path
      HOME = "/store/comfyui";
    };

    serviceConfig = {
      Type = "simple";
      User = "toph";
      Group = "users";
      WorkingDirectory = "/store/comfyui";
      StateDirectory = "comfyui";

      # Setup script that runs before starting
      ExecStartPre = pkgs.writeShellScript "comfyui-setup" ''
        set -e

        # Clone ComfyUI if not present
        if [ ! -d /store/comfyui/ComfyUI ]; then
          echo "Cloning ComfyUI..."
          ${pkgs.git}/bin/git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /store/comfyui/ComfyUI
        else
          echo "Updating ComfyUI..."
          cd /store/comfyui/ComfyUI
          ${pkgs.git}/bin/git pull || true
        fi

        cd /store/comfyui/ComfyUI

        # Setup Python virtual environment
        if [ ! -d .venv ]; then
          echo "Creating virtual environment..."
          ${comfyuiEnv}/bin/python -m venv .venv
        fi

        # Activate venv and install/update dependencies
        source .venv/bin/activate

        echo "Upgrading pip..."
        pip install --upgrade pip setuptools wheel

        echo "Installing PyTorch with ROCm support..."
        # Install PyTorch with ROCm 6.1 (stable version)
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1

        echo "Installing ComfyUI requirements..."
        # Install other requirements (filtering out torch to avoid conflicts)
        if [ -f requirements.txt ]; then
          grep -v "^torch" requirements.txt > requirements-filtered.txt || true
          if [ -s requirements-filtered.txt ]; then
            pip install -r requirements-filtered.txt
          fi
        fi

        # Create model directory symlinks
        echo "Setting up model directories..."
        for dir in checkpoints loras vae controlnet clip clip_vision embeddings; do
          if [ ! -e models/$dir ]; then
            ln -sfn /store/ai-models/$dir models/$dir
          fi
        done

        # Link output directory
        if [ ! -e output ]; then
          ln -sfn /store/ai-outputs output
        fi
      '';

      # Main execution script
      ExecStart = pkgs.writeShellScript "comfyui-start" ''
        cd /store/comfyui/ComfyUI
        source .venv/bin/activate

        echo "Starting ComfyUI..."
        exec python main.py \
          --listen 0.0.0.0 \
          --port 8188 \
          --use-pytorch-cross-attention \
          --preview-method auto
      '';

      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        "/store/comfyui"
        "/store/ai-models"
        "/store/ai-outputs"
      ];
      NoNewPrivileges = true;
    };
  };

  # Open firewall for ComfyUI
  networking.firewall.allowedTCPPorts = [ 8188 ];

  # Optional: ComfyUI Manager for easy extension management
  systemd.services.comfyui-manager-install = {
    description = "Install ComfyUI Manager";
    after = [ "comfyui.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "toph";
      Group = "users";
      ExecStart = pkgs.writeShellScript "install-manager" ''
        if [ ! -d /store/comfyui/ComfyUI/custom_nodes/ComfyUI-Manager ]; then
          cd /store/comfyui/ComfyUI/custom_nodes
          ${pkgs.git}/bin/git clone https://github.com/ltdrdata/ComfyUI-Manager.git
        fi
      '';
    };
  };
}
