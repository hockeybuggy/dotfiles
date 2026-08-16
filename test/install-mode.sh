#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMPDIR_ROOT=$(mktemp -d)
TRUE_BIN=$(command -v true)
FALSE_BIN=$(command -v false)
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

run_bootstrap() {
    mode=$1
    home=$2
    mkdir -p "$home"
    (
        cd "$ROOT"
        HOME="$home" TERM=xterm DOTFILES_SETUP_SCRIPT="$TRUE_BIN" \
            ./bootstrap.sh "--$mode" >/dev/null
    )
}

set +e
output=$(cd "$ROOT" && HOME="$TMPDIR_ROOT/no-mode" TERM=xterm \
    DOTFILES_SETUP_SCRIPT="$TRUE_BIN" ./bootstrap.sh 2>&1)
status=$?
set -e
[ "$status" -eq 2 ] || fail "bootstrap without a mode exited $status instead of 2"
printf '%s\n' "$output" | grep -q -- '--minimal' || fail "usage does not list --minimal"
[ ! -e "$TMPDIR_ROOT/no-mode/.dotfiles_mode" ] || fail "mode was written after invalid arguments"

set +e
output=$(cd "$ROOT" && HOME="$TMPDIR_ROOT/two-modes" TERM=xterm \
    DOTFILES_SETUP_SCRIPT="$TRUE_BIN" ./bootstrap.sh --work --personal 2>&1)
status=$?
set -e
[ "$status" -eq 2 ] || fail "bootstrap accepted two modes"

for mode in minimal work personal; do
    home="$TMPDIR_ROOT/$mode"
    run_bootstrap "$mode" "$home"
    [ "$(cat "$home/.dotfiles_mode")" = "$mode" ] || fail "$mode was not persisted"
done

failed_home="$TMPDIR_ROOT/setup-failed"
mkdir -p "$failed_home"
set +e
(
    cd "$ROOT"
    HOME="$failed_home" TERM=xterm DOTFILES_SETUP_SCRIPT="$FALSE_BIN" \
        ./bootstrap.sh --minimal >/dev/null 2>&1
)
status=$?
set -e
[ "$status" -ne 0 ] || fail "bootstrap ignored setup failure"
[ ! -e "$failed_home/.dotfiles_mode" ] || fail "mode was written after setup failure"

echo "install mode tests passed"
