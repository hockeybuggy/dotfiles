#!/usr/bin/env bash
# edit-in-pane.sh <file>
#
# Opens <file> in nvim in a new herdr pane below the agent's, focused, and
# blocks until the user quits the editor and the pane closes. Also works as
# $GIT_EDITOR.

set -euo pipefail

file="${1:?usage: edit-in-pane.sh <file>}"

[ -n "${HERDR_ENV:-}" ] || { echo "edit-in-pane.sh: not inside herdr" >&2; exit 1; }
command -v nvim >/dev/null || { echo "edit-in-pane.sh: nvim not on PATH" >&2; exit 1; }

file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"

pane="$(herdr pane split --current --direction down --cwd "$PWD" --focus \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')"
echo "PANE=$pane"

herdr pane run "$pane" "nvim $(printf '%q' "$file"); exit"

while herdr pane get "$pane" >/dev/null 2>&1; do
  sleep 1
done
