#!/usr/bin/env bash
# blocked-context.sh <pane_id> [lines]
#
# Bundles the three calls a supervisor needs to judge a blocked agent into
# one shot: agent get, agent explain, and the visible screen.

set -euo pipefail

pane_id="${1:?usage: blocked-context.sh <pane_id> [lines]}"
lines="${2:-60}"

echo "=== herdr agent get $pane_id ==="
herdr agent get "$pane_id"
echo
echo "=== herdr agent explain $pane_id ==="
herdr agent explain "$pane_id" --format json
echo
echo "=== herdr pane read $pane_id --source visible --lines $lines ==="
herdr pane read "$pane_id" --source visible --lines "$lines"
