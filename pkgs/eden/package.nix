# Based on https://github.com/Grantimatter/eden-flake/blob/main/package.nix
{
  lib,
  stdenv,
  cmake,
  openssl,
  boost,
  fmt_11,
  nlohmann_json,
  lz4,
  zlib,
  zstd,
  enet,
  libopus,
  vulkan-headers,
  vulkan-utility-libraries,
  spirv-tools,
  spirv-headers,
  simpleini,
  discord-rpc,
  cubeb,
  vulkan-memory-allocator,
  vulkan-loader,
  libusb1,
  pkg-config,
  gamemode,
  stb,
  SDL2,
  glslang,
  python3,
  httplib,
  cpp-jwt,
  fetchFromGitea,
  ffmpeg-headless,
  qt6,
  fetchFromGitHub,
  fetchurl,
  unzip,
  unordered_dense,
  mbedtls,
  xbyak,
  zydis,
}:
let
  inherit (qt6)
    qtbase
    qtmultimedia
    qtwayland
    wrapQtAppsHook
    qttools
    qtwebengine
    qt5compat
    ;

  compat-list = stdenv.mkDerivation {
    pname = "yuzu-compatibility-list";
    version = "unstable-2024-02-26";

    src = fetchFromGitHub {
      owner = "flathub";
      repo = "org.yuzu_emu.yuzu";
      rev = "9c2032a3c7e64772a8112b77ed8b660242172068";
      hash = "sha256-ITh/W4vfC9w9t+TJnPeTZwWifnhTNKX54JSSdpgaoBk=";
    };

    buildCommand = ''
      cp $src/compatibility_list.json $out
    '';
  };

  quazip = stdenv.mkDerivation {
    pname = "quazip";
    version = "1.5-qt6";
    src = fetchFromGitHub {
      owner = "crueter-archive";
      repo = "quazip-qt6";
      rev = "f838774d6306eb5a500af9ab336ec85f01ebd7ec";
      hash = "sha256-Jp+v7uwoPxvarzOclgSnoGcwAPXKnm23yrZKtjJCHro=";
    };
    nativeBuildInputs = [
      cmake
    ];

    buildInputs = [
      qtbase
      qtmultimedia
      qtwayland
      wrapQtAppsHook
      qttools
      qtwebengine
      qt5compat
    ];
  };

  mcl = stdenv.mkDerivation {
    pname = "mcl";
    version = "latest";
    src = fetchFromGitHub {
      owner = "azahar-emu";
      repo = "mcl";
      rev = "7b08d83418f628b800dfac1c9a16c3f59036fbad";
      hash = "sha256-uTOiOlMzKbZSjKjtVSqFU+9m8v8horoCq3wL0O2E8sI=";
    };

    nativeBuildInputs = [
      cmake
    ];

    buildInputs = [
      fmt_11
    ];
  };

  sirit = stdenv.mkDerivation rec {
    pname = "sirit";
    version = "v1.0.2";
    src = fetchFromGitHub {
      owner = "eden-emulator";
      repo = "sirit";
      rev = "${version}";
      hash = "sha256-0wjpQm8tWHeEebSiRGs7b8LYcA2d4MEbHuffP2eSNGU=";
    };

    nativeBuildInputs = [
      pkg-config
      cmake
    ];

    buildInputs = [
      spirv-headers
    ];

    cmakeFlags = [
      "-DSIRIT_USE_SYSTEM_SPIRV_HEADERS=ON"
    ];
  };

  nx_tzdb = stdenv.mkDerivation (finalAttrs: {
    pname = "nx_tzdb";
    version = "250725";
    src = fetchurl {
      url = "https://git.crueter.xyz/misc/tzdb_to_nx/releases/download/${finalAttrs.version}/${finalAttrs.version}.zip";
      hash = "sha256-xYT/3Uzy9VGh0DaK5ouhOsCqDwu3uxkMSp++ZIL0Gcs=";
    };

    nativeBuildInputs = [ unzip ];
    buildCommand = ''
      unzip $src -d $out
    '';

  });

  xbyak_new = xbyak.overrideAttrs (oldAttrs: {
    version = "7.22";
    src = fetchFromGitHub {
      owner = "herumi";
      repo = "xbyak";
      rev = "4e44f4614ddbf038f2a6296f5b906d5c72691e0f";
      hash = "sha256-ZmdOjO5MbY+z+hJEVgpQzoYGo5GAFgwAPiv4vs/YMUA=";
    };
  });

  frozen = stdenv.mkDerivation (finalAttrs: rec {
    pname = "frozen";
    version = "61dce5ae18ca59931e27675c468e64118aba8744";
    src = fetchFromGitHub {
      owner = "serge-sans-paille";
      repo = "frozen";
      rev = "${version}";
      hash = "sha256-zIczBSRDWjX9hcmYWYkbWY3NAAQwQtKhMTeHlYp4BKk=";
    };

    nativeBuildInputs = [
      cmake
    ];
  });

in
stdenv.mkDerivation (finalAttrs: {
  pname = "eden";
  version = "v0.0.4-rc3";
  src = fetchFromGitea {
    domain = "git.eden-emu.dev";
    owner = "eden-emu";
    repo = "eden";
    rev = "v0.0.4-rc3";
    hash = "sha256-THypvgdy3R7KyjeBLuO8+EVMDEIMafwXk0YVToJ2Ols=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    glslang
    pkg-config
    python3
    qttools
    wrapQtAppsHook
    mcl
    frozen
  ];

  buildInputs = [
    vulkan-headers
    qt5compat
    discord-rpc
    mcl
    boost
    nx_tzdb
    cpp-jwt
    cubeb
    enet
    ffmpeg-headless
    fmt_11
    gamemode
    httplib
    openssl
    libopus
    libusb1
    lz4
    mbedtls
    nlohmann_json
    qtbase
    qtmultimedia
    qtwayland
    qtwebengine
    SDL2
    quazip
    simpleini
    spirv-tools
    spirv-headers
    sirit
    stb
    unordered_dense
    vulkan-memory-allocator
    vulkan-utility-libraries
    xbyak_new
    zlib
    zstd
    zydis
  ];

  # dontFixCmake = true;

  __structuredAttrs = true;
  cmakeFlags = [
    # actually has a noticeable performance impact
    (lib.cmakeBool "YUZU_ENABLE_LTO" true)
    (lib.cmakeBool "YUZU_TESTS" false)
    (lib.cmakeBool "DYNARMIC_TESTS" false)

    (lib.cmakeBool "ENABLE_QT6" true)
    (lib.cmakeBool "ENABLE_QT_TRANSLATION" true)
    (lib.cmakeBool "ENABLE_OPENSSL" true)

    # use system libraries
    # NB: "external" here means "from the externals/ directory in the source",
    # so "false" means "use system"
    (lib.cmakeBool "YUZU_USE_EXTERNAL_SDL2" false)
    (lib.cmakeBool "YUZU_USE_EXTERNAL_VULKAN_HEADERS" false)
    (lib.cmakeBool "YUZU_USE_EXTERNAL_VULKAN_UTILITY_LIBRARIES" false)
    (lib.cmakeBool "YUZU_USE_EXTERNAL_VULKAN_SPIRV_TOOLS" false)
    (lib.cmakeBool "YUZU_USE_CPM" false)
    (lib.cmakeBool "CPMUTIL_FORCE_SYSTEM" true)

    # nx_tzdb
    (lib.cmakeFeature "YUZU_TZDB_PATH" "${nx_tzdb}")

    # don't check for missing submodules
    (lib.cmakeBool "YUZU_CHECK_SUBMODULES" false)

    # enable some optional features
    (lib.cmakeBool "YUZU_USE_QT_WEB_ENGINE" true)
    (lib.cmakeBool "YUZU_USE_QT_MULTIMEDIA" true)
    (lib.cmakeBool "USE_DISCORD_PRESENCE" true)

    # We dont want to bother upstream with potentially outdated compat reports
    (lib.cmakeBool "YUZU_ENABLE_COMPATIBILITY_REPORTING" false)
    (lib.cmakeBool "ENABLE_COMPATIBILITY_LIST_DOWNLOAD" false)

    (lib.cmakeFeature "TITLE_BAR_FORMAT_IDLE" "eden | ${finalAttrs.version} (nixpkgs) {}")
    (lib.cmakeFeature "TITLE_BAR_FORMAT_RUNNING" "eden | ${finalAttrs.version} (nixpkgs) | {}")

    # Dev
    (lib.cmakeBool "SIRIT_USE_SYSTEM_SPIRV_HEADERS" true)
    (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-Wno-error -Wno-array-parameter -Wno-stringop-overflow")
  ];

  env = {
    NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isx86_64 "-msse4.2";
  };

  qtWrapperArgs = [
    "--prefix LD_LIBRARY_PATH : ${vulkan-loader}/lib"
  ];

  postConfigure = ''
    ln -sf ${compat-list} ./dist/compatibility_list/compatbility_list.json
  '';

  postInstall = ''
    install -Dm44 $src/dist/72-yuzu-input.rules $out/lib/udev/rules.d/72-yuzu-input.rules
  '';

  meta = {
    description = "Nintendo Switch video game console emulator";
    homepage = "https://eden-emu.dev/";
    downloadPage = "https://eden-emu.dev/download";
    changelog = "https://github.com/eden-emulator/Releases/releases";
    mainProgram = "eden";
    desktopFileName = "dist/dev.eden_emu.eden.desktop";
  };
})
