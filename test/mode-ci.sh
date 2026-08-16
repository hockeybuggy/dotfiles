#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

head -n 1 "$ROOT/bootstrap.sh" | grep -qx '#!/usr/bin/env bash' \
    || fail "bootstrap must run before zsh is installed"

workflow="$ROOT/.github/workflows/test-setup.yml"
grep -q 'matrix:' "$workflow" || fail "workflow has no mode matrix"
grep -q 'minimal, work, personal' "$workflow" || fail "workflow omits an install mode"
grep -q './test/run.sh --mode' "$workflow" || fail "Linux job does not forward its mode"
grep -q './bootstrap.sh --personal' "$workflow" || fail "macOS job does not bootstrap personal mode"

grep -q './bootstrap.sh --"$MODE"' "$ROOT/test/run.sh" || fail "container provisioner does not forward mode to bootstrap"
grep -q './test/verify.sh --mode \\"$mode\\"' "$ROOT/test/run.sh" || fail "container provisioner does not forward mode to verification"
grep -q 'checks_for_mode' "$ROOT/test/verify.sh" || fail "verification has no mode-specific checks"
grep -Fq 'work|personal)' "$ROOT/test/run.sh" || fail "container tests do not gate agent checks by mode"

echo "mode CI tests passed"
