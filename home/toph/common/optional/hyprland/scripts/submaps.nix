{
  pkgs,
  ...
}:
pkgs.writeScript "submap-script" ''
  #!/usr/bin/env fish

  # Usage: ./parse_submaps.fish path/to/file.json
  if test (count $argv) -lt 1
      echo "Usage: $argv[0] path/to/file.json"
      exit 1
  end

  set json_file $argv[1]

  # Iterate over submaps preserving order
  for entry in (${pkgs.jq}/bin/jq -c '.| to_entries[]' $json_file)
      set submap_name (echo $entry | ${pkgs.jq}/bin/jq -r '.key')
      echo "submap=$submap_name"

      # Process each binds entry within the submap
      for bind_entry in (echo $entry | ${pkgs.jq}/bin/jq -c '.value.binds | to_entries[]')
          set bind_key (echo $bind_entry | ${pkgs.jq}/bin/jq -r '.key')

          if test "$bind_key" = ""
              set prefix "bind="
          else if test "$bind_key" = "unbind"
              set prefix "unbind="
          else
              set prefix "bind$bind_key="
          end

          # Process each binding's value in the array
          for binding in (echo $bind_entry | ${pkgs.jq}/bin/jq -r '.value[]')
              echo "$prefix$binding"
          end
      end

      # Append submap reset except for default "" submap
      if not test "$submap_name" = ""
          echo "submap=reset"
      end
  end
''
