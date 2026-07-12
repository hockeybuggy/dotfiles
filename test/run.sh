#!/usr/bin/env bash
#
# run.sh -- test ./setup on a clean Debian container.
#
# Builds a minimal Debian image, runs ./setup and ./bootstrap.sh inside a fresh
# container, then drives a tmux session (via verify.sh) to prove each installed
# tool actually runs.
#
# Usage:
#   ./test/run.sh                 # provision + automated tmux verification
#   ./test/run.sh --interactive   # provision, then drop into a zsh shell to poke

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
IMAGE=dotfiles-test
INTERACTIVE=0

case "${1:-}" in
    "") ;;
    -i|--interactive|--shell) INTERACTIVE=1 ;;
    -h|--help) echo "Usage: $0 [--interactive]"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Usage: $0 [--interactive]" >&2; exit 1 ;;
esac

echo "==> Building $IMAGE image"
docker build -t "$IMAGE" "$REPO_ROOT/test"

# Copy the read-only mount into a writable home, put the freshly installed
# binaries on PATH, then install + symlink. Single-quoted on purpose: these
# variables must expand inside the container, not on the host.
# shellcheck disable=SC2016
PROVISION='set -e
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
case "${TERM:-}" in ""|dumb) export TERM=xterm ;; esac   # bootstrap.sh/verify.sh call tput; a non-tty run gives TERM=dumb, which has no colour caps
cp -r /dotfiles "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
./setup
./bootstrap.sh'

if [ "$INTERACTIVE" -eq 1 ]; then
    echo "==> Provisioning, then dropping into an interactive shell"
    docker run --rm -it -v "$REPO_ROOT:/dotfiles:ro" "$IMAGE" bash -lc "
$PROVISION
echo
echo 'Provisioned. Try: tmux, then eza --long / btm / rg / fzf / starship'
exec zsh -l"
else
    echo "==> Provisioning and verifying"
    docker run --rm -v "$REPO_ROOT:/dotfiles:ro" "$IMAGE" bash -lc "
$PROVISION
exec ./test/verify.sh"
fi
