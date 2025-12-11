{
  config,
  lib,
  pkgs,
  ...
}:

let
  comfyHome = "/store/comfyui";
  comfyVersion = "v0.3.76";

  # All runtime libraries needed by PyTorch and other compiled Python packages
  libPath = lib.makeLibraryPath (
    with pkgs;
    [
      stdenv.cc.cc.lib # libstdc++.so.6
      glib
      glibc
      libGL
      libGLU
      ncurses5
      zlib
      zstd
      xorg.libX11
      xorg.libXext
      xorg.libXfixes
      xorg.libXrender
      rocmPackages.clr
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
    ]
  );

  # Startup script (Bash required for venv activation)
  comfyScript = pkgs.writeShellScript "comfyui-start" ''
    set -e
    cd "${comfyHome}"

    # Set library path before anything else
    export LD_LIBRARY_PATH="${libPath}:''${LD_LIBRARY_PATH:-}"

    # Initialize venv if needed
    if [ ! -d "${comfyHome}/venv" ]; then
      echo "Creating Python virtual environment..."
      ${pkgs.python312}/bin/python3 -m venv "${comfyHome}/venv"
    fi

    source "${comfyHome}/venv/bin/activate"

    # Re-export after venv activation (it can reset LD_LIBRARY_PATH)
    export LD_LIBRARY_PATH="${libPath}:''${LD_LIBRARY_PATH:-}"

    # Use venv's pip (not Nix's, which has PEP 668 protection)
    pip install --upgrade pip --quiet

    # Install PyTorch for ROCm if missing
    if ! python -c "import torch" 2>/dev/null || [ "''${FORCE_REINSTALL:-0}" = "1" ]; then
      echo "Installing PyTorch nightly for ROCm 6.4..."
      pip install --pre torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/nightly/rocm6.4/
    fi

    # Clone ComfyUI if missing
    if [ ! -d "${comfyHome}/.git" ]; then
      echo "Downloading ComfyUI ${comfyVersion}..."
      # Clone to temp, then move everything including .git
      ${pkgs.git}/bin/git clone https://github.com/comfyanonymous/ComfyUI.git "${comfyHome}/temp"
      cd "${comfyHome}/temp" && ${pkgs.git}/bin/git checkout "${comfyVersion}"
      shopt -s dotglob  # Include hidden files in glob
      cp -r "${comfyHome}/temp"/* "${comfyHome}/"
      shopt -u dotglob
      rm -rf "${comfyHome}/temp"
    fi

    # Install requirements
    [ -f requirements.txt ] && pip install -r requirements.txt --quiet

    # Build tools for compiling packages like insightface
    export CC="${pkgs.gcc}/bin/gcc"
    export CXX="${pkgs.gcc}/bin/g++"
    export PATH="${pkgs.gcc}/bin:${pkgs.cmake}/bin:$PATH"

    # Install common custom node dependencies
    pip install --quiet \
      bitsandbytes Cython deepdiff diffusers docstring-parser ftfy gguf \
      GitPython imageio-ffmpeg llama-cpp-agent llama-cpp-python \
      mkdocs mkdocs-material "mkdocstrings[python]" numpy \
      opencv-contrib-python opencv-python piexif py-cpuinfo pynvml \
      simpleeval timm toml "transformers==4.38.2" uv yt-dlp

    # insightface needs special handling
    pip install --no-build-isolation insightface --quiet 2>/dev/null || \
      echo "Warning: insightface installation failed (pulid node may not work)"

    echo "Starting ComfyUI..."
    exec python main.py \
      --listen "''${COMFYUI_HOST:-0.0.0.0}" \
      --port "''${COMFYUI_PORT:-8188}" \
      --reserve-vram 0.5 \
      --lowvram \
      --use-pytorch-cross-attention \
      --disable-xformers \
      --bf16-unet \
      --fast \
      "$@"
  '';
in
{
  # System packages for debugging/monitoring
  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
    rocmPackages.rocminfo
  ];

  # Fonts for ComfyUI text nodes
  fonts.packages = with pkgs; [
    noto-fonts
    liberation_ttf
    dejavu_fonts
  ];

  # AMD GPU support
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr
      rocmPackages.clr.icd
      rocmPackages.rocm-runtime
      rocmPackages.rocm-smi
    ];
  };

  # Directory structure
  systemd.tmpfiles.rules = [
    "d ${comfyHome} 0755 1000 1004 -"
    "d ${comfyHome}/input 0755 1000 1004 -"
    "d ${comfyHome}/output 0755 1000 1004 -"
    "d ${comfyHome}/models 0755 1000 1004 -"
    "d ${comfyHome}/custom_nodes 0755 1000 1004 -"
    "d ${comfyHome}/user 0755 1000 1004 -"
    "d ${comfyHome}/cache 0755 1000 1004 -"
  ];

  systemd.services.comfyui = {
    description = "ComfyUI - Stable Diffusion GUI";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    path = with pkgs; [
      coreutils
      findutils
      gnugrep
      gnused
      git
      python312
      bash
      ffmpeg_8-full
      gcc
      cmake
    ];

    serviceConfig = {
      Type = "simple";
      User = "1000";
      Group = "1004";
      WorkingDirectory = comfyHome;
      ExecStart = "${comfyScript}";

      Restart = "on-failure";
      RestartSec = "10s";

      MemoryMax = "32G";
      MemorySwapMax = "8G";

      PrivateTmp = false;
      ProtectSystem = false;
      ProtectHome = false;
      ReadWritePaths = [ comfyHome ];
    };

    environment = {
      LD_LIBRARY_PATH = libPath;

      # ROCm configuration
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";
      HIP_VISIBLE_DEVICES = "0";
      CUDA_VISIBLE_DEVICES = "";

      # Memory management
      PYTORCH_HIP_ALLOC_CONF = "garbage_collection_threshold:0.6,max_split_size_mb:256";
      PYTORCH_CUDA_ALLOC_CONF = "max_split_size_mb:256,garbage_collection_threshold:0.6";
      PYTORCH_TUNABLEOP_ENABLED = "1";
      TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL = "1";

      # MIOpen settings
      MIOPEN_DISABLE_CACHE = "1";
      MIOPEN_USER_DB_PATH = "${comfyHome}/cache/miopen";

      # Paths
      HOME = comfyHome;
      XDG_CACHE_HOME = "${comfyHome}/cache";
      UV_CACHE_DIR = "${comfyHome}/cache/uv";
      COMFYUI_MODEL_PATH = "${comfyHome}/models";
      COMFYUI_INPUT_PATH = "${comfyHome}/input";
      COMFYUI_OUTPUT_PATH = "${comfyHome}/output";

      # Service settings
      PYTHONUNBUFFERED = "1";
      GIT_PYTHON_GIT_EXECUTABLE = "${pkgs.git}/bin/git";
      COMFYUI_HOST = "0.0.0.0";
      COMFYUI_PORT = "8188";
    };
  };
}
