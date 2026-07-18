#!/usr/bin/env bash
# run-pi-pane.sh
#
# Run `pi` as a headless subagent (--mode json) inside a visible tmux
# pane so the user can watch it work, while the full JSON event stream is
# still captured to a log the calling agent parses afterward.
#
# The pane shows a pretty, prose-only view (pretty.jq); the log gets the
# raw JSONL. tee sits upstream of jq, so the log is captured even if the
# pretty view errors. This blocks until pi exits, then returns — the same
# "kick it off, wait, read the result" contract as the headless
# use-pi-subagent skill, just visible.
#
# Usage:
#   run-pi-pane.sh <prompt_file> <json_log> [extra pi flags...]
#
# Example:
#   run-pi-pane.sh task.prompt.md run.jsonl \
#     --model openai-codex/gpt-5.6-terra --thinking high
#
# Prints KEY=VALUE lines on stdout (JSON_LOG, STDERR_LOG, PI_EXIT,
# STATUS) for the caller to read. Exits non-zero if pi could not be run
# to completion (missing tmux, aborted pane); pi's own exit code is
# reported via PI_EXIT / the printed STATUS, not this script's status.

set -euo pipefail

PROMPT_FILE="${1:-}"
JSON_LOG="${2:-}"
if [ -z "$PROMPT_FILE" ] || [ -z "$JSON_LOG" ]; then
  echo "run-pi-pane.sh: usage: run-pi-pane.sh <prompt_file> <json_log> [pi flags...]" >&2
  exit 2
fi
shift 2  # remaining args are extra pi flags, passed through verbatim

if [ ! -f "$PROMPT_FILE" ]; then
  echo "run-pi-pane.sh: prompt file not found: $PROMPT_FILE" >&2
  exit 2
fi

if [ -z "${TMUX:-}" ]; then
  echo "run-pi-pane.sh: not inside a tmux session, cannot open a pane" >&2
  echo "Run the agent from inside tmux, or use the headless use-pi-subagent skill instead." >&2
  exit 1
fi

# Resolve tooling absolutely in the agent's shell (which has the right
# PATH, e.g. fnm's pi shim). The tmux pane inherits the server's
# environment, which may not, so we don't rely on its PATH.
PI_BIN="$(command -v pi || true)"
if [ -z "$PI_BIN" ]; then
  echo "run-pi-pane.sh: pi not found on PATH" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRETTY_JQ="$SCRIPT_DIR/pretty.jq"

STDERR_LOG="${JSON_LOG%.jsonl}.stderr.log"
[ "$STDERR_LOG" = "$JSON_LOG" ] && STDERR_LOG="$JSON_LOG.stderr.log"
STATUS_FILE="$JSON_LOG.pi-exit"
SENTINEL="$JSON_LOG.pane-done"
PANE_SCRIPT="$JSON_LOG.pane.sh"
rm -f "$STATUS_FILE" "$SENTINEL" "$PANE_SCRIPT"

# Write the pane's work to a real script file rather than cramming it
# into `bash -c '...'` — the pipeline itself contains single quotes, so
# any inline-quoting scheme is a foot-gun. The prompt text is read via
# $(cat ...) inside the pane, so arbitrary prompt content never touches
# this command line. pi's exit code is taken from the head of the pipe
# (PIPESTATUS) and recorded before the sentinel is touched, so the waiter
# below always has a status to report. We then exec a shell so the pane
# stays open for the user to read/scroll — they close it themselves.
cat > "$PANE_SCRIPT" <<EOF
#!/usr/bin/env bash
"$PI_BIN" --mode json --print --approve --no-session $* "\$(cat '$PROMPT_FILE')" \\
  2>'$STDERR_LOG' | tee '$JSON_LOG' | jq -rj --unbuffered -f '$PRETTY_JQ'
st=\${PIPESTATUS[0]}
printf '%s' "\$st" > '$STATUS_FILE'
printf '\n\n---- pi finished (exit %s) ---- (Ctrl-D to close this pane)\n' "\$st"
touch '$SENTINEL'
exec "\${SHELL:-/bin/sh}"
EOF

# -v: stacked top/bottom split so a long stream is easy to watch below the
#     agent. -c: start in the current repo so pi's relative paths and
#     context-file discovery resolve correctly.
PANE=$(tmux split-window -v -P -F '#{pane_id}' -c "$PWD" "bash \"$PANE_SCRIPT\"")

# Block until pi finishes (sentinel appears). The dead-pane guard means
# this can never hang: if the pane exits early — whether it vanishes
# (remain-on-exit off) or lingers dead (remain-on-exit on) — pane_dead
# stops being "0" and we stop waiting. Missing sentinel afterward == the
# run was aborted before pi completed.
while [ ! -f "$SENTINEL" ]; do
  dead="$(tmux display-message -p -t "$PANE" '#{pane_dead}' 2>/dev/null || echo gone)"
  [ "$dead" != "0" ] && break
  sleep 0.3
done

aborted=0
[ -f "$SENTINEL" ] || aborted=1

PI_EXIT=""
[ -f "$STATUS_FILE" ] && PI_EXIT="$(cat "$STATUS_FILE")"
rm -f "$SENTINEL" "$PANE_SCRIPT"

echo "JSON_LOG=$JSON_LOG"
echo "STDERR_LOG=$STDERR_LOG"
echo "PI_EXIT=$PI_EXIT"
if [ "$aborted" = 1 ]; then
  echo "STATUS=aborted"
  echo "run-pi-pane.sh: pane closed before pi finished; run is incomplete" >&2
  exit 1
fi
echo "STATUS=complete"
