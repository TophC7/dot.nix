#!/usr/bin/env fish

if test (count $argv) -ne 1
    echo "Usage: $argv0 push|pull"
    exit 1
end

set action $argv[1]
set subtree_path "ags"
set remote "RyotShell-origin"
set branch "main"

cd (git rev-parse --show-toplevel)
switch $action
    case push
        set changes (git status --porcelain "$subtree_path")
        if test -n "$changes"
            set_color yellow; echo " Cannot push. There are uncommitted changes in $subtree_path."
            exit 1
        end
        git subtree push --prefix="$subtree_path" $remote $branch
    case pull
        git subtree pull --prefix="$subtree_path" $remote $branch
    case commit
        set changes (git status --porcelain "$subtree_path")
        if test -z "$changes"
            echo "No changes to commit in $subtree_path."
            exit 0
        end
        echo " Enter commit message:"
        read commit_message
        if test -z "$commit_message"
            echo "Commit message cannot be empty."
            exit 1
        end
        git add "$subtree_path"
        git commit -m "$commit_message"
    case '*'
        echo "Unknown argument. Use push or pull."
        exit 1
end