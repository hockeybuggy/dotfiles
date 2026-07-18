#!/usr/bin/env bash
#
# verify.sh -- run inside the test container after ./setup.sh and ./bootstrap.sh.
#
# Drives a tmux session running a login zsh and exercises each installed tool,
# capturing its output to prove it actually runs. Prints a pass/fail summary
# and exits non-zero if anything is missing.

set -uo pipefail

if command -v tput >/dev/null 2>&1 && [ -n "${TERM:-}" ]; then
    GREEN=$(tput setaf 2 2>/dev/null || echo); RED=$(tput setaf 1 2>/dev/null || echo)
    BOLD=$(tput bold 2>/dev/null || echo); RESET=$(tput sgr0 2>/dev/null || echo)
else
    GREEN=""; RED=""; BOLD=""; RESET=""
fi

# Make every installed tool resolvable regardless of the .zshrc fnm path quirk.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/fnm:$PATH"
# shellcheck source=/dev/null
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --shell bash)" 2>/dev/null || true
    fnm use lts-latest >/dev/null 2>&1 || true
fi

# "label|command" -- the command must exit 0. Most print a version; diff-so-fancy
# is a stdin filter with no version flag (it would block on the pane's tty), so we
# just confirm it resolves on PATH.
checks=(
    "eza|eza --version"
    "bat|bat --version"
    "ripgrep (rg)|rg --version"
    "fd|fd --version"
    "fzf|fzf --version"
    "bottom (btm)|btm --version"
    "starship|starship --version"
    "zoxide|zoxide --version"
    "neovim|nvim --version"
    "tmux|tmux -V"
    "zsh|zsh --version"
    "git|git --version"
    "cargo|cargo --version"
    "rustc|rustc --version"
    "uv|uv --version"
    "Python 3.14|uv python find --managed-python 3.14 --show-version | grep -Eq '^3\\.14\\.'"
    "python3|python3 --version"
    "ruff|ruff --version"
    "ty|ty --version"
    "pgcli|pgcli --version"
    "pip|pip3 --version"
    "node|node --version"
    "npm|npm --version"
    "diff-so-fancy|command -v diff-so-fancy"
    "markdownlint|markdownlint --version"
    "Claude Code|claude --version"
    "Pi|pi --version"
)

SOCK="verify"
tmux -L "$SOCK" kill-server 2>/dev/null || true
# A login zsh so the demo runs through the real .zshrc (aliases, starship, ...).
tmux -L "$SOCK" new-session -d -s v -x 220 -y 60 zsh
# Give the shell a moment to source .zshrc before we start driving it.
sleep 2

results=()   # "label|status|detail"
failures=0

echo "${BOLD}Exercising tools in tmux...${RESET}"
for i in "${!checks[@]}"; do
    label="${checks[$i]%%|*}"
    cmd="${checks[$i]#*|}"

    # Fresh screen per check keeps capture-pane unambiguous. The DONE marker is
    # built with a %d format so the *typed* command line (which shows the literal
    # "%d") never matches the resolved "DONE_i_RCn" we poll for.
    tmux -L "$SOCK" send-keys -t v \
        "clear; printf '### %s ###\\n' \"$label\"; $cmd; printf 'DONE_${i}_RC%d\\n' \"\$?\"" Enter

    out=""
    for _ in $(seq 1 60); do
        out=$(tmux -L "$SOCK" capture-pane -p -t v 2>/dev/null || echo)
        if printf '%s\n' "$out" | grep -Eq "DONE_${i}_RC[0-9]"; then
            break
        fi
        sleep 0.25
    done

    rc=$(printf '%s\n' "$out" | sed -n "s/.*DONE_${i}_RC\([0-9][0-9]*\).*/\1/p" | tail -1)
    # First line of the command's own output, for the summary.
    detail=$(printf '%s\n' "$out" | awk '/^### /{f=1;next} /DONE_'"$i"'_RC/{f=0} f && NF {print; exit}')

    if [ "${rc:-1}" = "0" ]; then
        results+=("$label|ok|$detail")
        printf '  %s✓%s %-16s %s\n' "$GREEN" "$RESET" "$label" "$detail"
    else
        results+=("$label|FAIL|not found / non-zero exit")
        failures=$((failures + 1))
        printf '  %s✗%s %-16s %s\n' "$RED" "$RESET" "$label" "not found / non-zero exit"
    fi
done

tmux -L "$SOCK" kill-server 2>/dev/null || true

echo
echo "${BOLD}Summary${RESET}"
printf '%s\n' "-------------------------------------------------------------"
for r in "${results[@]}"; do
    label="${r%%|*}"; rest="${r#*|}"; status="${rest%%|*}"; detail="${rest#*|}"
    if [ "$status" = "ok" ]; then
        printf '  %s%-6s%s %-16s %s\n' "$GREEN" "PASS" "$RESET" "$label" "$detail"
    else
        printf '  %s%-6s%s %-16s %s\n' "$RED" "FAIL" "$RESET" "$label" "$detail"
    fi
done
printf '%s\n' "-------------------------------------------------------------"

total=${#checks[@]}
passed=$((total - failures))
if [ "$failures" -eq 0 ]; then
    echo "${GREEN}${BOLD}All $total tools verified.${RESET}"
    exit 0
else
    echo "${RED}${BOLD}$passed/$total passed, $failures failed.${RESET}"
    exit 1
fi
