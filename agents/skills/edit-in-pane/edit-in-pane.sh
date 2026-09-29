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
before="$(cksum < "$file" 2>/dev/null || true)"

pane="$(herdr pane split --current --direction down --cwd "$PWD" --focus \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')"
echo "PANE=$pane"

herdr pane run "$pane" "nvim $(printf '%q' "$file"); exit"

# Only pane_not_found means the user closed it; a transient herdr error must
# not end the wait while they are still typing.
until [[ "$(herdr pane get "$pane" 2>&1)" == *'"pane_not_found"'* ]]; do
  sleep 1
done

if [ "$(cksum < "$file" 2>/dev/null || true)" = "$before" ]; then
  echo "CHANGED=no"
else
  echo "CHANGED=yes"
fi
