#!/usr/bin/env bash
# Append a coding-agent status line to the shared notification log.
#
# Both Claude Code and pi call this through done.sh and notify.sh, so a single
# `tail -F` on the log shows every agent across every tmux pane. See the
# agent-notifications skill for the Ghostty window that watches it.
#
# Usage: log-event.sh done       # the agent finished its turn
#        log-event.sh attention  # the agent is waiting on a human

LOG="${AGENT_NOTIFICATION_LOG:-$HOME/devel/AGENT_NOTIFICATIONS.log}"

state="${1:-done}"

# Colours are written into the file itself: `tail` passes them through, and the
# few tools that read the log without a terminal can strip them.
esc=$(printf '\033')
reset="${esc}[0m"
dim="${esc}[2m"
cyan="${esc}[36m"
bold_white="${esc}[1;37m"

case "$state" in
    attention)
        icon="🔔"
        colour="${esc}[1;33m" # yellow: something is blocked on you
        label="needs attention"
        ;;
    *)
        icon="✅"
        colour="${esc}[1;32m" # green: finished, nothing required
        label="done"
        ;;
esac

# Claude Code exports CLAUDE_PROJECT_DIR; pi exports AGENT_PROJECT_DIR.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    agent="claude"
    project_dir="$CLAUDE_PROJECT_DIR"
elif [ -n "${AGENT_PROJECT_DIR:-}" ]; then
    agent="pi"
    project_dir="$AGENT_PROJECT_DIR"
else
    agent="agent"
    project_dir="$PWD"
fi
project=$(basename "$project_dir")

# session:window.pane, so the line says exactly where to look. Prefer the
# pane the hook is running in over tmux's idea of the active one.
target="-"
if [ -n "${TMUX:-}" ]; then
    if [ -n "${TMUX_PANE:-}" ]; then
        target=$(tmux display-message -t "$TMUX_PANE" -p '#S:#I.#P' 2>/dev/null)
    else
        target=$(tmux display-message -p '#S:#I.#P' 2>/dev/null)
    fi
    [ -z "$target" ] && target="-"
fi

mkdir -p "$(dirname "$LOG")" 2>/dev/null

# One printf so concurrent agents can't interleave halves of a line.
printf '%s%s%s %s %s%-6s%s %s%-20s%s %s%-18s%s %s%s%s\n' \
    "$dim" "$(date '+%H:%M:%S')" "$reset" \
    "$icon" \
    "$dim" "$agent" "$reset" \
    "$bold_white" "$project" "$reset" \
    "$cyan" "$target" "$reset" \
    "$colour" "$label" "$reset" \
    >> "$LOG"

exit 0
