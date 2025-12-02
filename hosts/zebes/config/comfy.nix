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
      glib
      glibc
      libGL
      libGLU
      ncurses5
      rocmPackages.clr
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
      xorg.libX11
      xorg.libXext
      xorg.libXfixes
      xorg.libXrender
      zlib
      zstd
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
        echo "Installing PyTorch nightly for ROCm 6.4..."
        pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.4/
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

    # Set up compiler environment for building packages
    export CC="${pkgs.gcc}/bin/gcc"
    export CXX="${pkgs.gcc}/bin/g++"
    export CMAKE_C_COMPILER="${pkgs.gcc}/bin/gcc"
    export CMAKE_CXX_COMPILER="${pkgs.gcc}/bin/g++"
    export PATH="${pkgs.gcc}/bin:${pkgs.cmake}/bin:$PATH"

    # Install missing dependencies for custom nodes
    echo "Installing custom node dependencies..."
    pip install --quiet \
        bitsandbytes \
        Cython \
        deepdiff \
        diffusers \
        docstring-parser \
        ftfy \
        gguf \
        GitPython \
        imageio-ffmpeg \
        llama-cpp-agent \
        llama-cpp-python \
        mkdocs \
        mkdocs-material \
        "mkdocstrings[python]" \
        numpy \
        opencv-contrib-python \
        opencv-python \
        piexif \
        py-cpuinfo \
        pynvml \
        simpleeval \
        timm \
        toml \
        "transformers==4.38.2" \
        uv \
        yt-dlp

    # Install insightface with proper library path and compiler path for compilation
    echo "Installing insightface..."
    PATH="${pkgs.gcc}/bin:$PATH" \
    LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH" \
        pip install --no-build-isolation insightface --quiet || \
        echo "Warning: insightface installation failed, pulid node may not work"

    # Create necessary directories
    mkdir -p "$COMFYUI_HOME"/{input,output,models,custom_nodes,user,cache}

    # Handle UV cache directory - remove if problematic and let uv recreate it
    if [ -d "$COMFYUI_HOME/cache/uv" ]; then
        # Check if we can write to it
        if ! touch "$COMFYUI_HOME/cache/uv/.test" 2>/dev/null; then
            echo "UV cache has permission issues, removing and recreating..."
            rm -rf "$COMFYUI_HOME/cache/uv" 2>/dev/null || {
                echo "Cannot remove UV cache, moving to backup..."
                mv "$COMFYUI_HOME/cache/uv" "$COMFYUI_HOME/cache/uv.backup.$(date +%s)" 2>/dev/null || true
            }
        else
            rm -f "$COMFYUI_HOME/cache/uv/.test"
        fi
    fi

    # Set UV cache environment variable to ensure it uses the right location
    export UV_CACHE_DIR="$COMFYUI_HOME/cache/uv"

    # Set library path for compilation
    export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH"

    # Set environment variables for ROCm
    export HSA_OVERRIDE_GFX_VERSION="''${HSA_OVERRIDE_GFX_VERSION:-11.0.0}"
    export HIP_VISIBLE_DEVICES="''${HIP_VISIBLE_DEVICES:-0}"
    # More aggressive memory management for AMD GPUs
    export PYTORCH_HIP_ALLOC_CONF="garbage_collection_threshold:0.6,max_split_size_mb:256"
    export PYTORCH_TUNABLEOP_ENABLED="1"
    # Force PyTorch to use less aggressive memory allocation
    export PYTORCH_CUDA_ALLOC_CONF="max_split_size_mb:256,garbage_collection_threshold:0.6"
    export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL="1"
    export CUDA_VISIBLE_DEVICES=""  # Disable CUDA
    export MIOPEN_DISABLE_CACHE="1"  # Helps with miopenStatusUnknownError
    export MIOPEN_USER_DB_PATH="$COMFYUI_HOME/cache/miopen"  # Custom MIOpen cache location

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
        --highvram \
        --use-pytorch-cross-attention \
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
    ffmpeg_8-full # Required for video processing nodes
    gcc # Required for building some Python packages
    cmake # Required for llama-cpp-python

    # ROCm tools
    rocmPackages.rocm-smi
    rocmPackages.rocminfo
  ];

  # Install fonts system-wide for ComfyUI nodes
  fonts.packages = with pkgs; [
    noto-fonts
    liberation_ttf
    dejavu_fonts
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
            ffmpeg_8-full # For video processing nodes
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
