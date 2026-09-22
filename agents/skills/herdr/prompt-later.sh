#!/usr/bin/env bash
# prompt-later.sh <delay-seconds> <agent-pane> <text>
#
# Sleeps, waits for the agent to settle at idle or done, then submits <text>
# with `herdr agent prompt`. It never types into a busy agent or an open
# approval dialog: a blocked agent makes `agent prompt` fail with
# agent_blocked, and the script exits non-zero without sending anything.
#
# Run it detached so it outlives the calling session:
#   nohup prompt-later.sh 10800 wD:pT 'Continue.' >"$log" 2>&1 &

set -euo pipefail

delay="${1:?usage: prompt-later.sh <delay-seconds> <agent-pane> <text>}"
pane="${2:?usage: prompt-later.sh <delay-seconds> <agent-pane> <text>}"
text="${3:?usage: prompt-later.sh <delay-seconds> <agent-pane> <text>}"

sleep "$delay"
herdr agent wait "$pane" --until idle --until "done" --timeout 21600000
herdr agent prompt "$pane" "$text" --wait --until working --timeout 30000
