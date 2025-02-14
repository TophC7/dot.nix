{

  imports =
    let
      commit = "9f01fb79f61f53fe31d5ef831e420ab9ad252b99";
    in
    [
      "${
        builtins.fetchTarball {
          name = "arion-v0.2.2.0";
          url = "https://github.com/hercules-ci/arion/archive/${commit}.tar.gz";
          # obtained via nix-prefetch-url --unpack <url>
          sha256 = "1y2wi9kjb1agrvzaj6417lap4qg969hdfz3cmw3v3sz1q5mqcaw5";
        }
      }/nixos-module.nix"
    ];

  virtualisation.docker.enable = true;
  virtualisation.arion = {
    backend = "docker"; # or "docker"
    projects.filerun = {
      # serviceName = "filerun";
      settings = {
        # Specify you project here, or import it from a file.
        imports = [ ./arion-compose.nix ];
      };
    };
  };
}
