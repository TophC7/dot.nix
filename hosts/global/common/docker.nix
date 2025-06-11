{ pkgs, ... }:
let
  update-containers = pkgs.writeShellScriptBin "update-containers" ''
    SUDO=""
    if [[ $(id -u) -ne 0 ]]; then
      SUDO="sudo"
    fi

    # Get all unique images from running and stopped containers
    images=$($SUDO ${pkgs.docker}/bin/docker ps -a --format="{{.Image}}" | sort -u)

    echo "Found images to update:"
    echo "$images"

    for image in $images
    do
      echo "Pulling $image..."
      $SUDO ${pkgs.docker}/bin/docker pull $image
    done

    echo "Container image updates complete!"
  '';
in
{
  virtualisation = {
    docker = {
      enable = true;
      autoPrune.enable = true;
    };
    oci-containers.backend = "docker";
  };

  environment.systemPackages = with pkgs; [
    lazydocker # Simple TUI
    update-containers
  ];
}
