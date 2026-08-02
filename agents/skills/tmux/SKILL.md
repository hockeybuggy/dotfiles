---
name: tmux
description: "Create and drive tmux panes, windows, and sessions. Put user-requested work in the user's current tmux context; reserve the isolated agent server for agent-only background work."
---

# Tmux Skill

Use tmux only when the user asks for a pane, window, or session, or when a
long-lived process or interactive REPL needs to persist. For a short command
that finishes on its own, use a regular `zsh` command unless the user explicitly
asks for tmux.

## Choose the target from the user's words

When the user asks to run work in tmux, their requested container determines
where it goes:

| User says | Create | Server and location |
| --- | --- | --- |
| "new pane" | A split pane | The **current window of the current session** on the user's tmux server |
| "new window" | A window | The **current session** on the user's tmux server |
| "new session" | A session | A new named session on the user's tmux server |

For a pane or window, `$TMUX` must be set. It identifies the user's active tmux
server and session. Use plain `tmux` for these visible, user-requested actions —
**do not use `-L agent`**. If the agent is not running in tmux, explain that it
cannot create a pane or window in the user's current session rather than
silently creating one elsewhere.

For a new session, create it detached so the user's current client is not
interrupted. Name it after its purpose and report the name.

## Shell

Use **zsh**, not bash, in panes, windows, sessions, temporary scripts, and
command examples. Start commands with `zsh -lc` and use `exec zsh` afterward
when the user may want to inspect the result. This keeps the new tmux container
open after the command finishes.

## Visible user tmux operations

### New pane in the current window

Use `split-window` without `-t`; invoked from the agent's current tmux context,
it targets the current window. `-P -F` returns the pane ID for later inspection.

```zsh
pane="$(tmux split-window -v -P -F '#{pane_id}' -c "$PWD" \
  zsh -lc 'rg badger; status=$?; print -r -- "__AGENT_DONE_${status}__"; exec zsh')"
```

Use `-h` instead of `-v` only when the user asks for a side-by-side pane.

### New window in the current session

```zsh
window="$(tmux new-window -P -F '#{window_id}' -c "$PWD" -n search \
  zsh -lc 'rg badger; status=$?; print -r -- "__AGENT_DONE_${status}__"; exec zsh')"
```

Do not supply `-t` unless the user names a different session. By default, tmux
uses the current session.

### New session

```zsh
session='search'
tmux new-session -d -s "$session" -c "$PWD" \
  zsh -lc 'rg badger; status=$?; print -r -- "__AGENT_DONE_${status}__"; exec zsh'
```

Do not reuse or kill an existing user session. If the requested name already
exists, ask for a different name or target the existing session only when the
user explicitly asks.

### Capturing output and checking completion

Use the pane or window ID returned when creating the target. A sentinel lets the
agent wait for a finite command without guessing at a delay:

```zsh
for _ in {1..50}; do
  tmux capture-pane -t "$pane" -p -S - | grep -q '__AGENT_DONE_' && break
  sleep 0.1
done

tmux capture-pane -t "$pane" -p -S -
```

Report the command's output and exit status. Do not close a user-requested pane
or window after a finite command; it remains available for the user to inspect.

### Sending more input

```zsh
tmux send-keys -t "$pane" -l 'print -r -- hello'
tmux send-keys -t "$pane" Enter
tmux send-keys -t "$pane" C-c
```

Use `-l` for literal text. Pass `Enter` as a separate argument.

## Agent-only background work

Use the dedicated `agent` socket only when the work is explicitly agent-only:
for example, an unattended dev server, watcher, or REPL the user did not ask to
see in their own tmux. This isolation prevents accidental interference with the
user's sessions.

```zsh
tmux -L agent new-session -d -s dev -- zsh -lc 'npm run dev'
tmux -L agent list-sessions
tmux -L agent kill-session -t dev
```

Never use the agent socket for a request that says "new pane", "new window", or
"new session" unless the user explicitly asks for an isolated agent session.

## Safety and cleanup

- Use `-c "$PWD"` so commands run in the requested repository.
- Do not kill, rename, attach to, or otherwise alter user sessions you did not
  create.
- Clean up agent-only sessions when finished. Leave user-requested panes,
  windows, and sessions intact unless the user asks to close them.
- For commands containing complex quoting, write a temporary **zsh** script and
  run it with `zsh /absolute/path/to/script.zsh` rather than building a fragile
  `zsh -lc` string.
