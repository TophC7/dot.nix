{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  versionCheckHook,
  nix-update-script,
  icu,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "microsoft-edit";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "edit";
    tag = "v${finalAttrs.version}";
    hash = "sha256-5GUAHa0/7k4uVNWEjn0hd1YvkRnUk6AdxTQhw5z95BY=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-DEzjfrXSmum/GJdYanaRDKxG4+eNPWf5echLhStxcIg=";
  # Requires nightly features
  env.RUSTC_BOOTSTRAP = 1;

  # Add a patch to fix the write_filled error
  patches = [
    ./write-filled-fix.patch
  ];

  buildInputs = [
    icu
  ];

  postFixup =
    let
      rpathAppend = lib.makeLibraryPath [ icu ];
    in
    lib.optionalString stdenv.hostPlatform.isElf ''
      patchelf $out/bin/edit \
        --add-rpath ${rpathAppend}
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      ${stdenv.cc.targetPrefix}install_name_tool -add_rpath ${rpathAppend} $out/bin/edit
    '';

  # Disabled for now, microsoft/edit#194
  doInstallCheck = false;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/edit";
  versionCheckProgramArg = "--version";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Simple editor for simple needs";
    longDescription = ''
      This editor pays homage to the classic MS-DOS Editor,
      but with a modern interface and input controls similar to VS Code.
      The goal is to provide an accessible editor that even users largely
      unfamiliar with terminals can easily use.
    '';
    mainProgram = "edit";
    homepage = "https://github.com/microsoft/edit";
    changelog = "https://github.com/microsoft/edit/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ RossSmyth ]; # https://github.com/NixOS/nixpkgs/pull/409075
    platforms = lib.platforms.all;
  };
})
