#!/usr/bin/env zsh

set -euo pipefail
IFS=$'\n\t'

function doIt() {
    # Array of excluded files/directories (in addition to .gitignore)
    excluded=(
        ".git"
        "bootstrap.sh"
        "README.md"
    )
    # Create a fd command with exclusions from the array. We use fd instead of
    # find because it respects .gitignore
    fd_cmd="fd --type f --hidden"
    for excl in "${excluded[@]}"; do
        fd_cmd+=" --exclude \"$excl\""
    done

    # Create symbolic links for all dotfiles
    for raw_file in $(eval $fd_cmd); do
        if [ -n "$raw_file" ]; then
            file=${raw_file:2} # Remove a leading "./"

            mkdir -p "$(dirname "$HOME/$file")"
            ln -sf "$PWD/$file" "$HOME/$file"
            echo "Linked: $PWD/$file -> $HOME/$file"
        fi
    done
}

doIt;

unset doIt;
