#!/usr/bin/env bash
# blocked-context.sh <pane_id> [lines]
#
# Bundles the three calls a supervisor needs to judge a blocked agent into
# one shot: get, explain, and the visible screen.

set -euo pipefail

pane_id="${1:?usage: blocked-context.sh <pane_id> [lines]}"
lines="${2:-60}"

echo "=== drover get $pane_id ==="
drover get "$pane_id"
echo
echo "=== drover explain $pane_id ==="
drover explain "$pane_id"
echo
echo "=== drover read $pane_id --lines $lines ==="
drover read "$pane_id" --lines "$lines"
