#!/usr/bin/env bash
#
# doctor.sh -- report whether this machine has a healthy dotfiles setup.

set -uo pipefail

DOTFILES=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib/install-mode.sh
. "$DOTFILES/lib/install-mode.sh"
MODE_FILE="$HOME/.dotfiles_mode"
INSTALL_MODE=""
BOOTSTRAP_HINT="run ./bootstrap.sh --minimal, --work, or --personal"
STRICT=0
CI=0
OK_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

if [ -t 1 ] && command -v tput >/dev/null 2>&1; then
    GREEN=$(tput setaf 2 2>/dev/null || echo)
    YELLOW=$(tput setaf 3 2>/dev/null || echo)
    RED=$(tput setaf 1 2>/dev/null || echo)
    BOLD=$(tput bold 2>/dev/null || echo)
    RESET=$(tput sgr0 2>/dev/null || echo)
else
    GREEN=""; YELLOW=""; RED=""; BOLD=""; RESET=""
fi

have() { command -v "$1" >/dev/null 2>&1; }

usage() {
    echo "Usage: ./doctor.sh [--strict] [--ci]"
}

section() {
    echo
    echo "${BOLD}$*${RESET}"
}

pass() {
    OK_COUNT=$((OK_COUNT + 1))
    printf '  %s✓%s  %-28s %s\n' "$GREEN" "$RESET" "$1" "$2"
}

warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
    printf '  %s!%s  %-28s %s\n' "$YELLOW" "$RESET" "$1" "$2"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  %s✗%s  %-28s %s\n' "$RED" "$RESET" "$1" "$2"
}

note() {
    printf '  %-31s %s\n' "$1" "$2"
}

for arg in "$@"; do
    case "$arg" in
        --strict) STRICT=1 ;;
        --ci) CI=1 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

section "Install mode"
if [ ! -f "$MODE_FILE" ]; then
    fail "Install mode" "missing; $BOOTSTRAP_HINT"
elif IFS= read -r INSTALL_MODE < "$MODE_FILE" && install_mode_is_valid "$INSTALL_MODE"; then
    pass "Mode" "$INSTALL_MODE ($MODE_FILE)"
    BOOTSTRAP_HINT="run ./bootstrap.sh --$INSTALL_MODE"
else
    fail "Install mode" "invalid in $MODE_FILE; run ./bootstrap.sh with exactly one mode"
    INSTALL_MODE=""
fi

# Compare dotted numeric versions, ignoring non-numeric suffixes.
version_ge() {
    awk -v actual="$1" -v required="$2" 'BEGIN {
        split(actual, a, "."); split(required, r, ".")
        for (i = 1; i <= 4; i++) {
            a[i] += 0; r[i] += 0
            if (a[i] > r[i]) exit 0
            if (a[i] < r[i]) exit 1
        }
        exit 0
    }'
}

check_tool() {
    label="$1"
    command_name="$2"
    if have "$command_name"; then
        pass "$label" "$(command -v "$command_name")"
    else
        fail "$label" "missing; $BOOTSTRAP_HINT"
    fi
}

check_optional_tool() {
    label="$1"
    command_name="$2"
    if have "$command_name"; then
        pass "$label" "$(command -v "$command_name")"
    else
        warn "$label" "optional; install $command_name"
    fi
}

check_min_version() {
    label="$1"
    command_name="$2"
    actual="$3"
    required="$4"
    if ! have "$command_name"; then
        fail "$label" "missing; $BOOTSTRAP_HINT"
    elif [ -z "$actual" ]; then
        fail "$label" "could not determine version"
    elif version_ge "$actual" "$required"; then
        pass "$label" "$actual (>= $required)"
    else
        fail "$label" "$actual is too old; require >= $required"
    fi
}

check_python_on_path() {
    label="$1"
    command_name="$2"
    if ! have "$command_name"; then
        return
    fi
    resolved=$(command -v "$command_name")
    actual=$("$command_name" --version 2>&1 | awk '{print $2}')
    newest=""
    if have uv; then
        newest=$(uv python list --only-installed 2>/dev/null \
            | awk '$1 ~ /^cpython-/ {print $1}' \
            | sed -E 's/^cpython-([0-9]+\.[0-9]+\.[0-9]+).*/\1/' \
            | sort -V | tail -1)
    fi
    if [ -z "$actual" ]; then
        fail "$label" "could not determine version"
    elif [ -n "$newest" ] && ! version_ge "$actual" "$newest"; then
        warn "$label" "$actual is outdated; $newest is installed (try 'uv python upgrade' or check PATH order)"
    else
        pass "$label" "$resolved ($actual)"
    fi
}

check_repo_link() {
    label="$1"
    link="$2"
    if [ ! -L "$link" ]; then
        if [ -e "$link" ]; then
            fail "$label" "$link is not a symlink; run ./bootstrap.sh"
        else
            fail "$label" "$link is missing; run ./bootstrap.sh"
        fi
        return
    fi
    if [ ! -e "$link" ]; then
        fail "$label" "$link is dangling; run ./bootstrap.sh"
        return
    fi
    target=$(readlink "$link")
    case "$target" in
        "$DOTFILES"|"$DOTFILES"/*) pass "$label" "$target" ;;
        *) fail "$label" "points outside $DOTFILES; run ./bootstrap.sh" ;;
    esac
}

section "Platform"
note "OS" "$(uname -s)"
note "Architecture" "$(uname -m)"
note "Shell" "${SHELL:-unknown}"

section "Required tools"
nvim_version=""
tmux_version=""
zsh_version=""
if have nvim; then nvim_version=$(nvim --version 2>/dev/null | awk 'NR == 1 {gsub(/^v/, "", $2); print $2}'); fi
if have tmux; then tmux_version=$(tmux -V 2>/dev/null | awk '{print $2}'); fi
if have zsh; then zsh_version=$(zsh --version 2>/dev/null | awk '{print $2}'); fi
# Neovim calls its 0.11 release "11.0" in the dependency documentation.
check_min_version "neovim" nvim "$nvim_version" "0.11.0"
check_min_version "tmux" tmux "$tmux_version" "3.5"
check_min_version "zsh" zsh "$zsh_version" "5.0"
check_tool "git" git
check_tool "fzf" fzf
check_tool "ripgrep (rg)" rg
check_tool "fd" fd
check_tool "bat" bat
check_tool "eza" eza
check_tool "bottom (btm)" btm
check_tool "starship" starship
check_tool "zoxide" zoxide
check_tool "fnm" fnm
check_tool "node" node
check_tool "npm" npm
check_tool "python3" python3
if have pip; then
    pass "pip" "$(command -v pip)"
elif have pip3; then
    pass "pip" "$(command -v pip3)"
else
    fail "pip" "missing; $BOOTSTRAP_HINT"
fi

if install_mode_has "$INSTALL_MODE" development; then
    check_tool "uv" uv
    check_tool "gnupg (gpg)" gpg
    check_tool "diff-so-fancy" diff-so-fancy
    check_tool "markdownlint" markdownlint
    check_tool "cargo" cargo
    check_tool "rustc" rustc
    check_tool "ruff" ruff
    check_tool "ty" ty
    check_tool "pgcli" pgcli
    if have uv && uv python find --managed-python 3.14 --show-version 2>/dev/null | grep -Eq '^3\.14\.'; then
        pass "uv-managed Python 3.14" "installed"
    else
        fail "uv-managed Python 3.14" "missing; $BOOTSTRAP_HINT"
    fi
    check_python_on_path "python3 (PATH)" python3
    check_python_on_path "python (PATH)" python
fi

if [ "$(uname -s)" = "Darwin" ] && install_mode_has "$INSTALL_MODE" workstation; then
    check_tool "reattach-to-user-namespace" reattach-to-user-namespace
    if have brew && brew list --versions uutils-coreutils 2>/dev/null | grep -q .; then
        pass "uutils-coreutils" "installed by Homebrew"
    else
        fail "uutils-coreutils" "missing; $BOOTSTRAP_HINT"
    fi
fi

section "Config linked correctly"
manifest="$HOME/.dotfiles_linked_files"
if [ ! -f "$manifest" ]; then
    fail "Linked-files manifest" "missing; run ./bootstrap.sh"
else
    pass "Linked-files manifest" "$manifest"
    while IFS= read -r link || [ -n "$link" ]; do
        [ -n "$link" ] && check_repo_link "$(printf '%s' "$link" | sed "s|^$HOME/||")" "$link"
    done < "$manifest"
fi
check_repo_link "Claude CLAUDE.md" "$HOME/.claude/CLAUDE.md"
check_repo_link "pi CLAUDE.md" "$HOME/.pi/agent/CLAUDE.md"
check_repo_link "agy GEMINI.md" "$HOME/.gemini/config/GEMINI.md"
for hook in "$DOTFILES"/agents/hooks/*.sh; do
    [ -e "$hook" ] || continue
    check_repo_link "Claude hook $(basename "$hook")" "$HOME/.claude/hooks/$(basename "$hook")"
    check_repo_link "Pi hook $(basename "$hook")" "$HOME/.pi/agent/scripts/$(basename "$hook")"
done
if [ -f "$HOME/.claude/settings.json" ]; then
    pass "Claude settings" "$HOME/.claude/settings.json exists"
else
    fail "Claude settings" "missing; run ./bootstrap.sh"
fi
if [ -f "$DOTFILES/agents/agy/hooks.json" ]; then
    check_repo_link "agy hooks.json" "$HOME/.gemini/config/hooks.json"
fi
if [ -f "$DOTFILES/.config/mcp/mcp.json" ]; then
    check_repo_link "agy mcp_config.json" "$HOME/.gemini/config/mcp_config.json"
fi
agy_settings="$HOME/.gemini/antigravity-cli/settings.json"
if [ -f "$agy_settings" ] && python3 -c "
import json, sys
rule = 'read_file(' + sys.argv[2] + ')'
allow = json.load(open(sys.argv[1])).get('permissions', {}).get('allow', [])
sys.exit(0 if rule in allow else 1)
" "$agy_settings" "$DOTFILES" 2>/dev/null; then
    pass "agy read_file allow-rule" "$DOTFILES"
else
    warn "agy read_file allow-rule" "missing; run ./bootstrap.sh (needed to read shared skills)"
fi

section "Coding agents"
if install_mode_has "$INSTALL_MODE" claude; then
    check_tool "Claude Code" claude
else
    note "Claude Code" "not required for $INSTALL_MODE mode"
fi
if install_mode_has "$INSTALL_MODE" pi; then
    check_tool "Pi" pi
else
    note "Pi" "not required for $INSTALL_MODE mode"
fi
if install_mode_has "$INSTALL_MODE" agy; then
    check_tool "Antigravity CLI (agy)" agy
else
    note "Antigravity CLI (agy)" "not required for $INSTALL_MODE mode"
fi
# Skills link per-agent: agents/skills goes to all three agents,
# agents/skills-claude to Claude Code only, agents/skills-pi to Pi only.
# Count each agent only against the directories that target it.
if [ -d "$DOTFILES/agents/skills" ]; then
    claude_total=0; claude_linked=0; pi_total=0; pi_linked=0; agy_total=0; agy_linked=0
    for skills_spec in \
        "agents/skills:both" \
        "agents/skills-claude:claude" \
        "agents/skills-pi:pi"; do
        skills_root="$DOTFILES/${skills_spec%:*}"
        skills_agents=${skills_spec##*:}
        [ -d "$skills_root" ] || continue
        for skill_dir in "$skills_root"/*/; do
            [ -d "$skill_dir" ] || continue
            skill_name=$(basename "$skill_dir")
            case "$skills_agents" in
                both|claude)
                    claude_total=$((claude_total + 1))
                    case "$(readlink "$HOME/.claude/skills/$skill_name" 2>/dev/null)" in
                        "$DOTFILES"/*) claude_linked=$((claude_linked + 1)) ;;
                    esac
                    ;;
            esac
            case "$skills_agents" in
                both|pi)
                    pi_total=$((pi_total + 1))
                    case "$(readlink "$HOME/.pi/agent/skills/$skill_name" 2>/dev/null)" in
                        "$DOTFILES"/*) pi_linked=$((pi_linked + 1)) ;;
                    esac
                    ;;
            esac
            case "$skills_agents" in
                both)
                    agy_total=$((agy_total + 1))
                    case "$(readlink "$HOME/.gemini/config/skills/$skill_name" 2>/dev/null)" in
                        "$DOTFILES"/*) agy_linked=$((agy_linked + 1)) ;;
                    esac
                    ;;
            esac
        done
    done
    if [ "$claude_total" -gt 0 ] && [ "$claude_linked" -eq "$claude_total" ]; then
        pass "Claude skills linked" "$claude_linked/$claude_total"
    else
        warn "Claude skills linked" "$claude_linked/$claude_total linked; run ./bootstrap.sh"
    fi
    if [ "$pi_total" -gt 0 ] && [ "$pi_linked" -eq "$pi_total" ]; then
        pass "Pi skills linked" "$pi_linked/$pi_total"
    else
        warn "Pi skills linked" "$pi_linked/$pi_total linked; run ./bootstrap.sh"
    fi
    if [ "$agy_total" -gt 0 ] && [ "$agy_linked" -eq "$agy_total" ]; then
        pass "agy skills linked" "$agy_linked/$agy_total"
    else
        warn "agy skills linked" "$agy_linked/$agy_total linked; run ./bootstrap.sh"
    fi
    # A skill moved between those directories leaves a dangling symlink, which
    # the agent silently ignores. Bootstrap prunes them; report any that remain.
    stale=0
    for skills_dest in "$HOME/.claude/skills" "$HOME/.pi/agent/skills" "$HOME/.gemini/config/skills"; do
        for skill_link in "$skills_dest"/*; do
            [ -L "$skill_link" ] || continue
            [ -e "$skill_link" ] || stale=$((stale + 1))
        done
    done
    if [ "$stale" -eq 0 ]; then
        pass "Skill links resolve" "no dangling links"
    else
        warn "Skill links resolve" "$stale dangling; run ./bootstrap.sh"
    fi
else
    warn "Agent skills" "agents/skills missing from repo"
fi
if [ -d "$DOTFILES/agents/extensions" ]; then
    total=0; linked=0
    for extension in "$DOTFILES"/agents/extensions/*.ts; do
        [ -f "$extension" ] || continue
        total=$((total + 1))
        case "$(readlink "$HOME/.pi/agent/extensions/$(basename "$extension")" 2>/dev/null)" in
            "$DOTFILES"/*) linked=$((linked + 1)) ;;
        esac
    done
    if [ "$total" -gt 0 ] && [ "$linked" -eq "$total" ]; then
        pass "Pi extensions linked" "$linked/$total from agents/extensions"
    else
        warn "Pi extensions linked" "$linked/$total linked; run ./bootstrap.sh"
    fi
fi

section "Shell & environment"
if [ "$CI" -eq 1 ]; then
    note "Default login shell" "skipped with --ci"
else
    login_shell="${SHELL:-}"
    if [ "$(uname -s)" = "Darwin" ] && have dscl; then
        detected_shell=$(dscl . -read "$HOME" UserShell 2>/dev/null | awk '{print $2}')
        [ -n "$detected_shell" ] && login_shell="$detected_shell"
    fi
    case "$login_shell" in
        */zsh) pass "Default login shell" "$login_shell" ;;
        *) warn "Default login shell" "not zsh; run chsh -s \"$(command -v zsh 2>/dev/null || echo /bin/zsh)\"" ;;
    esac
fi
case ":$PATH:" in *":$HOME/.local/bin:"*) pass "PATH: ~/.local/bin" "present" ;; *) warn "PATH: ~/.local/bin" "add it in ~/.zshrc" ;; esac
case ":$PATH:" in *":$HOME/.cargo/bin:"*) pass "PATH: ~/.cargo/bin" "present" ;; *) warn "PATH: ~/.cargo/bin" "add it in ~/.zshrc" ;; esac
fnm_dir="$HOME/.local/share/fnm"
case ":$PATH:" in *":$fnm_dir:"*) pass "PATH: fnm" "$fnm_dir" ;; *) warn "PATH: fnm" "add $fnm_dir in ~/.zshrc" ;; esac
if [ "${EDITOR:-}" = "nvim" ]; then pass "EDITOR" "nvim"; else warn "EDITOR" "set EDITOR=nvim in ~/.zshrc"; fi
if have zsh; then
    zsh_stderr=$(mktemp "${TMPDIR:-/tmp}/doctor-zsh.XXXXXX")
    if zsh -ic 'exit' >/dev/null 2>"$zsh_stderr" && [ ! -s "$zsh_stderr" ]; then
        pass ".zshrc loads cleanly" "no stderr"
    else
        detail=$(head -n 1 "$zsh_stderr")
        warn ".zshrc loads cleanly" "${detail:-non-zero exit}; run zsh -ic exit"
    fi
    rm -f "$zsh_stderr"
else
    warn ".zshrc loads cleanly" "zsh is unavailable"
fi

if [ "$CI" -eq 1 ]; then
    note "Zsh local config" "skipped with --ci"
elif [ -f "$HOME/.zshrc.local" ]; then
    pass "Zsh local config" "$HOME/.zshrc.local"
else
    note "Zsh local config" "optional; copy ~/.dotfiles/.zshrc.local.example"
fi

section "Git configuration"
git_name=$(git config --global --get user.name 2>/dev/null || true)
git_email=$(git config --global --get user.email 2>/dev/null || true)
if [ -n "$git_name" ]; then pass "Git user.name" "$git_name"; else fail "Git user.name" "set git config --global user.name"; fi
if [ -n "$git_email" ]; then pass "Git user.email" "$git_email"; else fail "Git user.email" "set git config --global user.email"; fi
template=$(git config --global --get commit.template 2>/dev/null || true)
case "$template" in
    \~/.gitmessage|"$HOME/.gitmessage") pass "Git commit template" "$template" ;;
    *) warn "Git commit template" "set commit.template to ~/.gitmessage" ;;
esac
pager=$(git config --global --get core.pager 2>/dev/null || true)
case "$pager" in
    *diff-so-fancy*|*git-pager.sh*) pass "Git pager" "$pager" ;;
    *) warn "Git pager" "configure diff-so-fancy or ~/.dotfiles/.bin/git-pager.sh" ;;
esac
if [ "$CI" -eq 1 ]; then
    note "Git local config" "skipped with --ci"
elif [ -f "$HOME/.gitconfig.local" ]; then
    pass "Git local config" "$HOME/.gitconfig.local"
else
    warn "Git local config" "copy ~/.dotfiles/.gitconfig.local.example"
fi

section "Optional dependencies"
if install_mode_has "$INSTALL_MODE" development; then
    if install_mode_has "$INSTALL_MODE" personal; then
        check_optional_tool "luarocks" luarocks
        check_optional_tool "stylua" stylua
    fi
    check_optional_tool "rbenv" rbenv
    check_optional_tool "rubocop" rubocop
    check_optional_tool "solargraph" solargraph
    check_optional_tool "prettier" prettier
else
    note "Development extras" "not checked in minimal mode"
fi
if [ "$CI" -eq 1 ]; then
    note "Machine-only checks" "skipped with --ci"
else
    if [ "$(uname -s)" = "Darwin" ] && install_mode_has "$INSTALL_MODE" workstation; then
        if find "$HOME/Library/Fonts" /Library/Fonts -iname '*Inconsolata*Nerd*' -print 2>/dev/null | grep -q .; then
            pass "Inconsolata Nerd Font" "installed"
        else
            warn "Inconsolata Nerd Font" "run brew install --cask font-inconsolata-nerd-font"
        fi
    elif [ "$(uname -s)" != "Darwin" ] && install_mode_has "$INSTALL_MODE" workstation; then
        if have fc-list && fc-list 2>/dev/null | grep -qi 'Inconsolata.*Nerd'; then
            pass "Inconsolata Nerd Font" "installed"
        else
            warn "Inconsolata Nerd Font" "install the Inconsolata Nerd Font"
        fi
    fi
    if [ "$(uname -s)" = "Darwin" ] && install_mode_has "$INSTALL_MODE" personal; then
        check_optional_tool "duti" duti
        if [ -d "$HOME/Applications/Open in Neovim.app" ]; then
            pass "Open in Neovim handler" "installed"
        else
            warn "Open in Neovim handler" "run ./bootstrap.sh --personal"
        fi
        if [ -d "/Applications/iTerm.app" ]; then pass "iTerm2" "installed"; else warn "iTerm2" "optional terminal is not installed"; fi
        if [ -d "/Applications/Ghostty.app" ]; then pass "Ghostty" "installed"; else warn "Ghostty" "optional terminal is not installed"; fi
    fi
fi

section "Summary"
printf '  %s✓%s %d OK   %s!%s %d WARN   %s✗%s %d FAIL\n' \
    "$GREEN" "$RESET" "$OK_COUNT" "$YELLOW" "$RESET" "$WARN_COUNT" "$RED" "$RESET" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ] || { [ "$STRICT" -eq 1 ] && [ "$WARN_COUNT" -gt 0 ]; }; then
    exit 1
fi
exit 0
