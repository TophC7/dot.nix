{ pkgs, inputs, ... }:
{
  imports = [
    inputs.nix-gaming.nixosModules.pipewireLowLatency
  ];

  services.pulseaudio = {
    enable = false;
    package = pkgs.pulseaudioFull;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
    lowLatency.enable = true;

    # Fix for HyperX Cloud Alpha; only support 48kHz/S16LE
    # The lowLatency module requests 96kHz which it does not support
    wireplumber.extraConfig = {
      "51-hyperx-fix" = {
        "monitor.alsa.rules" = [
          # Device-level rule
          {
            matches = [
              { "device.name" = "~alsa_card.usb-Kingston_HyperX_Cloud_Alpha_S.*"; }
            ];
            actions = {
              update-props = {
                "api.alsa.use-acp" = true;
                "audio.rate" = 48000;
                "audio.allowed-rates" = [ 48000 ];
              };
            };
          }
          # Node-level rule for sink/source
          {
            matches = [
              { "node.name" = "~alsa_output.usb-Kingston_HyperX_Cloud_Alpha_S.*"; }
            ];
            actions = {
              update-props = {
                "audio.rate" = 48000;
                "audio.allowed-rates" = [ 48000 ];
                "audio.format" = "S16LE";
                "api.alsa.period-size" = 1024;
                "api.alsa.headroom" = 8192;
              };
            };
          }
        ];
      };
    };

    # Also add PipeWire ALSA config as fallback
    extraConfig.pipewire = {
      "92-hyperx-alsa" = {
        "context.objects" = [
          {
            factory = "adapter";
            args = {
              "factory.name" = "api.alsa.pcm.sink";
              "node.name" = "alsa_output.hyperx";
              "node.description" = "HyperX Cloud Alpha S";
              "media.class" = "Audio/Sink";
              "api.alsa.path" = "hw:0,0";
              "audio.rate" = 48000;
              "audio.channels" = 2;
              "audio.position" = "FL,FR";
            };
          }
        ];
      };
    };
  };

  # services.easyeffects = {
  #   enable = true;
  # };

  # environment.systemPackages = with pkgs; [
  #   gnomeExtensions.easyeffects-preset-selector
  # ];
}
