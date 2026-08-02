#!/usr/bin/env bash
# Notification sound for questions and permission prompts.
# Shared by Claude Code and pi; see agents/hooks/tmux-title.sh.
# On macOS plays a system sound; elsewhere falls back to a terminal bell.

# Also record the prompt in the shared notification log.
bash "$(dirname "${BASH_SOURCE[0]}")/log-event.sh" attention

if [[ "$(uname)" == "Darwin" ]]; then
    # Backgrounded: afplay blocks for the length of the sound, which would
    # otherwise stall the tool call that triggered the prompt. Detach stdio
    # too, or the caller reading our output to EOF would keep waiting on it.
    afplay /System/Library/Sounds/Bottle.aiff >/dev/null 2>&1 &
else
    printf '\a'
fi

# Send visual bell to the current tmux pane so the window gets highlighted.
if [ -n "$TMUX" ]; then
    if [ -n "$TMUX_PANE" ]; then
        tty=$(tmux display-message -t "$TMUX_PANE" -p '#{pane_tty}' 2>/dev/null)
    else
        tty=$(tmux display-message -p '#{pane_tty}' 2>/dev/null)
    fi
    [ -n "$tty" ] && printf '\a' > "$tty"
fi
exit 0
