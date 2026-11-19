#!/usr/bin/env bash
# delegate.sh --label <name> [--cwd <dir>] [--model <query>] [--effort <level>] <brief-file>
#
# Starts an interactive OpenCode agent in a new tab of the caller's herdr
# workspace, selects its model and effort, and tells it to read and follow
# <brief-file>. Prints the new pane, tab and OpenCode session id.
#
# The OpenCode TUI has no --model flag, so the model and effort are set with
# the `/model` and `/effort` commands from agents/opencode/plugins, and the
# footer is checked to confirm each one took. <query> is any text that
# matches a single model, as `/model` takes it. On failure the tab is left
# open so the screen can be inspected.

set -euo pipefail

usage() {
  echo "usage: delegate.sh --label <name> [--cwd <dir>] [--model <query>] [--effort <level>] <brief-file>" >&2
  exit 2
}

label="" cwd="$PWD" model="" effort="" brief=""
while [ $# -gt 0 ]; do
  case "$1" in
    --label) label="${2:?}"; shift 2 ;;
    --cwd) cwd="${2:?}"; shift 2 ;;
    --model) model="${2:?}"; shift 2 ;;
    --effort) effort="${2:?}"; shift 2 ;;
    -*) usage ;;
    *) [ -z "$brief" ] || usage; brief="$1"; shift ;;
  esac
done
[ -n "$label" ] && [ -n "$brief" ] || usage

command -v jq >/dev/null 2>&1 || { echo "missing jq on PATH" >&2; exit 1; }
[ -n "${HERDR_ENV:-}" ] || { echo "not inside herdr" >&2; exit 1; }
[[ "$label" =~ ^[a-z][a-z0-9_-]{0,31}$ ]] || {
  echo "label must start with a lowercase letter and use only a-z, 0-9, '-' or '_' (max 32)" >&2
  exit 1
}
[ -f "$brief" ] || { echo "no such brief: $brief" >&2; exit 1; }
[ -d "$cwd" ] || { echo "no such directory: $cwd" >&2; exit 1; }
brief="$(cd "$(dirname "$brief")" && pwd)/$(basename "$brief")"
session="ses_${label//[^a-z0-9]/}_$(date +%s)"

fail() {
  echo "$1 (pane $pane left open)" >&2
  herdr agent read "$pane" --source visible --lines 40 | grep -v '^[[:space:]]*$' | tail -15 >&2
  exit 1
}

screen() { herdr agent read "$pane" --source visible --lines 80; }

footer() {
  screen | grep '┃' | grep ' · ' | tail -1 | sed 's/^[[:space:]]*┃[[:space:]]*//'
}

words() { tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]\n' ' '; }

wait_for() {
  local i
  for i in $(seq 30); do
    "$@" && return 0
    sleep 0.5
  done
  return 1
}

model_selected() {
  local shown word
  shown=" $(footer | words) "
  for word in $(words <<<"$model"); do
    [[ "$shown" == *" $word"* ]] || return 1
  done
}

# `/model` leaves the model picker open when the query matches no model or
# several, and opens a variant picker after selecting a model that has them.
model_settled() {
  local shown
  shown="$(screen)"
  [[ "$shown" == *"Select variant"* ]] && return 0
  [[ "$shown" != *"Select model"* ]] && model_selected
}

effort_selected() { [ "$(footer | awk -F ' · ' '{print $NF}')" = "$effort" ]; }

shell_ready() {
  herdr pane process-info --pane "$pane" \
    | jq -e '.result.process_info | .foreground_process_group_id == .shell_pid' >/dev/null
}

created="$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --label "$label" --cwd "$cwd" --no-focus)"
tab="$(jq -r .result.tab.tab_id <<<"$created")"
pane="$(jq -r .result.root_pane.pane_id <<<"$created")"

wait_for shell_ready || fail "the new tab's shell never became ready"
herdr agent start "$label" --kind opencode --pane "$pane" --timeout 120000 -- --session "$session" >/dev/null \
  || fail "OpenCode did not start"

if [ -n "$model" ]; then
  herdr pane run "$pane" "/model $model" >/dev/null
  wait_for model_settled || {
    herdr pane send-keys "$pane" esc
    fail "'$model' did not select a single model"
  }
  if screen | grep -q 'Select variant'; then
    herdr pane send-keys "$pane" esc
  fi
  wait_for model_selected || fail "'$model' did not select a single model"
fi

if [ -n "$effort" ]; then
  herdr pane run "$pane" "/effort $effort" >/dev/null
  wait_for effort_selected || fail "effort '$effort' was not applied"
fi

herdr agent prompt "$pane" "Read $brief and follow it." --wait --until working --timeout 30000 >/dev/null \
  || fail "the agent did not start working on the brief"

printf 'pane=%s\ntab=%s\nsession=%s\nfooter=%s\n' "$pane" "$tab" "$session" "$(footer)"
