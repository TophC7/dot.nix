{ pkgs, ... }:
let
  # Low-latency settings
  quantum = 128;
  rate = 48000;
  qr = "${toString quantum}/${toString rate}";
in
{
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

    extraConfig = {
      # Low-latency PipeWire configuration
      pipewire."99-lowlatency" = {
        "context.properties"."default.clock.min-quantum" = quantum;

        "context.modules" = [
          {
            name = "libpipewire-module-rt";
            flags = [
              "ifexists"
              "nofail"
            ];
            args = {
              "nice.level" = -15;
              "rt.prio" = 88;
              "rt.time.soft" = 200000;
              "rt.time.hard" = 200000;
            };
          }
        ];
      };

      # Low-latency PulseAudio compatibility
      pipewire-pulse."99-lowlatency"."pulse.properties" = {
        "server.address" = [ "unix:native" ];
        "pulse.min.req" = qr;
        "pulse.min.quantum" = qr;
        "pulse.min.frag" = qr;
      };

      # Client stream properties for low latency
      client."99-lowlatency"."stream.properties" = {
        "node.latency" = qr;
        "resample.quality" = 1;
      };
    };

    wireplumber.extraConfig."99-alsa-lowlatency"."monitor.alsa.rules" = [
      {
        matches = [ { "node.name" = "~alsa_output.*"; } ];
        actions.update-props = {
          "audio.format" = "S32LE";
          "audio.rate" = rate * 2; # 96kHz for ALSA outputs
          "api.alsa.period-size" = 2;
        };
      }
    ];
  };
}
