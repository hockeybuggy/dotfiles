#!/usr/bin/env bash
# peers.sh [--all]
#
# Lists the other panes in the caller's tmux window (or every pane with --all),
# one per line: pane_id, agent, state, window name, cwd. The caller's own pane
# is left out. Agent and state come from tmux's OSC 7501 record, or "-".

set -euo pipefail

[ -n "${TMUX:-}" ] || { echo "not inside tmux" >&2; exit 1; }

if [ "${1:-}" = "--all" ]; then
  set -- -a
else
  set --
fi

tab=$(printf '\t')
format="#{pane_id}${tab}#{?pane_program_name,#{pane_program_name},-}${tab}#{?pane_program_state,#{pane_program_state},-}${tab}#{window_name}${tab}#{pane_current_path}"
peers="$(tmux list-panes "$@" -F "$format" | awk -F '\t' -v self="${TMUX_PANE:-}" '$1 != self')"

if [ -n "$peers" ]; then
  printf '%s\n' "$peers"
elif [ "$#" -eq 0 ]; then
  echo "no other panes in this window (try --all)" >&2
else
  echo "no other panes" >&2
fi
