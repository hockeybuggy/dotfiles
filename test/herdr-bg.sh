#!/usr/bin/env bash
#
# herdr-bg.sh -- test agents/skills/herdr/herdr-bg.zsh without a herdr server.
#
# A stub `herdr` on PATH records the report-metadata calls the wrapper makes, so
# the marker lifecycle is checked without touching a real session.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
WRAPPER="$REPO_ROOT/agents/skills/herdr/herdr-bg.zsh"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

mkdir -p "$workdir/bin"
cat > "$workdir/bin/herdr" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$workdir/calls.log"
EOF
chmod +x "$workdir/bin/herdr"

run_in_herdr() {
    PATH="$workdir/bin:$PATH" \
        HERDR_ENV=1 \
        HERDR_PANE_ID='wT:p1' \
        XDG_STATE_HOME="$workdir/state" \
        zsh "$WRAPPER" "$@"
}

fail() {
    echo "herdr-bg: $1" >&2
    exit 1
}

# Outside herdr the wrapper must be invisible: no herdr calls, exit status
# forwarded from the wrapped command.
: > "$workdir/calls.log"
status=0
env -u HERDR_ENV -u HERDR_PANE_ID PATH="$workdir/bin:$PATH" \
    zsh "$WRAPPER" sh -c 'exit 7' || status=$?
[ "$status" -eq 7 ] || fail "expected pass-through status 7, got $status"
[ ! -s "$workdir/calls.log" ] || fail "reported metadata while outside herdr"

# Usage errors are distinguishable from a command's own failure.
status=0
run_in_herdr > /dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "expected usage status 2 for no command, got $status"

status=0
run_in_herdr --label > /dev/null 2>&1 || status=$?
[ "$status" -eq 2 ] || fail "expected usage status 2 for bare --label, got $status"

# Inside herdr: a label is published while the command runs, then cleared.
: > "$workdir/calls.log"
run_in_herdr --label 'test suite' true
grep -q -- "--token bg=test suite" "$workdir/calls.log" \
    || fail "did not publish the bg token: $(cat "$workdir/calls.log")"
grep -q -- "--state-label idle=waiting · test suite" "$workdir/calls.log" \
    || fail "did not relabel the idle state: $(cat "$workdir/calls.log")"
tail -n 1 "$workdir/calls.log" | grep -q -- '--clear-token bg' \
    || fail "did not clear the bg token on exit: $(cat "$workdir/calls.log")"
[ -z "$(ls -A "$workdir/state/herdr-bg/wT_p1")" ] \
    || fail "left a marker file behind after exit"

# A second live job collapses into a count. Standing in for the concurrent job
# with this test's own pid keeps the assertion deterministic.
: > "$workdir/calls.log"
echo 'earlier job' > "$workdir/state/herdr-bg/wT_p1/$$"
run_in_herdr --label 'later job' true
grep -q -- "--token bg=2 jobs · " "$workdir/calls.log" \
    || fail "did not count concurrent jobs: $(cat "$workdir/calls.log")"

# A marker whose process is gone is pruned rather than reported forever.
: > "$workdir/calls.log"
rm -f "$workdir/state/herdr-bg/wT_p1/$$"
dead_pid=$(sh -c 'echo $$')
echo 'killed job' > "$workdir/state/herdr-bg/wT_p1/$dead_pid"
run_in_herdr --label 'healer' true
if grep -q -- 'killed job' "$workdir/calls.log"; then
    fail "reported a marker whose process had exited"
fi
[ ! -e "$workdir/state/herdr-bg/wT_p1/$dead_pid" ] \
    || fail "did not prune the stale marker file"

echo "herdr-bg wrapper: ok"
