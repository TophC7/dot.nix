{
  config,
  lib,
  pkgs,
  ...
}:

let
  python = pkgs.python312;

  # Library dependencies needed at runtime
  libPath = lib.makeLibraryPath (
    with pkgs;
    [
      gcc-unwrapped.lib
      glibc
      zstd
      zlib
      libGL
      libGLU
      glib
      ncurses5
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libXfixes
      rocmPackages.rocm-runtime
      rocmPackages.clr
      rocmPackages.clr.icd
    ]
  );

  # Create a wrapper script with all dependencies available
  # NOTE: Using Bash instead of Fish because Python venv activation requires Bash/POSIX shell
  comfyuiScript = pkgs.writeShellScript "comfyui-start" ''
    #!${pkgs.bash}/bin/bash
    set -e

    COMFYUI_HOME="''${COMFYUI_HOME:-/store/comfyui}"
    COMFYUI_VERSION="''${COMFYUI_VERSION:-v0.3.57}"

    cd "$COMFYUI_HOME"

    # Create virtual environment if it doesn't exist
    if [ ! -d "$COMFYUI_HOME/venv" ]; then
        echo "Creating Python virtual environment..."
        ${python}/bin/python3.12 -m venv "$COMFYUI_HOME/venv"
    fi

    # Activate virtual environment
    source "$COMFYUI_HOME/venv/bin/activate"

    # Set library paths AFTER activating venv (venv activation can reset these)
    export LD_LIBRARY_PATH="${libPath}:''${LD_LIBRARY_PATH:-}"

    # Upgrade pip
    pip install --upgrade pip --quiet

    # Install/upgrade PyTorch for ROCm if needed
    if ! python -c "import torch" 2>/dev/null || [ "''${FORCE_REINSTALL:-0}" = "1" ]; then
        echo "Installing PyTorch for ROCm..."
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.3
    fi

    # Clone/update ComfyUI if needed
    if [ ! -f "$COMFYUI_HOME/main.py" ]; then
        echo "Downloading ComfyUI ''${COMFYUI_VERSION}..."
        ${pkgs.git}/bin/git clone https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI_HOME/temp"
        cd "$COMFYUI_HOME/temp"
        ${pkgs.git}/bin/git checkout "''${COMFYUI_VERSION}"
        cp -r ./* "$COMFYUI_HOME/"
        cd "$COMFYUI_HOME"
        rm -rf "$COMFYUI_HOME/temp"
    fi

    # Install ComfyUI requirements
    if [ -f "$COMFYUI_HOME/requirements.txt" ]; then
        echo "Installing ComfyUI requirements..."
        pip install -r requirements.txt --quiet
    fi

    # Install missing dependencies for custom nodes
    echo "Installing custom node dependencies..."
    pip install --quiet \
        piexif \
        deepdiff \
        yt-dlp \
        gguf \
        imageio-ffmpeg

    # Create necessary directories
    mkdir -p "$COMFYUI_HOME"/{input,output,models,custom_nodes,user,cache}
    
    # Fix UV cache permissions if it exists
    if [ -d "$COMFYUI_HOME/cache/uv" ]; then
        chmod -R u+rw "$COMFYUI_HOME/cache/uv" || true
    fi

    # Set environment variables for ROCm
    export HSA_OVERRIDE_GFX_VERSION="''${HSA_OVERRIDE_GFX_VERSION:-11.0.0}"
    export HIP_VISIBLE_DEVICES="''${HIP_VISIBLE_DEVICES:-0}"
    export PYTORCH_HIP_ALLOC_CONF="expandable_segments:True"
    export PYTORCH_TUNABLEOP_ENABLED="1"
    export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL="1"
    export CUDA_VISIBLE_DEVICES=""  # Disable CUDA

    # Set ComfyUI paths
    export COMFYUI_MODEL_PATH="$COMFYUI_HOME/models"
    export COMFYUI_INPUT_PATH="$COMFYUI_HOME/input"
    export COMFYUI_OUTPUT_PATH="$COMFYUI_HOME/output"
    export HOME="$COMFYUI_HOME"
    export XDG_CACHE_HOME="$COMFYUI_HOME/cache"

    echo "Starting ComfyUI..."
    exec python main.py \
        --listen "''${COMFYUI_HOST:-0.0.0.0}" \
        --port "''${COMFYUI_PORT:-8188}" \
        --use-pytorch-cross-attention \
        --highvram \
        "$@"
  '';
in
{
  # System packages - these will be available globally
  environment.systemPackages = with pkgs; [
    python312
    python312Packages.pip
    python312Packages.virtualenv
    git
    ffmpeg  # Required for video processing nodes

    # ROCm tools
    rocmPackages.rocm-smi
    rocmPackages.rocminfo
  ];

  # Enable AMD GPU support
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
      rocmPackages.rocm-smi
    ];
  };

  # Ensure directories exist (owned by uid 1000, gid 1004)
  systemd.tmpfiles.rules = [
    "d /store/comfyui 0755 1000 1004 -"
    "d /store/comfyui/input 0755 1000 1004 -"
    "d /store/comfyui/output 0755 1000 1004 -"
    "d /store/comfyui/models 0755 1000 1004 -"
    "d /store/comfyui/custom_nodes 0755 1000 1004 -"
    "d /store/comfyui/user 0755 1000 1004 -"
    "d /store/comfyui/cache 0755 1000 1004 -"
    "d /store/comfyui/temp 0755 1000 1004 -"
  ];

  # Simple systemd service
  systemd.services.comfyui = {
    description = "ComfyUI - Stable Diffusion GUI";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "1000";
      Group = "1004"; # ryot
      WorkingDirectory = "/store/comfyui";

      # Use our Nix-provided script
      ExecStart = "${comfyuiScript}";

      # Restart on failure
      Restart = "on-failure";
      RestartSec = "10s";

      # Memory limits
      MemoryMax = "32G";
      MemorySwapMax = "8G";

      # Security settings - more permissive for dynamic Python env
      PrivateTmp = false; # Allow access to /tmp for pip
      ProtectSystem = false; # Allow pip to install packages
      ProtectHome = false; # User might need home access
      ReadWritePaths = [ "/store/comfyui" ];
    };

    environment = {
      PATH = lib.mkForce (
        lib.makeBinPath (
          with pkgs;
          [
            coreutils
            findutils
            gnugrep
            gnused
            systemd
            git # Critical for ComfyUI-Manager
            python312
            bash
            ffmpeg # For video processing nodes
          ]
        )
      );

      LD_LIBRARY_PATH = libPath;

      GIT_PYTHON_GIT_EXECUTABLE = "${pkgs.git}/bin/git";
      PYTHONUNBUFFERED = "1";

      COMFYUI_HOME = "/store/comfyui";
      COMFYUI_HOST = "0.0.0.0";
      COMFYUI_PORT = "8188";

      # ROCm configuration
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";
      HIP_VISIBLE_DEVICES = "0";
    };
  };
}
