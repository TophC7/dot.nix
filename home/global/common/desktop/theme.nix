{
  config,
  lib,
  pkgs,
  inputs,
  host,
  ...
}:

let
  cfg = config.theme;

  # Generate Material You colors JSON using matugen
  # This is shared by both matugen and dms generators
  generateMatugenJson =
    wallpaper: scheme: polarity:
    pkgs.runCommand "matugen-colors.json"
      {
        nativeBuildInputs = [ inputs.matugen.packages.${pkgs.system}.default ];
      }
      ''
        matugen image ${wallpaper} \
          --type ${if scheme != null then scheme else "scheme-expressive"} \
          --mode ${polarity} \
          --json strip \
          --quiet \
          > $out
      '';

  # Generate base16 YAML from matugen Material You colors
  generateMatugenScheme =
    wallpaper: scheme: polarity:
    let
      matugenJson = generateMatugenJson wallpaper scheme polarity;
    in
    pkgs.runCommand "matugen-base16-scheme.yaml"
      {
        nativeBuildInputs = [
          inputs.matugen.packages.${pkgs.system}.default
          pkgs.jq
        ];
      }
      ''
        # Generate Material You colors and convert to base16 format
        # Base16 mapping:
        # base00-07: Backgrounds and foregrounds (dark to light)
        # base08-0F: Accent colors for syntax highlighting

        cat > $out << EOF
        system: base16
        slug: matugen-material
        name: matugen-material
        author: Matugen
        variant: ${polarity}
        palette:
          base00: "$(jq -r '.colors.background.${polarity}' ${matugenJson})"
          base01: "$(jq -r '.colors.surface.${polarity}' ${matugenJson})"
          base02: "$(jq -r '.colors.surface_container.${polarity}' ${matugenJson})"
          base03: "$(jq -r '.colors.surface_bright.${polarity}' ${matugenJson})"
          base04: "$(jq -r '.colors.on_surface_variant.${polarity}' ${matugenJson})"
          base05: "$(jq -r '.colors.on_surface.${polarity}' ${matugenJson})"
          base06: "$(jq -r '.colors.surface_container_highest.${polarity}' ${matugenJson})"
          base07: "$(jq -r '.colors.on_background.${polarity}' ${matugenJson})"
          base08: "$(jq -r '.colors.error.${polarity}' ${matugenJson})"
          base09: "$(jq -r '.colors.on_error_container.${polarity}' ${matugenJson})"
          base0A: "$(jq -r '.colors.tertiary.${polarity}' ${matugenJson})"
          base0B: "$(jq -r '.colors.primary.${polarity}' ${matugenJson})"
          base0C: "$(jq -r '.colors.on_tertiary_container.${polarity}' ${matugenJson})"
          base0D: "$(jq -r '.colors.secondary.${polarity}' ${matugenJson})"
          base0E: "$(jq -r '.colors.on_secondary_container.${polarity}' ${matugenJson})"
          base0F: "$(jq -r '.colors.on_primary_container.${polarity}' ${matugenJson})"
        EOF
      '';

  # Generate base16 YAML using DMS with matugen colors
  generateDmsScheme =
    wallpaper: scheme: polarity:
    let
      matugenJson = generateMatugenJson wallpaper scheme polarity;
    in
    pkgs.runCommand "dms-base16-scheme.yaml"
      {
        nativeBuildInputs = [
          inputs.matugen.packages.${pkgs.system}.default
          pkgs.jq
          inputs.dms-cli.packages.${pkgs.system}.default
        ];
      }
      ''
        # Extract primary and surface colors from matugen JSON
        PRIMARY=$(jq -r '.colors.primary.${polarity}' ${matugenJson})
        SURFACE=$(jq -r '.colors.surface.${polarity}' ${matugenJson})

        # Generate dank16 colors using DMS
        ${
          if polarity == "light" then
            "DMS_OUTPUT=$(dms dank16 $PRIMARY --background $SURFACE --light)"
          else
            "DMS_OUTPUT=$(dms dank16 $PRIMARY --background $SURFACE)"
        }

        # Parse DMS output and create base16 YAML
        # DMS outputs: palette = 0=#0d1419, palette = 1=#d55958, etc.
        # We need to extract these and map to base16 format

        # Extract all 16 colors from DMS output
        # Remove everything before and including the # to get just the hex value
        COLOR_0=$(echo "$DMS_OUTPUT" | grep 'palette = 0=' | sed 's/.*#//')
        COLOR_1=$(echo "$DMS_OUTPUT" | grep 'palette = 1=' | sed 's/.*#//')
        COLOR_2=$(echo "$DMS_OUTPUT" | grep 'palette = 2=' | sed 's/.*#//')
        COLOR_3=$(echo "$DMS_OUTPUT" | grep 'palette = 3=' | sed 's/.*#//')
        COLOR_4=$(echo "$DMS_OUTPUT" | grep 'palette = 4=' | sed 's/.*#//')
        COLOR_5=$(echo "$DMS_OUTPUT" | grep 'palette = 5=' | sed 's/.*#//')
        COLOR_6=$(echo "$DMS_OUTPUT" | grep 'palette = 6=' | sed 's/.*#//')
        COLOR_7=$(echo "$DMS_OUTPUT" | grep 'palette = 7=' | sed 's/.*#//')
        COLOR_8=$(echo "$DMS_OUTPUT" | grep 'palette = 8=' | sed 's/.*#//')
        COLOR_9=$(echo "$DMS_OUTPUT" | grep 'palette = 9=' | sed 's/.*#//')
        COLOR_10=$(echo "$DMS_OUTPUT" | grep 'palette = 10=' | sed 's/.*#//')
        COLOR_11=$(echo "$DMS_OUTPUT" | grep 'palette = 11=' | sed 's/.*#//')
        COLOR_12=$(echo "$DMS_OUTPUT" | grep 'palette = 12=' | sed 's/.*#//')
        COLOR_13=$(echo "$DMS_OUTPUT" | grep 'palette = 13=' | sed 's/.*#//')
        COLOR_14=$(echo "$DMS_OUTPUT" | grep 'palette = 14=' | sed 's/.*#//')
        COLOR_15=$(echo "$DMS_OUTPUT" | grep 'palette = 15=' | sed 's/.*#//')

        # Create base16 YAML with DMS colors
        # Map DMS palette indices sequentially to base16 positions
        cat > $out << EOF
        system: base16
        slug: dms-dank16
        name: dms-dank16
        author: DMS
        variant: ${polarity}
        palette:
          base00: "''${COLOR_0^^}"
          base01: "''${COLOR_1^^}"
          base02: "''${COLOR_2^^}"
          base03: "''${COLOR_3^^}"
          base04: "''${COLOR_4^^}"
          base05: "''${COLOR_5^^}"
          base06: "''${COLOR_6^^}"
          base07: "''${COLOR_7^^}"
          base08: "''${COLOR_8^^}"
          base09: "''${COLOR_9^^}"
          base0A: "''${COLOR_10^^}"
          base0B: "''${COLOR_11^^}"
          base0C: "''${COLOR_12^^}"
          base0D: "''${COLOR_13^^}"
          base0E: "''${COLOR_14^^}"
          base0F: "''${COLOR_15^^}"
        EOF
      '';

  # Determine base16 scheme based on generator and desktop environment
  base16Config =
    if cfg.base16.generator == "stylix" then
      # Stylix: use file, pkg, or nothing (auto-generate)
      if cfg.base16.file != null then
        cfg.base16.file
      else if cfg.base16.pkg != null then
        "${pkgs.base16-schemes}/share/themes/${cfg.base16.pkg}.yaml"
      else
        # Don't set anything - let stylix auto-generate from wallpaper
        null
    else if cfg.base16.generator == "matugen" then
      # Matugen: works with any desktop environment
      # Use IFD to bypass pure Nix YAML parser issues
      {
        yaml = "${generateMatugenScheme cfg.image cfg.base16.scheme cfg.polarity}";
        use-ifd = "auto";
      }
    else if cfg.base16.generator == "dms" then
      # DMS: only available for Niri
      if host.niri or false then
        # Use IFD to bypass pure Nix YAML parser issues
        {
          yaml = "${generateDmsScheme cfg.image cfg.base16.scheme cfg.polarity}";
          use-ifd = "auto";
        }
      else
        throw "DMS is only supported on Niri desktop"
    else
      throw "Unknown base16 generator: ${cfg.base16.generator}";
in
{
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  # Configure Stylix based on theme-spec settings
  stylix = lib.mkIf cfg.enable (
    {
      enable = true;
      autoEnable = true;

      # Use the wallpaper image from theme-spec
      image = cfg.image;

      # Set light/dark mode from theme-spec polarity
      polarity = cfg.polarity;

      # Standard font configuration - can be extended later if needed in theme-spec
      fonts = {
        serif = {
          package = pkgs.google-fonts.override { fonts = [ "Laila" ]; };
          name = "Laila";
        };

        sansSerif = {
          package = pkgs.lexend;
          name = "Lexend";
        };

        monospace = {
          package = pkgs.monocraft-nerd-fonts;
          name = "Monocraft";
        };

        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };

        sizes = {
          applications = 12;
          desktop = 11;
          popups = 11;
          terminal = 12;
        };
      };

      # Desktop-specific targets
      targets = {
        gnome = {
          enable = true;
          useWallpaper = true;
        };
        vscode = {
          enable = false;
        };
      };
    }
    // lib.optionalAttrs (base16Config != null) {
      # Set base16 scheme based on generator and desktop environment
      # Only set if we have a value (null means let stylix auto-generate)
      base16Scheme = base16Config;
    }
  );

  # Configure pointer/cursor from theme-spec
  home.pointerCursor = lib.mkIf cfg.enable {
    gtk.enable = true;
    package = cfg.pointer.package;
    name = cfg.pointer.name;
    size = cfg.pointer.size;
  };

  # Configure GTK icon theme from theme-spec
  gtk = lib.mkIf cfg.enable {
    enable = true;

    iconTheme = {
      package = cfg.icon.package;
      name = cfg.icon.name;
    };
  };
}
