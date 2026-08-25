#!/usr/bin/env bash
# Rename the current tmux window to reflect a coding agent's state.
#
# tmux's automatic-rename names each window after the pane's running process,
# but Claude Code sets its process title to its version string (e.g. 2.1.206),
# so the window ends up labelled with a version number instead of anything
# useful. These hooks override that with a status emoji plus the project name,
# and restore automatic-rename when the session ends.
#
# A window the user has named themselves is left alone entirely — see the
# ownership check below.
#
# An agent working on a specific issue or ticket can add its identifier with
# `--task`; it is stored as a window option so the status hooks keep it in the
# title on every subsequent rename. The task is only ever shown when the agent
# has the window to itself — in a split window the title belongs to everyone in
# it, not to one agent's issue.
#
# Shared by Claude Code (via settings.json hooks), pi (via the notifications
# extension), and agy (via hooks.json, see agents/hooks/agy-*.sh).
#
# Usage: tmux-title.sh <emoji>          # "<emoji> <project> [task]"
#        tmux-title.sh --task ABC-123   # remember a task, retitle now
#        tmux-title.sh --task           # forget the task, retitle now
#        tmux-title.sh --reset          # re-enable tmux automatic-rename

# Nothing to do outside tmux.
[ -z "${TMUX:-}" ] && exit 0

# Resolve the window index from the active pane.
if [ -n "${TMUX_PANE:-}" ]; then
    window=$(tmux display-message -t "$TMUX_PANE" -p '#I' 2>/dev/null)
else
    window=$(tmux display-message -p '#I' 2>/dev/null)
fi
[ -z "$window" ] && exit 0

# Never touch a window the user has named themselves. tmux turns
# automatic-rename off for a window as soon as anything renames it, so "auto
# is off and the current name is not the one we last set" means the name came
# from the user (or from a window that was already named before the agent
# started here), and it is not ours to overwrite. `#{automatic-rename}`
# formats as 1/0, not on/off.
info=$(tmux display-message -t "$window" -p '#{automatic-rename}|#W' 2>/dev/null)
auto="${info%%|*}"
current="${info#*|}"
ours=$(tmux show-options -w -t "$window" -qv @agent_title 2>/dev/null)
if [ "$auto" = "0" ] && [ "$current" != "$ours" ]; then
    exit 0
fi

if [ "$1" = "--reset" ]; then
    tmux set-window-option -t "$window" -u @agent_task 2>/dev/null
    tmux set-window-option -t "$window" -u @agent_emoji 2>/dev/null
    tmux set-window-option -t "$window" -u @agent_title 2>/dev/null
    tmux set-window-option -t "$window" automatic-rename on
    exit 0
fi

if [ "$1" = "--task" ]; then
    task="$2"
    if [ -z "$task" ]; then
        tmux set-window-option -t "$window" -u @agent_task 2>/dev/null
    else
        tmux set-window-option -t "$window" @agent_task "$task"
    fi
    # Keep whatever state emoji the last status hook set.
    emoji=$(tmux show-options -w -t "$window" -qv @agent_emoji 2>/dev/null)
else
    emoji="${1:-🤖}"
    tmux set-window-option -t "$window" @agent_emoji "$emoji"
    task=$(tmux show-options -w -t "$window" -qv @agent_task 2>/dev/null)
fi

[ -z "$emoji" ] && emoji=🤖
project=$(basename "${AGENT_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${AGY_PROJECT_DIR:-$PWD}}}")

# Only claim the title for a task when this agent is alone in the window.
panes=$(tmux display-message -t "$window" -p '#{window_panes}' 2>/dev/null)
[ "$panes" = "1" ] || task=""

title="$emoji $project"
[ -n "$task" ] && title="$title $task"

# Pin the name so automatic-rename can't clobber it with the version string,
# and remember it so a later user rename is recognisable as not ours.
tmux set-window-option -t "$window" automatic-rename off
tmux set-window-option -t "$window" @agent_title "$title"
tmux rename-window -t "$window" "$title"
exit 0
