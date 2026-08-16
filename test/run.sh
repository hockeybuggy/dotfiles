#!/usr/bin/env bash
#
# run.sh -- test ./setup.sh on a clean Debian container.
#
# Builds a minimal Debian image, runs ./setup.sh and ./bootstrap.sh inside a fresh
# container, then drives a tmux session (via verify.sh) to prove each installed
# tool actually runs.
#
# Usage:
#   ./test/run.sh [--mode MODE]                 # provision + tmux verification
#   ./test/run.sh [--mode MODE] --interactive   # provision, then open a shell

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
"$REPO_ROOT/test/setup-script-name.sh"
"$REPO_ROOT/test/install-mode.sh"
"$REPO_ROOT/test/setup-modes.sh"
"$REPO_ROOT/test/mode-ci.sh"
"$REPO_ROOT/test/setup-pgcli.sh"
"$REPO_ROOT/test/pi-pane-pretty.sh"
"$REPO_ROOT/test/agy-pane-pretty.sh"

IMAGE=dotfiles-test
INTERACTIVE=0
mode=personal

while [ "$#" -gt 0 ]; do
    case "$1" in
        --mode)
            [ "$#" -ge 2 ] || { echo "Missing mode after --mode" >&2; exit 2; }
            mode=$2
            shift 2
            ;;
        -i|--interactive|--shell)
            INTERACTIVE=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--mode minimal|work|personal] [--interactive]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: $0 [--mode minimal|work|personal] [--interactive]" >&2
            exit 2
            ;;
    esac
done
case "$mode" in
    minimal|work|personal) ;;
    *) echo "Unknown mode: $mode" >&2; exit 2 ;;
esac

echo "==> Building $IMAGE image"
docker build -t "$IMAGE" "$REPO_ROOT/test"

# Copy the read-only mount into a writable home, put the freshly installed
# binaries on PATH, then install + symlink. Single-quoted on purpose: these
# variables must expand inside the container, not on the host.
# shellcheck disable=SC2016
PROVISION='set -e
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/fnm:$PATH"
case "${TERM:-}" in ""|dumb) export TERM=xterm ;; esac   # bootstrap.sh/verify.sh call tput; a non-tty run gives TERM=dumb, which has no colour caps
cp -r /dotfiles "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
./bootstrap.sh --"$MODE"
git -C "$HOME" config --global user.name "Dot Files"
git -C "$HOME" config --global user.email "dotfiles@example.com"
export EDITOR=nvim
eval "$(fnm env --shell bash)"
fnm use lts-latest >/dev/null'

case "$mode" in
    minimal|personal) agent_test='./test/pi-clear-alias.sh' ;;
    work) agent_test=':' ;;
esac

if [ "$INTERACTIVE" -eq 1 ]; then
    echo "==> Provisioning, then dropping into an interactive shell"
    docker run --rm -it -e MODE="$mode" -v "$REPO_ROOT:/dotfiles:ro" "$IMAGE" bash -lc "
$PROVISION
echo
echo 'Provisioned. Try: tmux, then eza --long / btm / rg / fzf / starship'
exec zsh -l"
else
    echo "==> Provisioning and verifying"
    docker run --rm -e MODE="$mode" -v "$REPO_ROOT:/dotfiles:ro" "$IMAGE" bash -lc "
$PROVISION
$agent_test
./test/verify.sh --mode \"$mode\"
(cd \"\$HOME\" && \"\$HOME/.dotfiles/doctor.sh\" --ci)"
fi
