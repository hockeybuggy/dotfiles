#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# Unmatched globs expand to nothing rather than aborting. Every glob loop below
# guards each entry with a [ -f ]/[ -d ]/[ -L ] test, which is only reachable if
# an empty directory yields zero iterations instead of a "no matches found"
# error — an empty agents/skills-pi is a normal state, not a failure.
shopt -s nullglob

DOTFILES=$(cd "$(dirname "$0")" && pwd)
LINKED_FILES="$HOME/.dotfiles_linked_files"
MODE_FILE="$HOME/.dotfiles_mode"
INSTALL_MODE=""

source "$DOTFILES/lib/install-mode.sh"

# Define color variables
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)

function section() {
    printf '\n%s\n' "${GREEN}$1${RESET}"
}

# Paths inside the repo print relative to it, and paths under $HOME print with ~.
function short() {
    # shellcheck disable=SC2088
    case "$1" in
        "$DOTFILES"/*) printf '%s' "${1#"$DOTFILES"/}" ;;
        "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
        *) printf '%s' "$1" ;;
    esac
}

# Usage: report <label> <source> <destination>...
function report() {
    local label=$1 src=${2%/} dst
    shift 2
    printf '%s: %s\n' "$label" "$(short "$src")"
    for dst in "$@"; do
        printf '    -> %s\n' "$(short "$dst")"
    done
}

function usage() {
    install_mode_usage "./bootstrap.sh"
}

function parseArgs() {
    for arg in "$@"; do
        case "$arg" in
            --minimal|--work|--personal)
                mode=${arg#--}
                if [ -n "$INSTALL_MODE" ]; then
                    echo "Choose exactly one install mode." >&2
                    usage >&2
                    return 2
                fi
                INSTALL_MODE=$mode
                ;;
            -h|--help)
                usage
                return 64
                ;;
            *)
                echo "Unknown argument: $arg" >&2
                usage >&2
                return 2
                ;;
        esac
    done

    if ! install_mode_is_valid "$INSTALL_MODE"; then
        echo "An install mode is required." >&2
        usage >&2
        return 2
    fi
}

function doIt() {
    section "Symlinking files"
    new_linked_files="$LINKED_FILES.tmp.$$"
    : > "$new_linked_files"

    # Array of excluded files/directories (in addition to .gitignore)
    excluded=(
        ".git"
        ".claude"
        ".github"
        "agents"
        "lib"
        "test"
        "bootstrap.sh"
        "doctor.sh"
        "setup.sh"
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
            report "Linked" "$PWD/$file" "$HOME/$file"
            echo "$HOME/$file" >> "$new_linked_files"
        fi
    done

    # Unlink whatever the previous run linked that no longer exists here.
    if [ -f "$LINKED_FILES" ]; then
        while IFS= read -r link; do
            if [ -L "$link" ] && ! grep -qxF "$link" "$new_linked_files"; then
                rm "$link"
                echo "Removed stale link: $(short "$link")"
            fi
        done < "$LINKED_FILES"
    fi
    mv "$new_linked_files" "$LINKED_FILES"

    section "Setting up Claude Code config"
    mkdir -p "$HOME/.claude"
    # Claude Code only reads AGENTS.md from projects, so the global rules
    # still have to be linked in as CLAUDE.md.
    ln -sf "$PWD/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
    report "Linked" "$PWD/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"

    # Pi coding agent: share the same AGENTS.md as global context
    section "Setting up pi config"
    mkdir -p "$HOME/.pi/agent"
    [ -L "$HOME/.pi/agent/CLAUDE.md" ] && rm "$HOME/.pi/agent/CLAUDE.md"
    ln -sf "$PWD/agents/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
    report "Linked" "$PWD/agents/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"

    if [ -f ".config/mcp/mcp.json" ]; then
        ln -sf "$PWD/.config/mcp/mcp.json" "$HOME/.pi/agent/mcp.json"
        report "Linked" "$PWD/.config/mcp/mcp.json" "$HOME/.pi/agent/mcp.json"
    fi

    # Pi rewrites its settings file itself, so merge in the tracked defaults
    # rather than symlinking it, the same way as agy's settings below.
    python3 lib/merge-settings.py agents/pi/settings.json "$HOME/.pi/agent/settings.json"
    report "Merged" "$PWD/agents/pi/settings.json" "$HOME/.pi/agent/settings.json"

    # Pi records packages only in its own settings file, so uninstall the
    # ones earlier setups added by hand. pi-mcp-adapter would also replace Pi's
    # built-in MCP support.
    if command -v pi >/dev/null 2>&1; then
        for package in npm:pi-mcp-adapter npm:pi-web-access npm:@ifi/oh-pi-themes; do
            if grep -qF "\"$package\"" "$HOME/.pi/agent/settings.json" 2>/dev/null; then
                pi remove "$package" >/dev/null && echo "Removed pi package: $package"
            fi
        done
    fi

    # Antigravity CLI (agy): share the same AGENTS.md as global rules (agy
    # calls this GEMINI.md) and share the MCP server list.
    section "Setting up agy config"
    mkdir -p "$HOME/.gemini/config"
    ln -sf "$PWD/agents/AGENTS.md" "$HOME/.gemini/config/GEMINI.md"
    report "Linked" "$PWD/agents/AGENTS.md" "$HOME/.gemini/config/GEMINI.md"

    if [ -f ".config/mcp/mcp.json" ]; then
        ln -sf "$PWD/.config/mcp/mcp.json" "$HOME/.gemini/config/mcp_config.json"
        report "Linked" "$PWD/.config/mcp/mcp.json" "$HOME/.gemini/config/mcp_config.json"
    fi

    # agy reads one settings file and rewrites it itself, so it cannot be
    # symlinked -- agents/agy/settings.json is merged into it instead. That
    # tracked file carries only portable defaults (colour scheme, model, and
    # an allowlist of read-only commands); machine-local keys such as
    # trustedWorkspaces stay in the personal file and are never touched.
    #
    # The extra allow-rule is this repo's own path. ~/.gemini/config/skills/*
    # are symlinks that resolve back into here, which agy treats as a real
    # path outside whatever project it's running in. By default it denies
    # (interactively: prompts "outside workspace" for) any read of a path
    # outside the current workspace, which would otherwise make every shared
    # skill unreadable. Scoping the rule to this repo fixes that without
    # loosening access anywhere else on disk.
    mkdir -p "$HOME/.gemini/antigravity-cli"
    python3 lib/merge-settings.py \
        agents/agy/settings.json \
        "$HOME/.gemini/antigravity-cli/settings.json" \
        --allow-rule "read_file($PWD)"
    report "Merged" "$PWD/agents/agy/settings.json" "$HOME/.gemini/antigravity-cli/settings.json"

    section "Linking Pi extensions and agent skills"

    # Pi extensions are global and load from per-extension symlinks.
    if [ -d "agents/extensions" ]; then
        mkdir -p "$HOME/.pi/agent/extensions"
        for extension in "$PWD"/agents/extensions/*.ts; do
            [ -f "$extension" ] || continue
            extension_name=$(basename "$extension")
            ln -sfn "$extension" "$HOME/.pi/agent/extensions/$extension_name"
            report "Linked extension" "$extension" "$HOME/.pi/agent/extensions/$extension_name"
        done
    fi

    # The agent notification hooks (sounds, the shared notification log, tmux
    # window titles) are gone -- herdr surfaces agent state itself. Their
    # symlinks live outside the repo, so removing the sources doesn't unlink
    # them: prune what earlier bootstraps left behind. agy's hooks.json is the
    # one that matters, since a dangling link there makes every turn error.
    for stale in "$HOME/.gemini/config/hooks.json" "$HOME/.pi/agent/extensions/notifications.ts"; do
        if [ -L "$stale" ] && [ ! -e "$stale" ]; then
            rm -f "$stale"
            echo "Removed stale link: $(short "$stale")"
        fi
    done
    for stale_dir in "$HOME/.claude/hooks" "$HOME/.pi/agent/scripts" "$HOME/.pi/agent/hooks"; do
        if [ -d "$stale_dir" ]; then
            find "$stale_dir" -maxdepth 1 -type l ! -exec test -e {} \; -delete 2>/dev/null
            rmdir "$stale_dir" 2>/dev/null && echo "Removed empty $(short "$stale_dir")"
        fi
    done

    # Agent skills. Most are shared by Claude Code and the Pi coding agent, but
    # some only make sense for one of them, so each source directory declares
    # which agents it links into:
    #
    #   agents/skills          both agents (tracked)
    #   agents/skills-claude   Claude Code only (tracked)
    #   agents/skills-pi       Pi only (tracked)
    #   agents/skills-local    both agents (untracked, work-specific)
    #
    # agy only understands agent-agnostic skills, so it gets the "both"
    # directories too -- not agents/skills-claude or agents/skills-pi.
    #
    # The agents discover skills through per-skill symlinks, so a skill works
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
            targets=()
            case "$skills_agents" in
                both|claude) targets+=("$HOME/.claude/skills/$skill_name") ;;
            esac
            case "$skills_agents" in
                both|pi) targets+=("$HOME/.pi/agent/skills/$skill_name") ;;
            esac
            case "$skills_agents" in
                both) targets+=("$HOME/.gemini/config/skills/$skill_name") ;;
            esac
            for target in "${targets[@]}"; do
                ln -sfn "$skill_dir" "$target"
            done
            report "Linked skill" "$skill_dir" "${targets[@]}"
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
            echo "Pruned stale skill link: $(short "$skill_link")"
        done
    done

    section "Setting up Claude Code settings"
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
" "$HOME/.claude/settings.json"
        report "Merged" "$PWD/.claude/settings.json + settings.local.json" "$HOME/.claude/settings.json"
    else
        cp ".claude/settings.json" "$HOME/.claude/settings.json"
        report "Copied" "$PWD/.claude/settings.json" "$HOME/.claude/settings.json"
    fi

    section "Done"
}

if parseArgs "$@"; then
    parse_status=0
else
    parse_status=$?
fi
if [ "$parse_status" -eq 64 ]; then
    exit 0
elif [ "$parse_status" -ne 0 ]; then
    exit "$parse_status"
fi

cd "$DOTFILES"
setup_script=${DOTFILES_SETUP_SCRIPT:-"$DOTFILES/setup.sh"}
"$setup_script" "--$INSTALL_MODE"

doIt

mode_tmp="$MODE_FILE.tmp.$$"
printf '%s\n' "$INSTALL_MODE" > "$mode_tmp"
mv "$mode_tmp" "$MODE_FILE"
echo "Recorded install mode: $INSTALL_MODE ($(short "$MODE_FILE"))"

unset doIt
