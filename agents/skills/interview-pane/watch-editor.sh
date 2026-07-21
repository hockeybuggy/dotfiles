#!/usr/bin/env bash
# watch-editor.sh — block until a vim/nvim editor for a given file opens
# and then closes.
#
# Usage:
#   watch-editor.sh <filename-or-basename> [appear-timeout-seconds]
#
# Run this as a BACKGROUNDED tool call (run_in_background: true) right
# after splitting the tmux pane. When the editor closes it exits 0 and
# the agent gets a completion notification, which is the cue to read the
# answers back.
#
# It deliberately does NOT touch the tmux socket — it only inspects the
# process table via pgrep — so it runs fine inside the default sandbox.

set -uo pipefail

TARGET="${1:-}"
APPEAR_TIMEOUT="${2:-120}"

if [ -z "$TARGET" ]; then
  echo "watch-editor.sh: missing filename argument" >&2
  exit 2
fi

# Match nvim OR vim editing OUR specific file.
#
# Two gotchas encoded here:
#   1. `pgrep -f "vim ..."` also matches "nvim" (substring), so we would
#      track the wrong process if a plain vim were open elsewhere. The
#      `n?vim` alternation matches both intentionally and nothing else.
#   2. Anchoring on the unique interview filename means we don't collide
#      with unrelated editor sessions the user has open.
#
# `-f` matches against the full command line. macOS/BSD pgrep treats the
# pattern as an extended regex, so `?` and `.*` work as expected.
PATTERN="n?vim .*${TARGET}"

# Phase 1: wait for the editor to APPEAR.
#
# THIS PHASE IS THE WHOLE POINT. A naive "wait until the process is gone"
# loop runs before tmux has spawned the editor, sees nothing, and exits
# immediately — falsely reporting that the user already closed the editor.
# We must first confirm the editor exists.
appeared=""
for _ in $(seq 1 "$APPEAR_TIMEOUT"); do
  if pgrep -f "$PATTERN" >/dev/null 2>&1; then
    appeared=1
    break
  fi
  sleep 1
done

if [ -z "$appeared" ]; then
  echo "TIMEOUT: no editor matching '$PATTERN' appeared within ${APPEAR_TIMEOUT}s" >&2
  echo "The pane may have failed to launch the editor. Check 'tmux list-panes'." >&2
  exit 3
fi

echo "OPENED: editor for '$TARGET' is running; waiting for it to close..."

# Phase 2: wait for the editor to DISAPPEAR.
while pgrep -f "$PATTERN" >/dev/null 2>&1; do
  sleep 1
done

echo "CLOSED: editor for '$TARGET' has exited"
