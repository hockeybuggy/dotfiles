#!/usr/bin/env bash
# run-agy-pane.sh
#
# Run `agy` as a headless subagent (--output-format stream-json) inside a
# visible herdr tab so the user can watch it work, while the full NDJSON
# event stream is still captured to a log the calling agent parses
# afterward.
#
# The tab shows a pretty, prose-only view (pretty.jq); the log gets the
# raw stream-json. tee sits upstream of jq, so the log is captured even if
# the pretty view errors. This blocks until agy exits, then returns -- the
# same "kick it off, wait, read the result" contract as run-pi-pane.sh, just
# for agy.
#
# Usage:
#   TASK_NAME=<short-slug> run-agy-pane.sh <prompt_file> <json_log> [extra agy flags...]
#
# TASK_NAME (optional) labels the new herdr tab so the user can tell what
# it's for at a glance. Set it to a short slug describing the task, e.g.
# "fix-login-bug". Defaults to "agy-task" if unset.
#
# Example:
#   TASK_NAME=fix-login-bug run-agy-pane.sh task.prompt.md run.jsonl \
#     --model "Gemini 3.6 Flash (High)" --effort high
#
# Prints KEY=VALUE lines on stdout (JSON_LOG, STDERR_LOG, AGY_EXIT,
# STATUS) for the caller to read. Exits non-zero if agy could not be run
# to completion (not inside herdr, closed tab); agy's own exit code is
# reported via AGY_EXIT / the printed STATUS, not this script's status.

set -euo pipefail

PROMPT_FILE="${1:-}"
JSON_LOG="${2:-}"
if [ -z "$PROMPT_FILE" ] || [ -z "$JSON_LOG" ]; then
  echo "run-agy-pane.sh: usage: run-agy-pane.sh <prompt_file> <json_log> [agy flags...]" >&2
  exit 2
fi
shift 2  # remaining args are extra agy flags, passed through verbatim

if [ ! -f "$PROMPT_FILE" ]; then
  echo "run-agy-pane.sh: prompt file not found: $PROMPT_FILE" >&2
  exit 2
fi

if [ -z "${HERDR_ENV:-}" ]; then
  echo "run-agy-pane.sh: not inside a herdr session, cannot open a tab" >&2
  echo "Run the agent from inside herdr, then try again." >&2
  exit 1
fi

# Sanitize into a readable herdr tab label.
TAB_LABEL="$(printf '%s' "${TASK_NAME:-agy-task}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
TAB_LABEL="${TAB_LABEL:-agy-task}"

# Resolve tooling absolutely in the agent's shell (which has the right
# PATH). The herdr pane inherits the server's environment, which may not,
# so we don't rely on its PATH.
AGY_BIN="$(command -v agy || true)"
if [ -z "$AGY_BIN" ]; then
  echo "run-agy-pane.sh: agy not found on PATH" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRETTY_JQ="$SCRIPT_DIR/pretty.jq"

STDERR_LOG="${JSON_LOG%.jsonl}.stderr.log"
[ "$STDERR_LOG" = "$JSON_LOG" ] && STDERR_LOG="$JSON_LOG.stderr.log"
STATUS_FILE="$JSON_LOG.agy-exit"
SENTINEL="$JSON_LOG.pane-done"
PANE_SCRIPT="$JSON_LOG.pane.sh"
rm -f "$STATUS_FILE" "$SENTINEL" "$PANE_SCRIPT"

# Write the pane's work to a real script file rather than cramming it into
# the `herdr pane run` command line — the pipeline itself contains single
# quotes, so any inline-quoting scheme is a foot-gun. The prompt text is
# read via $(cat ...) inside the pane, so arbitrary prompt content never
# touches that command line. -p and its prompt value go LAST: agy's flag
# parser stops consuming flags at the first non-flag token, so any extra
# pass-through flags in "$*" must land before the prompt, not after. agy's
# exit code is taken from the head of the pipe (PIPESTATUS) and recorded
# before the sentinel is touched, so the waiter below always has a status
# to report. herdr returns the pane to its zsh prompt when the script
# finishes, so the transcript stays on screen with no `exec` needed — the
# user closes it themselves.
#
# --dangerously-skip-permissions auto-approves every tool call, the agy
# equivalent of pi's --approve. There's no --no-session equivalent; simply
# omitting --continue/--conversation starts a fresh conversation each run.
cat > "$PANE_SCRIPT" <<EOF
#!/usr/bin/env bash
"$AGY_BIN" --output-format stream-json --dangerously-skip-permissions $* -p "\$(cat '$PROMPT_FILE')" \\
  2>'$STDERR_LOG' | tee '$JSON_LOG' | jq -rj --unbuffered -f '$PRETTY_JQ'
st=\${PIPESTATUS[0]}
printf '%s' "\$st" > '$STATUS_FILE'
printf '\n\n---- agy finished (exit %s) ---- (Ctrl-D to close this tab)\n' "\$st"
touch '$SENTINEL'
EOF

# A tab, not a split: the run gets the full terminal, and --label lets the
# user spot it in the tab bar without opening it. --cwd starts it in the
# current repo so agy's relative paths and workspace discovery resolve
# correctly, and --no-focus keeps the user where they are.
PANE_ID="$(herdr tab create --cwd "$PWD" --label "$TAB_LABEL" --no-focus \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["root_pane"]["pane_id"])')"
herdr pane run "$PANE_ID" "bash '$PANE_SCRIPT'" > /dev/null

# Block until agy finishes (sentinel appears). The missing-pane guard means
# this can never hang: if the user closes the tab, `pane get` starts
# failing and we stop waiting. Missing sentinel afterward == the run was
# aborted before agy completed.
while [ ! -f "$SENTINEL" ]; do
  herdr pane get "$PANE_ID" > /dev/null 2>&1 || break
  sleep 0.3
done

aborted=0
[ -f "$SENTINEL" ] || aborted=1

AGY_EXIT=""
[ -f "$STATUS_FILE" ] && AGY_EXIT="$(cat "$STATUS_FILE")"
rm -f "$SENTINEL" "$PANE_SCRIPT"

echo "JSON_LOG=$JSON_LOG"
echo "STDERR_LOG=$STDERR_LOG"
echo "AGY_EXIT=$AGY_EXIT"
if [ "$aborted" = 1 ]; then
  echo "STATUS=aborted"
  echo "run-agy-pane.sh: tab closed before agy finished; run is incomplete" >&2
  exit 1
fi
echo "STATUS=complete"
