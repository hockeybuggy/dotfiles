---
name: agent-notifications
description: "Open a dedicated Ghostty window tailing the shared agent notification log (`~/devel/AGENT_NOTIFICATIONS.log`), where Claude Code and pi record when a turn finishes or a pane needs attention. Use when the user asks to watch agent notifications, open the notification window, or see which agent needs attention."
---

# Agent notifications

Every Claude Code and pi session appends to a shared log through the
hook scripts in `agents/hooks`:

- `done.sh` → `✅ … done` (green) when a turn finishes
- `notify.sh` → `🔔 … needs attention` (yellow) on a permission prompt,
  a question, or a trust prompt

Each line records the time, which agent, the project, and the
`session:window.pane` to jump to:

```
00:37:31 ✅ claude  dotfiles   work:2.1   done
00:37:34 🔔 pi      api-server work:3.0   needs attention
```

## Open the watcher window

```bash
open -na Ghostty --args --title="Agent notifications" \
    -e "$HOME/.claude/skills/agent-notifications/watch.sh"
```

Check whether one is already running before opening another:

```bash
pgrep -f 'agent-notifications/watch.sh' >/dev/null && echo "already open"
```

`watch.sh` creates the log if missing and uses `tail -F`, so the window
survives the file being rotated or deleted. Colours are stored in the
log itself, so any `tail`/`cat` shows them.

## Jumping to a pane

The third column is a tmux target. From another pane:

```bash
tmux switch-client -t 'work:3.0'   # inside tmux
tmux attach -t work \; select-window -t 3 \; select-pane -t 0
```

## Notes

- The log path is `~/devel/AGENT_NOTIFICATIONS.log`, overridable with
  `AGENT_NOTIFICATION_LOG` (read by both `watch.sh` and `log-event.sh`).
- Lines outside tmux show `-` as the target.
- The log grows without bound; truncate it whenever it gets noisy:
  `: > ~/devel/AGENT_NOTIFICATIONS.log`.
