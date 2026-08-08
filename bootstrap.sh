#!/usr/bin/env zsh

set -euo pipefail
IFS=$'\n\t'

# Unmatched globs expand to nothing rather than aborting. Every glob loop below
# guards each entry with a [ -f ]/[ -d ]/[ -L ] test, which is only reachable if
# an empty directory yields zero iterations instead of a "no matches found"
# error — an empty agents/skills-pi is a normal state, not a failure.
setopt null_glob

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
        "agents"
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

    # Pi coding agent: share the same CLAUDE.md as global context
    echo "\n${GREEN}Setting up pi config${RESET}"
    mkdir -p "$HOME/.pi/agent"
    ln -sf "$PWD/.claude/CLAUDE.md" "$HOME/.pi/agent/CLAUDE.md"
    echo "Linked: $PWD/.claude/CLAUDE.md -> $HOME/.pi/agent/CLAUDE.md"

    # Antigravity CLI (agy): share the same CLAUDE.md as global rules (agy
    # calls this GEMINI.md), share the MCP server list, and wire lifecycle
    # hooks for the same sound/tmux-title notifications as Claude Code and pi.
    echo "\n${GREEN}Setting up agy config${RESET}"
    mkdir -p "$HOME/.gemini/config"
    ln -sf "$PWD/.claude/CLAUDE.md" "$HOME/.gemini/config/GEMINI.md"
    echo "Linked: $PWD/.claude/CLAUDE.md -> $HOME/.gemini/config/GEMINI.md"

    if [ -f ".config/mcp/mcp.json" ]; then
        ln -sf "$PWD/.config/mcp/mcp.json" "$HOME/.gemini/config/mcp_config.json"
        echo "Linked: $PWD/.config/mcp/mcp.json -> $HOME/.gemini/config/mcp_config.json"
    fi

    if [ -f "agents/agy/hooks.json" ]; then
        ln -sf "$PWD/agents/agy/hooks.json" "$HOME/.gemini/config/hooks.json"
        echo "Linked: $PWD/agents/agy/hooks.json -> $HOME/.gemini/config/hooks.json"
    fi

    # ~/.gemini/config/skills/* are symlinks that resolve into this repo, which
    # agy treats as a real path outside whatever project it's running in. By
    # default it denies (interactively: prompts "outside workspace" for) any
    # read of a path outside the current workspace, which would otherwise
    # make every shared skill unreadable. A read_file() allow-rule scoped to
    # this repo's own path fixes that without loosening access anywhere else
    # on disk -- add it to agy's personal settings file if it isn't there
    # already; everything else in that file (colorScheme, model,
    # trustedWorkspaces) is the user's own and stays untouched.
    mkdir -p "$HOME/.gemini/antigravity-cli"
    python3 -c "
import json, os

path = os.path.expanduser('~/.gemini/antigravity-cli/settings.json')
settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)
rule = 'read_file(' + os.getcwd() + ')'
allow = settings.setdefault('permissions', {}).setdefault('allow', [])
if rule not in allow:
    allow.append(rule)
with open(path, 'w') as f:
    json.dump(settings, f, indent=2)
"
    echo "Added a read_file() allow-rule for $PWD to ~/.gemini/antigravity-cli/settings.json"

    # Pi extensions are global and load from per-extension symlinks.
    if [ -d "agents/extensions" ]; then
        mkdir -p "$HOME/.pi/agent/extensions"
        for extension in "$PWD"/agents/extensions/*.ts; do
            [ -f "$extension" ] || continue
            extension_name=$(basename "$extension")
            ln -sfn "$extension" "$HOME/.pi/agent/extensions/$extension_name"
            echo "Linked extension: $extension -> ~/.pi/agent/extensions/$extension_name"
        done
    fi

    # Hook scripts (sounds, tmux window titles) are shared: Claude Code runs
    # them from its settings.json hook table, pi from the notifications
    # extension. Link the same files into both agents' config directories.
    #
    # Pi renamed hooks to extensions and warns on startup if ~/.pi/agent/hooks
    # still exists, so its copies live in ~/.pi/agent/scripts instead. Remove
    # the old directory if a previous bootstrap created it.
    if [ -d "agents/hooks" ]; then
        if [ -d "$HOME/.pi/agent/hooks" ]; then
            rm -rf "$HOME/.pi/agent/hooks"
            echo "Removed deprecated ~/.pi/agent/hooks"
        fi
        mkdir -p "$HOME/.claude/hooks" "$HOME/.pi/agent/scripts"
        for hook in agents/hooks/*.sh; do
            hook_name=$(basename "$hook")
            ln -sf "$PWD/$hook" "$HOME/.claude/hooks/$hook_name"
            ln -sf "$PWD/$hook" "$HOME/.pi/agent/scripts/$hook_name"
            echo "Linked hook: $PWD/$hook -> ~/.claude/hooks/$hook_name, ~/.pi/agent/scripts/$hook_name"
        done
    fi

    # Agent skills. Most are shared by Claude Code and the Pi coding agent, but
    # some only make sense for one of them, so each source directory declares
    # which agents it links into:
    #
    #   agents/skills          both agents (tracked)
    #   agents/skills-claude   Claude Code only (tracked)
    #   agents/skills-pi       Pi only (tracked)
    #   agents/skills-local    both agents (untracked, work-specific)
    #
    # Both agents discover skills through per-skill symlinks, so a skill works
    # the same way whichever directory it lives in.
    #
    # ~/.pi/agent/skills used to be a single symlink to agents/skills; replace
    # it with a real directory so local skills can live alongside tracked ones.
    if [ -L "$HOME/.pi/agent/skills" ]; then
        rm -f "$HOME/.pi/agent/skills"
    fi
    mkdir -p "$HOME/.claude/skills" "$HOME/.pi/agent/skills"
    mkdir -p "$HOME/.gemini/config/skills"

    for skills_spec in \
        "agents/skills:both" \
        "agents/skills-claude:claude" \
        "agents/skills-pi:pi" \
        "agents/skills-local:both"; do
        skills_root=${skills_spec%:*}
        skills_agents=${skills_spec##*:}
        [ -d "$skills_root" ] || continue
        for skill_dir in "$PWD/$skills_root"/*/; do
            [ -d "$skill_dir" ] || continue
            skill_name=$(basename "$skill_dir")
            targets=""
            case "$skills_agents" in
                both|claude)
                    ln -sfn "$skill_dir" "$HOME/.claude/skills/$skill_name"
                    targets="~/.claude/skills/$skill_name"
                    ;;
            esac
            case "$skills_agents" in
                both|pi)
                    ln -sfn "$skill_dir" "$HOME/.pi/agent/skills/$skill_name"
                    targets="${targets:+$targets, }~/.pi/agent/skills/$skill_name"
                    ;;
            esac
            echo "Linked skill: $skill_dir -> $targets"
        done
    done

    # agy only understands agent-agnostic skills, so it gets the shared and
    # local directories -- not agents/skills-claude or agents/skills-pi.
    for skills_root in "agents/skills" "agents/skills-local"; do
        [ -d "$skills_root" ] || continue
        for skill_dir in "$PWD/$skills_root"/*/; do
            [ -d "$skill_dir" ] || continue
            skill_name=$(basename "$skill_dir")
            ln -sfn "$skill_dir" "$HOME/.gemini/config/skills/$skill_name"
            echo "Linked skill: $skill_dir -> ~/.gemini/config/skills/$skill_name"
        done
    done

    # Moving a skill between those directories leaves the old symlink behind,
    # pointing at a path that no longer exists. A dangling link is invisible to
    # the agent, so the skill silently stops loading; prune them here.
    for skills_dest in "$HOME/.claude/skills" "$HOME/.pi/agent/skills" "$HOME/.gemini/config/skills"; do
        for skill_link in "$skills_dest"/*; do
            [ -L "$skill_link" ] || continue
            [ -e "$skill_link" ] && continue
            rm -f "$skill_link"
            echo "Pruned stale skill link: $skill_link"
        done
    done

    if [ -f ".claude/settings.local.json" ]; then
        python3 -c "
import json, sys

def deep_merge(base, local):
    # Recursively merge so nested dicts (e.g. permissions.ask and
    # permissions.allow) are combined rather than wholesale replaced.
    for key, value in local.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            deep_merge(base[key], value)
        elif isinstance(value, list) and isinstance(base.get(key), list):
            # Union lists (e.g. permissions.allow) so tracked base entries
            # and machine-local entries combine instead of local replacing
            # base wholesale.
            base[key] = base[key] + [v for v in value if v not in base[key]]
        else:
            base[key] = value
    return base

base = json.load(open('.claude/settings.json'))
local = json.load(open('.claude/settings.local.json'))
deep_merge(base, local)
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
