{
  pkgs,
  ...
}:
pkgs.writeScript "title" ''
  #!/usr/bin/env fish

  # Customize these color commands as you like
  set colorUser       (set_color --bold cyan)
  set colorHost       (set_color --bold blue)
  set colorOS         (set_color --bold magenta)
  set colorVersion    (set_color --bold magenta)
  set colorCodename   (set_color --bold --italic magenta)
  set colorBang       (set_color --bold white)
  set colorReset      (set_color normal)

  # Get uppercase user, host, OS name
  set u (whoami)
  set user (printf '%s%s' (string upper (string sub -l 1 $u)) (string lower (string sub -s 2 $u)))

  set h (hostname)
  set host (printf '%s%s' (string upper (string sub -l 1 $h)) (string lower (string sub -s 2 $h)))

  set osN (grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
  set osName (printf '%s%s' (string upper (string sub -l 1 $osN)) (string lower (string sub -s 2 $osN)))

  set osVersion (grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

  set osCN (grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
  set osCodeName (printf '%s%s' (string upper (string sub -l 1 $osCN)) (string lower (string sub -s 2 $osCN)))

  # Print each part as you like
  echo -n $colorUser$user$colorReset
  echo -n $colorBang" ⸘ "
  echo -n $colorHost$host$colorReset
  echo -n $colorBang" ‽ "
  echo -n $colorOS$osName" "$colorVersion$osVersion$colorReset" "
  echo $colorOS'('$colorCodename$osCodeName$colorReset$colorOS')'
''
