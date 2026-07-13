#!/usr/bin/env bash
# Rename the current tmux window to reflect Claude Code's state.
#
# tmux's automatic-rename names each window after the pane's running process,
# but Claude Code sets its process title to its version string (e.g. 2.1.206),
# so the window ends up labelled with a version number instead of anything
# useful. These hooks override that with a status emoji plus the project name,
# and restore automatic-rename when the session ends.
#
# Usage: tmux-title.sh <emoji>   # rename window to "<emoji> <project>"
#        tmux-title.sh --reset   # re-enable tmux automatic-rename

# Nothing to do outside tmux.
[ -z "${TMUX:-}" ] && exit 0

# Resolve the window index from the active pane.
if [ -n "${TMUX_PANE:-}" ]; then
    window=$(tmux display-message -t "$TMUX_PANE" -p '#I' 2>/dev/null)
else
    window=$(tmux display-message -p '#I' 2>/dev/null)
fi
[ -z "$window" ] && exit 0

if [ "$1" = "--reset" ]; then
    tmux set-window-option -t "$window" automatic-rename on
    exit 0
fi

emoji="${1:-🤖}"
project=$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")

# Pin the name so automatic-rename can't clobber it with the version string.
tmux set-window-option -t "$window" automatic-rename off
tmux rename-window -t "$window" "$emoji $project"
exit 0
