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

## Driving another agent

drover tracks the coding agents running in tmux panes (Claude Code, OpenCode,
Pi, agy). Agents report their own state to tmux with OSC 7501, so this needs
tmux 3.9 or a HEAD build. An agent is `idle`, `working`, `blocked` (waiting
on an approval or a question), `done` or `error`, and drover marks it
`unseen` when a turn ended while nobody was looking at the pane. Use drover
for agents; `send-keys` and `capture-pane` are for shells.

```zsh
drover list                     # every agent, as JSON
drover get "$pane"              # .state, .unseen, .message
drover read "$pane" --lines 40  # the screen, as text
drover prompt "$pane" 'Relay: the owner picked option B.' --wait --timeout 600000
```

`drover prompt` is safer than `send-keys`. If the agent is `blocked`, it
refuses with exit status 3 and sends nothing, where `send-keys` would type
straight into the dialog. `--wait-start` returns once the turn starts and
`--wait` once it settles or blocks. If it times out (exit status 4), check
`drover get` and `drover read` before sending it again, because it may
already have been delivered.

When an agent is `blocked`, read its screen and `message` and ask the user
before answering. Once they say how, answer with
`tmux send-keys -t "$pane" 1 Enter`, or whatever keys the dialog expects.
Only send slash commands like `/compact` when the user asks for them.

### Delegating a task to another agent

Never run an agent non-interactively (`pi -p`, `claude -p`, `codex exec` and
the like). Start it interactively in its own window so the user can watch,
answer its prompts and take over:

```zsh
pane="$(drover start pi --name fix-login-bug --cwd "$worktree" --wait \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["pane_id"])')"
drover prompt "$pane" "Read $prompt_file and follow it." --wait --timeout 1800000
```

The new agent has none of your context, so write the task, scope,
conventions and how to verify it to a file first. Pass extra flags after
`--`, e.g. `drover start claude --name review -- --model haiku`. When it
settles, check `drover get`. If it is `blocked`, handle it as above.
Otherwise read its answer with `drover read`, then verify its changes
yourself with `git status`, the diff and the relevant tests. Leave the
window open for the user.

### Watching an agent

Don't poll on a timer. Start a background wait; it returns the moment the
agent needs attention:

```zsh
drover wait "$pane" --until blocked --until unseen --timeout 3600000
```

`unseen` relies on `drover watch`, which `.tmux.conf` starts. Use
`--until settled` (`idle`, `done` or `error`) only when you need to know the
agent stopped working on a task you gave it: OpenCode goes back to `idle`,
never `done`. A wait that already matches returns at once, so check
`drover get` first. To watch several agents and answer safe prompts, use the
`supervise-agents` skill.

### Sending a prompt later

Don't use `sleep N && drover prompt …`. Use `prompt-later.sh` from this
skill's directory: it sleeps, waits for the agent to settle, and never types
into a blocked agent. Run it detached so it outlives your session:

```zsh
nohup "$skill_dir/prompt-later.sh" 10800 "$pane" 'Continue as far as you safely can.' \
  >"$TMPDIR/prompt-later.log" 2>&1 &
```

### Finding "the other pane"

`peers.sh` from this skill's directory lists the other panes in the current
window, or in every session with `--all`: pane id, agent, state, window
name and directory. If more than one pane fits, ask the user which one they
mean.

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
