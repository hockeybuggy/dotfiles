#!/usr/bin/env bash
# launch-supervisor.sh <kind> <label> <mission-file> [pane_id...]
#
# Creates a new tab in the current workspace, starts an interactive agent of
# <kind> in it, and hands it the mission from <mission-file> -- with a watch
# list appended -- as its first prompt. Does not wait for the supervisor to
# finish; it's meant to run indefinitely. Prints its ids and returns.
#
# With no pane_id arguments, the supervisor is told to watch every agent
# `herdr agent list` reports (refreshed as it runs). Pass explicit pane ids
# to restrict it to exactly those.

set -euo pipefail

kind="${1:?usage: launch-supervisor.sh <kind> <label> <mission-file> [pane_id...]}"
label="${2:?usage: launch-supervisor.sh <kind> <label> <mission-file> [pane_id...]}"
mission_file="${3:?usage: launch-supervisor.sh <kind> <label> <mission-file> [pane_id...]}"
shift 3
watch_panes=("$@")

require() { command -v "$1" >/dev/null 2>&1 || { echo "missing $1 on PATH" >&2; exit 1; }; }
require herdr
require jq

[ -n "${HERDR_ENV:-}" ] || { echo "not inside herdr -- start this from a herdr pane" >&2; exit 1; }
[ -f "$mission_file" ] || { echo "mission file not found: $mission_file" >&2; exit 1; }

tab_json="$(herdr tab create --cwd "$PWD" --label "$label" --no-focus)"
tab_id="$(jq -r '.result.tab.tab_id' <<<"$tab_json")"
pane_id="$(jq -r '.result.root_pane.pane_id' <<<"$tab_json")"

herdr agent start "$label" --kind "$kind" --pane "$pane_id" >/dev/null

mission_path="$(mktemp -t herdr-supervisor-mission)"
{
  cat "$mission_file"
  echo
  printf 'Your own pane id is %s -- never add yourself to the watch list.\n' "$pane_id"
  echo
  echo "## Watch list"
  echo
  if [ "${#watch_panes[@]}" -gt 0 ]; then
    echo "Supervise exactly these panes -- do not add others automatically:"
    echo
    for p in "${watch_panes[@]}"; do
      echo "- $p"
    done
  else
    echo "Supervise every agent \`herdr agent list\` currently shows, refreshed periodically to pick up new ones, except your own pane."
  fi
} > "$mission_path"

herdr agent prompt "$pane_id" "Read $mission_path and follow it. Don't summarize it back -- just begin." \
  --wait --until working --timeout 30000 >/dev/null

echo "TAB_ID=$tab_id"
echo "PANE_ID=$pane_id"
echo "MISSION=$mission_path"
