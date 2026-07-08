#!/usr/bin/env bash
# Completion sound for when Claude stops.
# On macOS plays a system sound; elsewhere falls back to a terminal bell.
if [[ "$(uname)" == "Darwin" ]]; then
    afplay /System/Library/Sounds/Hero.aiff
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
