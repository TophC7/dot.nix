# Stylix integration — wires mix.nix theme spec to stylix.
#
# Pana owns palette generation: one Material palette compiles to CSS (pana),
# ANSI16 (terminal colors), and Base16 (stylix and everything downstream).
# When pana's home module runs beside us it compiles its own artifact set and
# we consume those; otherwise we drive the same compiler ourselves so every
# themed host gets identical palettes regardless of shell.
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.theme;
  system = pkgs.stdenv.hostPlatform.system;

  panaTheme = inputs.pana.packages.${system}.theme;

  # Pana's generated artifacts exist only beside an enabled, integrated pana.
  # Keying this off plain options (never theme.generated.*) matters: those
  # depend on the shared matugen template set, so testing them here while
  # conditionally registering a template would recurse infinitely.
  hasPana =
    config.programs ? pana && config.programs.pana.enable && config.theme.installGeneratedFiles;

  # Same compiler pana's home module uses, fed by our own matugen template run.
  selfCompiled =
    let
      artifacts = pkgs.runCommand "pana-theme-artifacts" { } ''
        mkdir -p "$out"
        ${lib.getExe panaTheme} compile \
          ${cfg.generated.files.".cache/pana/material.json"} "$out" ${cfg.polarity}
      '';
    in
    {
      material = "${artifacts}/theme/material.json";
      ansi16 = "${artifacts}/theme/ansi16.json";
      base16 = "${artifacts}/theme/base16.yaml";
    };

  materialPalette = if hasPana then config.programs.pana.generated.materialPalette else selfCompiled.material;
  ansi16Palette = if hasPana then config.programs.pana.generated.ansi16Palette else selfCompiled.ansi16;
  base16Scheme = if hasPana then config.programs.pana.generated.base16Scheme else selfCompiled.base16;

  # Terminal themes from the generated palettes. Syntax highlighting uses named
  # ANSI colors (resolved through Ghostty's palette); hex values where subtle
  # shading helps.
  terminalThemes =
    pkgs.runCommand "pana-terminal-themes" { nativeBuildInputs = [ pkgs.jq ]; }
      ''
        set -euo pipefail
        mkdir -p $out

        m() { jq -r --arg k "$1" '.[$k]' ${materialPalette}; }
        BG=$(m surface)
        FG=$(m on-surface)
        DIM=$(m surface-container-low)
        PARAM=$(m on-surface-variant)

        {
          printf 'background = %s\n' "$BG"
          printf 'foreground = %s\n' "$FG"
          printf 'cursor-color = %s\n' "$(m primary)"
          printf 'selection-background = %s\n' "$(m primary-container)"
          printf 'selection-foreground = %s\n' "$FG"
          jq -r '.normal[], .bright[]' ${ansi16Palette} \
            | awk '{ printf "palette = %d=%s\n", NR - 1, $1 }'
        } > $out/ghostty-theme

        cat > $out/fish-colors.fish << EOF
        set -g fish_color_normal normal
        set -g fish_color_command green
        set -g fish_color_keyword blue
        set -g fish_color_quote yellow
        set -g fish_color_redirection cyan
        set -g fish_color_end brblack
        set -g fish_color_error red
        set -g fish_color_param $PARAM
        set -g fish_color_comment $DIM
        set -g fish_color_autosuggestion $DIM
        set -g fish_color_operator blue
        set -g fish_color_escape yellow
        set -g fish_color_cwd green
        set -g fish_color_cwd_root red
        set -g fish_color_user brgreen
        set -g fish_color_host normal
        set -g fish_color_status red
        set -g fish_color_cancel -r
        set -g fish_color_search_match bryellow --background=$DIM
        set -g fish_color_selection white --bold --background=$DIM
        set -g fish_color_valid_path --underline
        set -g fish_color_history_current --bold
        set -g fish_color_match --background=brblue
        set -g fish_pager_color_completion normal
        set -g fish_pager_color_description yellow --dim
        set -g fish_pager_color_prefix white --bold
        set -g fish_pager_color_progress brwhite --background=cyan
        EOF
      '';
in
{
  imports = [
    inputs.stylix.homeModules.stylix
    inputs.mix-nix.homeManagerModules.theme
  ];

  config = lib.mkMerge [
    # Feed pana's typed Material template into the shared matugen run — only
    # when pana isn't already registering it under its own integration.
    (lib.mkIf (cfg.enable && !hasPana) {
      theme.matugen.templates.pana-material = {
        template = "${panaTheme}/share/pana/matugen/material.json";
        path = ".cache/pana/material.json";
      };
    })

    (lib.mkIf cfg.enable {
      stylix = {
        enable = lib.mkDefault true;
        autoEnable = lib.mkDefault true;
        image = cfg.image;
        polarity = cfg.polarity;

        fonts = lib.optionalAttrs (cfg.fonts != null) cfg.fonts;

        icons = lib.mkIf (cfg.icon != null) {
          enable = lib.mkDefault true;
          package = cfg.icon.package;
          dark = cfg.icon.name;
          light = cfg.icon.name;
        };

        base16Scheme = {
          yaml = base16Scheme;
          use-ifd = "auto";
        };

        targets = {
          dank-material-shell.enable = lib.mkDefault false;
          qt = {
            enable = lib.mkDefault true;
            platform = lib.mkDefault "qtct";
          };
          vscode.enable = lib.mkDefault false;

          # Terminal colors come from pana's ANSI16, not stylix.
          ghostty.enable = false;
          fish.enable = false;
        };
      };

      # Terminal theme files
      home.file.".config/ghostty/themes/pana".source = "${terminalThemes}/ghostty-theme";

      programs.ghostty.settings.theme = lib.mkForce "pana";

      programs.fish.interactiveShellInit = ''
        source ${terminalThemes}/fish-colors.fish
      '';

      home.pointerCursor = lib.mkIf (cfg.pointer != null) {
        gtk.enable = lib.mkDefault true;
        package = cfg.pointer.package;
        name = cfg.pointer.name;
        size = cfg.pointer.size;
      };

      gtk.enable = lib.mkDefault true;
    })
  ];
}
