#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMPDIR_ROOT=$(mktemp -d)
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Source function definitions without running installers.
DOTFILES="$ROOT" DOTFILES_SETUP_SOURCE_ONLY=1 source "$ROOT/setup.sh"

minimal_macos=$(macos_formulae minimal)
work_macos=$(macos_formulae work)
personal_macos=$(macos_formulae personal)
minimal_linux=$(linux_apt_packages minimal)
work_linux=$(linux_apt_packages work)

printf '%s\n' "$minimal_macos" | grep -qw neovim || fail "minimal macOS omits neovim"
printf '%s\n' "$minimal_macos" | grep -qw fnm || fail "minimal macOS omits fnm"
printf '%s\n' "$minimal_macos" | grep -qw node || fail "minimal macOS omits node"
! printf '%s\n' "$minimal_macos" | grep -qw uv || fail "minimal macOS includes uv"
! printf '%s\n' "$minimal_macos" | grep -qw duti || fail "minimal macOS includes duti"

printf '%s\n' "$work_macos" | grep -qw uv || fail "work macOS omits uv"
printf '%s\n' "$work_macos" | grep -qw reattach-to-user-namespace || fail "work macOS omits tmux support"
! printf '%s\n' "$work_macos" | grep -qw duti || fail "work macOS includes personal integration"

printf '%s\n' "$personal_macos" | grep -qw duti || fail "personal macOS omits duti"
printf '%s\n' "$minimal_linux" | grep -qw python3 || fail "minimal Linux omits bootstrap's Python runtime"
! printf '%s\n' "$minimal_linux" | grep -qw build-essential || fail "minimal Linux includes build tools"
printf '%s\n' "$work_linux" | grep -qw build-essential || fail "work Linux omits build tools"
printf '%s\n' "$work_linux" | grep -qw gnupg || fail "work Linux omits GnuPG"

set +e
output=$("$ROOT/setup.sh" 2>&1)
status=$?
set -e
[ "$status" -eq 2 ] || fail "setup without a mode exited $status instead of 2"
printf '%s\n' "$output" | grep -q -- '--personal' || fail "setup usage omits modes"

echo "setup mode tests passed"
