#!/usr/bin/env zsh

set -euo pipefail
IFS=$'\n\t'

LINKED_FILES="$HOME/.dotfiles_linked_files"

# Define color variables
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

function doIt() {
    # Clean up old symlinks first
    if [ -f "$LINKED_FILES" ]; then
        echo "${GREEN}Found previous linked files list, cleaning up old symlinks...${RESET}"
        while IFS= read -r link; do
            if [ -L "$link" ]; then
                rm "$link"
                echo "Removed symlink: $link"
            fi
        done < "$LINKED_FILES"
        rm "$LINKED_FILES"
        echo "Cleanup complete."
    fi

    echo "\n${GREEN}Symlinking files${RESET}"
    # Initialize the linked files list
    touch "$LINKED_FILES"

    # Array of excluded files/directories (in addition to .gitignore)
    excluded=(
        ".git"
        ".claude"
        "bootstrap.sh"
        "CLAUDE.md"
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
            file=${raw_file#./} # Remove a leading "./"

            mkdir -p "$(dirname "$HOME/$file")"
            ln -sf "$PWD/$file" "$HOME/$file"
            echo "Linked: $PWD/$file -> $HOME/$file"

            # Add the symlink path to our linked files list
            echo "$HOME/$file" >> "$LINKED_FILES"
        fi
    done

    echo "Created linked files list at $PWD/$LINKED_FILES with $(wc -l < "$LINKED_FILES" | tr -d ' ') entries."

    # Claude Code configuration
    echo "\n${GREEN}Setting up Claude Code config${RESET}"
    mkdir -p "$HOME/.claude"
    ln -sf "$PWD/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    echo "Linked: $PWD/.claude/CLAUDE.md -> $HOME/.claude/CLAUDE.md"

    if [ -f ".claude/settings.local.json" ]; then
        python3 -c "
import json, sys
base = json.load(open('.claude/settings.json'))
local = json.load(open('.claude/settings.local.json'))
base.update(local)
json.dump(base, open(sys.argv[1], 'w'), indent=2)
print('Merged .claude/settings.json + settings.local.json -> ' + sys.argv[1])
" "$HOME/.claude/settings.json"
    else
        cp ".claude/settings.json" "$HOME/.claude/settings.json"
        echo "Copied: .claude/settings.json -> $HOME/.claude/settings.json"
    fi

    echo "\n${GREEN}Done${RESET}"
}

doIt;

unset doIt;
