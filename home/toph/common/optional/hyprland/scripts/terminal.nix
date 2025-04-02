{
  pkgs,
  ...
}:
# TODO: obviously lol
# Handle float terminal and grim select terminal
pkgs.writeScript "terminal-launch" ''
  #!/usr/bin/env fish
  foot
''
