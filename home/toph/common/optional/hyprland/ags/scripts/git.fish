#!/usr/bin/env fish

if test (count $argv) -ne 1
    echo "Usage: $argv0 push|pull"
    exit 1
end

set action $argv[1]
set subtree_path "home/toph/common/optional/hyprland/ags"
set remote "RyotShell-origin"
set branch "main"

cd (git rev-parse --show-toplevel)
switch $action
    case push
        git subtree push --prefix="$subtree_path" $remote $branch
    case pull
        git subtree pull --prefix="$subtree_path" $remote $branch
    case '*'
        echo "Unknown argument. Use push or pull."
        exit 1
end