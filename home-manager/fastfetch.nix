{ pkgs, ... }:
# progams./fastfetch =
{
    enable = true;
    settings = {
        logo = {
            # Created with Chafa
            # chafa -s 26x13 -w 9 --symbols vhalf --view-size 26x13 cloud.png > cloud.txt
            source = builtins.readFile ./cloud.txt;
            type = "data";
            position = "left";
            padding = {
                top = 0;
            };
        };
        display = {
            separator = " ";
        };
        modules = [
            {
                key = "╭───────────╮";
                type = "custom";
            }
            {
                key = "│ {#31} user    {#keys}│";
                type = "title";
                format = "{user-name}";
            }
            {
                key = "│ {#32}󰇅 host    {#keys}│";
                type = "title";
                format = "{host-name}";
            }
            {
                key = "│ {#33}󰅐 uptime  {#keys}│";
                type = "uptime";
            }
            {
                key = "│ {#34}{icon} distro  {#keys}│";
                type = "os";
            }
            {
                key = "│ {#36}󰇄 desktop {#keys}│";
                type = "de";
            }
            {
                key = "│ {#32} shell   {#keys}│";
                type = "shell";
            }
            {
                key = "│ {#33}󰍛 cpu     {#keys}│";
                type = "cpu";
                showPeCoreCount = true;
            }
            {
                key = "│ {#34}󰉉 disk    {#keys}│";
                type = "disk";
                folders = "/";
            }
            {
                key = "│ {#35} memory  {#keys}│";
                type = "memory";
            }
            {
                key = "│ {#36}󰩟 network {#keys}│";
                type = "localip";
                format = "{ipv4} ({ifname})";
            }
            {
                key = "├───────────┤";
                type = "custom";
            }
            {
                key = "│ {#39} colors  {#keys}│";
                type = "colors";
                symbol = "circle";
            }
            {
                key = "╰───────────╯";
                type = "custom";
            }
        ];
    };
}  