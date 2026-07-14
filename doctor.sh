#!/usr/bin/env bash
#
# doctor.sh -- report whether this machine has a healthy dotfiles setup.

set -uo pipefail

DOTFILES=$(cd "$(dirname "$0")" && pwd)
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
        fail "$label" "missing; run ./setup.sh"
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
        fail "$label" "missing; run ./setup.sh"
    elif [ -z "$actual" ]; then
        fail "$label" "could not determine version"
    elif version_ge "$actual" "$required"; then
        pass "$label" "$actual (>= $required)"
    else
        fail "$label" "$actual is too old; require >= $required"
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
check_tool "uv" uv
check_tool "fnm" fnm
check_tool "gnupg (gpg)" gpg
check_tool "diff-so-fancy" diff-so-fancy
check_tool "node" node
check_tool "npm" npm
check_tool "markdownlint" markdownlint
check_tool "cargo" cargo
check_tool "rustc" rustc
check_tool "python3" python3
check_tool "ruff" ruff
check_tool "ty" ty
if have pip; then
    pass "pip" "$(command -v pip)"
elif have pip3; then
    pass "pip" "$(command -v pip3)"
else
    fail "pip" "missing; run ./setup.sh"
fi
if have uv && uv python find --managed-python 3.14 --show-version 2>/dev/null | grep -Eq '^3\.14\.'; then
    pass "uv-managed Python 3.14" "installed"
else
    fail "uv-managed Python 3.14" "missing; run uv python install 3.14"
fi
if [ "$(uname -s)" = "Darwin" ]; then
    check_tool "reattach-to-user-namespace" reattach-to-user-namespace
    if have brew && brew list --versions uutils-coreutils 2>/dev/null | grep -q .; then
        pass "uutils-coreutils" "installed by Homebrew"
    else
        fail "uutils-coreutils" "missing; run brew install uutils-coreutils"
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
for hook in "$DOTFILES"/.claude/hooks/*.sh; do
    [ -e "$hook" ] || continue
    check_repo_link "Claude hook $(basename "$hook")" "$HOME/.claude/hooks/$(basename "$hook")"
done
if [ -f "$HOME/.claude/settings.json" ]; then
    pass "Claude settings" "$HOME/.claude/settings.json exists"
else
    fail "Claude settings" "missing; run ./bootstrap.sh"
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
check_optional_tool "luarocks" luarocks
check_optional_tool "stylua" stylua
check_optional_tool "rbenv" rbenv
check_optional_tool "rubocop" rubocop
check_optional_tool "solargraph" solargraph
check_optional_tool "prettier" prettier
if [ "$CI" -eq 1 ]; then
    note "Machine-only checks" "skipped with --ci"
else
    # Agent skills live in agents/skills and are linked out to both Claude Code
    # (per-skill symlinks) and Pi (one directory symlink) by bootstrap.sh.
    if [ -d "$DOTFILES/agents/skills" ]; then
        total=0; linked=0
        for skill_dir in "$DOTFILES"/agents/skills/*/; do
            [ -d "$skill_dir" ] || continue
            total=$((total + 1))
            case "$(readlink "$HOME/.claude/skills/$(basename "$skill_dir")" 2>/dev/null)" in
                "$DOTFILES"/*) linked=$((linked + 1)) ;;
            esac
        done
        if [ "$total" -gt 0 ] && [ "$linked" -eq "$total" ]; then
            pass "Claude skills linked" "$linked/$total from agents/skills"
        else
            warn "Claude skills linked" "$linked/$total linked; run ./bootstrap.sh"
        fi
        check_repo_link "pi skills" "$HOME/.pi/agent/skills"
    else
        warn "Agent skills" "agents/skills missing from repo"
    fi
    if [ "$(uname -s)" = "Darwin" ]; then
        if find "$HOME/Library/Fonts" /Library/Fonts -iname '*Inconsolata*Nerd*' -print 2>/dev/null | grep -q .; then
            pass "Inconsolata Nerd Font" "installed"
        else
            warn "Inconsolata Nerd Font" "run brew install --cask font-inconsolata-nerd-font"
        fi
        if [ -d "/Applications/iTerm.app" ]; then pass "iTerm2" "installed"; else warn "iTerm2" "optional terminal is not installed"; fi
        if [ -d "/Applications/Ghostty.app" ]; then pass "Ghostty" "installed"; else warn "Ghostty" "optional terminal is not installed"; fi
    elif have fc-list; then
        if fc-list 2>/dev/null | grep -qi 'Inconsolata.*Nerd'; then pass "Inconsolata Nerd Font" "installed"; else warn "Inconsolata Nerd Font" "install the Inconsolata Nerd Font"; fi
    else
        warn "Inconsolata Nerd Font" "cannot check without fc-list"
    fi
fi

section "Summary"
printf '  %s✓%s %d OK   %s!%s %d WARN   %s✗%s %d FAIL\n' \
    "$GREEN" "$RESET" "$OK_COUNT" "$YELLOW" "$RESET" "$WARN_COUNT" "$RED" "$RESET" "$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ] || { [ "$STRICT" -eq 1 ] && [ "$WARN_COUNT" -gt 0 ]; }; then
    exit 1
fi
exit 0
