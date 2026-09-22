#!/usr/bin/env bash
# peers.sh [--all]
#
# Lists the other panes in the caller's tab (or every tab with --all), one per
# line: pane_id, agent, agent_status, tab label, cwd. The caller's own pane is
# left out. Answers "the other pane" and "the server tab" in one call.

set -euo pipefail

command -v jq >/dev/null 2>&1 || { echo "missing jq on PATH" >&2; exit 1; }
[ -n "${HERDR_ENV:-}" ] || { echo "not inside herdr" >&2; exit 1; }

scope="${HERDR_TAB_ID:?}"
[ "${1:-}" = "--all" ] && scope=""

peers="$(jq -rn \
  --argjson panes "$(herdr pane list)" \
  --argjson tabs "$(herdr tab list)" \
  --argjson agents "$(herdr agent list)" \
  --arg self "${HERDR_PANE_ID:-}" \
  --arg scope "$scope" '
  ($tabs.result.tabs | map({(.tab_id): .label}) | add) as $labels
  | ($agents.result.agents | map({(.pane_id): .agent}) | add // {}) as $kinds
  | $panes.result.panes[]
  | select(.pane_id != $self and ($scope == "" or .tab_id == $scope))
  | [.pane_id, ($kinds[.pane_id] // "-"), .agent_status, ($labels[.tab_id] // "-"), .cwd]
  | @tsv')"

if [ -n "$peers" ]; then
  printf '%s\n' "$peers"
elif [ -n "$scope" ]; then
  echo "no other panes in this tab (try --all)" >&2
else
  echo "no other panes" >&2
fi
