#!/usr/bin/env bash
# git-editor.sh
#
# A GIT_EDITOR wrapper that opens the file git hands it (usually
# COMMIT_EDITMSG, but also MERGE_MSG, rebase todo lists, etc.) in
# nvim inside a new tmux pane, and blocks until the user closes it.
#
# Usage:
#   GIT_EDITOR=/abs/path/to/git-editor.sh git commit
#   GIT_EDITOR=/abs/path/to/git-editor.sh git commit --amend
#   GIT_EDITOR=/abs/path/to/git-editor.sh git rebase -i HEAD~3
#
# Git itself takes care of:
#   - including the diff (when commit.verbose=true or `git commit -v`)
#   - stripping `#` comment lines
#   - aborting on empty messages
# so this script just has to "be the editor".

set -euo pipefail

FILE="${1:-}"
if [ -z "$FILE" ]; then
  echo "git-editor.sh: missing file argument" >&2
  exit 2
fi

if [ -z "${TMUX:-}" ]; then
  echo "git-editor.sh: not inside a tmux session, cannot open editor pane" >&2
  echo "Start the agent (or git command) from inside tmux, or unset GIT_EDITOR." >&2
  exit 1
fi

# Pick an editor. Don't recurse through $EDITOR/$VISUAL since this
# script may itself be one of those. tmux runs the pane command via
# /bin/sh -c which doesn't read shell aliases, so resolve concretely.
if command -v nvim >/dev/null 2>&1; then
  ED=nvim
else
  ED=vim
fi

DONE="$FILE.agent-done"
rm -f "$DONE"

# Split a new pane running the editor. After the editor exits:
#   - `touch $DONE`  signals the waiter (normal exit path)
#   - `tmux kill-pane` forces the pane to close even when the user
#     has `set -g remain-on-exit on` in their tmux config
PANE=$(tmux split-window -P -F '#{pane_id}' -v \
  "$ED '$FILE'; touch '$DONE'; tmux kill-pane")

# Wait until the editor is done. Two exit conditions:
#   1. sentinel file appears -> normal `:wq` / `:q` exit
#   2. pane disappears without the sentinel -> someone killed the
#      pane externally; treat as abort, git will see an unchanged
#      file and abort the commit on its own.
while [ ! -f "$DONE" ]; do
  if ! tmux display-message -p -t "$PANE" '#{pane_id}' >/dev/null 2>&1; then
    break
  fi
  sleep 0.3
done

rm -f "$DONE"
