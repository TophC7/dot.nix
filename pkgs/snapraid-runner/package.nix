{
  stdenv,
  lib,
  pkgs,
  ...
}:

let
  snapraid-runner-py = pkgs.writeTextFile {
    name = "snapraid-runner.py";
    executable = true;
    destination = "/bin/snapraid-runner.py";
    text = builtins.readFile ./snapraid-runner.py;
  };

  snapraid-runner = pkgs.writeTextFile {
    name = "snapraid-runner.sh";
    executable = true;
    destination = "/bin/snapraid-runner";
    text = ''
      #!${pkgs.stdenv.shell}

      # Check if the "-c" option is present
      config_option_present=false
      for arg in "$@"; do
        if [ "$arg" = "-c" ]; then
          config_option_present=true
          break
        fi
      done

      # Add the default config option if not present
      if [ "$config_option_present" = false ]; then
        set -- "-c" "/etc/snapraid-runner.conf" "$@"
      fi

      ${pkgs.python311}/bin/python3 ${snapraid-runner-py}/bin/snapraid-runner.py "$@"
    '';
  };

in
stdenv.mkDerivation rec {
  pname = "snapraid-runner";
  version = "8f78f9f1af8ca5a9b6469a6c142cab2577157331";

  buildInputs = [
    snapraid-runner
  ];

  builder = pkgs.writeTextFile {
    name = "builder.sh";
    text = ''
      . $stdenv/setup
      mkdir -p $out/bin
      ln -sf ${snapraid-runner}/bin/snapraid-runner $out/bin/snapraid-runner'';
  };
}
