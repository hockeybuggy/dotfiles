#!/usr/bin/env bash
# prompt-later.sh <delay-seconds> <agent-pane> <text>
#
# Sleeps, waits for the agent to settle, then submits <text> with
# `drover prompt`. It never types into a busy agent or an open approval
# dialog: `drover prompt` refuses a blocked agent with exit status 3.
#
# Run it detached so it outlives the calling session:
#   nohup prompt-later.sh 10800 %12 'Continue.' >"$log" 2>&1 &

set -euo pipefail

delay="${1:?usage: prompt-later.sh <delay-seconds> <agent-pane> <text>}"
pane="${2:?usage: prompt-later.sh <delay-seconds> <agent-pane> <text>}"
text="${3:?usage: prompt-later.sh <delay-seconds> <agent-pane> <text>}"

sleep "$delay"
drover wait "$pane" --until settled --timeout 21600000
drover prompt "$pane" "$text" --wait-start --timeout 30000
