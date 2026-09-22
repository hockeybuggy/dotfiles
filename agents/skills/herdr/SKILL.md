---
name: herdr
description: "Create and drive herdr panes, tabs, and workspaces, and talk to or watch other agents running in them. Put user-requested work in the user's running herdr session; reserve a named agent session for agent-only background work."
---

# Herdr Skill

[herdr](https://herdr.dev/) is a terminal multiplexer being trialled in place of
tmux. Use it only when the user asks for a pane, tab, or workspace, or when a
long-lived process or interactive REPL needs to persist. For a short command
that finishes on its own, use a regular `zsh` command unless the user
explicitly asks for herdr.

If the user says "tmux", use the `tmux` skill instead — both are installed, and
the two do not share sessions. The tracked config sets the prefix to `ctrl+s`
to match `.tmux.conf`, so a herdr session running inside tmux leaves both
fighting over the same prefix key.

## Container names

herdr nests differently from tmux: **Session → Workspace → Tab → Pane**. A
session is a whole server (the tmux server), a workspace is a project-scoped
group of tabs, a tab holds a pane layout, and panes are the terminals.

| User says | Create | Location |
| --- | --- | --- |
| "new pane" | `herdr pane split` | The **current tab** |
| "new tab" or "new window" | `herdr tab create` | The **current workspace** |
| "new workspace" | `herdr workspace create` | The user's running session |
| "new session" | A named session | A separate herdr server |

For a pane or tab, `HERDR_ENV` must be set — it is herdr's `$TMUX`, exported
into every managed pane along with `HERDR_PANE_ID`, `HERDR_TAB_ID` and
`HERDR_WORKSPACE_ID`. If the agent is not running inside herdr, explain that it
cannot add to the user's current tab rather than silently creating a container
elsewhere.

Pass `--no-focus` for anything created on the user's behalf in the background so
their focus is not stolen. Use `--focus` only when the user asks to be taken
there.

## Every command speaks JSON

The CLI prints a single JSON object on stdout and exits non-zero on failure
(2 for usage errors). Ids like `w1:p2` are stable, so capture them:

```zsh
pane="$(herdr pane split --current --direction down --cwd "$PWD" --no-focus \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')"
```

`workspace create` returns its first tab and pane too, at
`.result.workspace.workspace_id`, `.result.tab.tab_id` and
`.result.root_pane.pane_id`.

## Shell

Use **zsh**, not bash. Panes already start zsh (the tracked
`~/.config/herdr/config.toml` sets `terminal.default_shell`), so run commands
with `herdr pane run` rather than spawning a shell inside a shell. The pane
stays open after the command finishes, so there is no `exec zsh` equivalent to
add.

## Visible user herdr operations

### New pane in the current tab

`--current` splits the pane the agent is running in; omitting the target uses
the focused pane. Use `--direction down` for a stacked pane and `right` only
when the user asks for side-by-side.

```zsh
pane="$(herdr pane split --current --direction down --cwd "$PWD" --no-focus \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')"
herdr pane run "$pane" 'rg badger'
```

### New tab in the current workspace

```zsh
tab="$(herdr tab create --label search --cwd "$PWD" --no-focus \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["tab"]["tab_id"])')"
```

### New workspace

```zsh
herdr workspace create --cwd "$PWD" --label search --no-focus
```

Do not close, rename, or reorder a workspace the agent did not create.

### Running commands and sending input

`herdr pane run <pane_id> <command>` submits the text plus Enter atomically and
honours bracketed-paste mode. Prefer it over `send-text` followed by an Enter
key.

```zsh
herdr pane run "$pane" 'npm test'
herdr pane send-text "$pane" 'literal text, no Enter'
herdr pane send-keys "$pane" ctrl+c
herdr pane send-keys "$pane" enter
```

Key names: printables, `enter`, `esc`, `tab`, `backspace`, arrows, chords like
`ctrl+h` / `alt+x` / `shift+tab`, function keys, and names like `minus`. `C-c`
maps to `ctrl+c`.

### Reading output

```zsh
herdr pane read "$pane" --source visible --lines 40
```

Use `--source visible` for command output — it is the rendered screen and is
what a short command's output lands in. `recent` and `recent-unwrapped` read
*scrollback*, so they come back empty until output has actually scrolled off;
reach for `recent-unwrapped` only for long logs. ANSI is stripped unless
`--ansi` is passed.

### Waiting for a command to finish

`herdr pane wait-output` checks the current snapshot first, then polls, so it
cannot miss output that already arrived. Beware the obvious trap: the pane
echoes the command line, so a literal `--match` on a sentinel matches the
*echo* rather than the result. Emit the exit status into the sentinel and match
a regex that only the output can satisfy:

```zsh
herdr pane run "$pane" 'rg badger; print -r -- "__AGENT_DONE_${?}__"'
herdr pane wait-output "$pane" --regex '__AGENT_DONE_[0-9]+__' \
  --source visible --timeout 30000
herdr pane read "$pane" --source visible --lines 40
```

The command line shows the literal `${?}`, so only the expanded output has a
digit there. Always pass `--timeout` (milliseconds) — omitting it waits forever.
On timeout the command prints a JSON error and exits 1.

Report the command's output and exit status. Do not close a user-requested pane
or tab after a finite command; it remains available for the user to inspect.

### Restarting a long-running process

To restart a dev server or watcher in the user's pane, interrupt it and wait
for the shell to be back in the foreground before running anything. Don't
match a prompt character like `\$` with `wait-output`, because it is already
on screen. The shell has the foreground again once its pid leads the
foreground process group:

```zsh
herdr pane send-keys "$pane" ctrl+c
until herdr pane process-info --pane "$pane" | python3 -c '
import json,sys; p=json.load(sys.stdin)["result"]["process_info"]
sys.exit(p["foreground_process_group_id"] != p["shell_pid"])'; do sleep 2; done
herdr pane run "$pane" 'scripts/up'
```

### Inspecting state

```zsh
herdr pane list
herdr pane current --current
herdr pane process-info --pane "$pane"
herdr session list
```

`pane process-info` needs `--pane <id>`; it rejects a bare positional id.
`pane read` prints plain text, not JSON.

### Finding "the other pane"

`pane list` has no tab labels. So when the user says "the other session" or
"the server tab", use `peers.sh` from this skill's directory. It prints pane
id, agent, status, tab label and cwd for the other panes in the current tab,
or for every tab with `--all`:

```zsh
"$skill_dir/peers.sh" --all
```

If more than one pane fits, ask the user which one they mean.

## Driving another agent

herdr tracks the agents it recognises (Claude, pi, Codex and others) and
reports each one as `idle`, `working`, `blocked`, `done` or `unknown`. Use the
`herdr agent` commands for them. `pane run` and `pane read` are for shells.
The target can be a pane id or an agent name.

```zsh
herdr agent list
herdr agent get "$pane"              # .result.agent.agent_status
herdr agent read "$pane" --source visible --lines 40
herdr agent prompt "$pane" 'Relay: the owner picked option B.' --wait --timeout 600000
```

`agent prompt` is safer than `pane run`. If the agent is sitting at an
approval or question dialog, it refuses with `agent_blocked` and sends nothing,
where `pane run` would type straight into the dialog. With `--wait` it also
confirms that a turn started, then returns once the agent settles. If a prompt
times out or stalls, check `agent get` and `agent read` before sending it again,
because it may already have been delivered.

When an agent is `blocked`, read the screen and ask the user before answering
it. Once they say how, answer with `herdr agent send-keys "$pane" 1 enter`, or
whatever keys the dialog expects. Only send slash commands like `/compact` when
the user asks for them.

### Watching an agent

When the user asks for an agent to be watched or checked on, don't poll on a
timer. Start a background wait instead. It returns the moment the agent needs
attention or finishes:

```zsh
herdr agent wait "$pane" --until blocked --until done --timeout 3600000
```

In Claude Code, run it with Bash `run_in_background`. The harness wakes you
when it exits. Then read the screen, report to the user, and start the next
wait if they want you to keep watching. For resilience, a long fallback wakeup
(20–30 minutes) is enough, in case a wait hangs. To watch several agents and
auto-answer safe prompts, use the `supervise-herdr-agents` skill.

### Sending a prompt later

Don't use `sleep N && herdr pane run …`. It fires blind, even if the agent is
busy or blocked. Use `prompt-later.sh` from this skill's directory instead. It
sleeps, waits for the agent to settle, and submits the prompt with
`agent prompt`. If the agent is blocked, it sends nothing. Run it detached so
it outlives your session:

```zsh
nohup "$skill_dir/prompt-later.sh" 10800 "$pane" 'Continue as far as you safely can.' \
  >"$TMPDIR/prompt-later.log" 2>&1 &
```

## Remote machines

Saved SSH machines take the same commands with a `--machine` prefix. Pane
ids and agent names belong to one server, so run discovery on the remote side
first:

```zsh
herdr --machine halite agent list
herdr --machine halite agent prompt "$remote_pane" 'Status?' --wait --timeout 120000
```

Only add, rename, enable or remove machine profiles when the user asks. The
first `herdr machine add` for a host has to approve installing the remote
binary from an interactive terminal, so ask the user to run it themselves
(`! herdr machine add --label <label> <ssh-target>`). Don't retry it
non-interactively.

## Agent-only background work

Use a **named session** for work the user did not ask to see — an unattended
dev server, watcher, or REPL. A named session is a separate server with its own
socket, so it cannot disturb the user's panes. This is herdr's equivalent of
`tmux -L agent`.

```zsh
export HERDR_SESSION=agent
herdr server                       # starts the agent server (headless)
herdr workspace create --cwd "$PWD" --label dev --no-focus
herdr server stop                  # stops the server and its pane processes
herdr session delete agent
```

`HERDR_SESSION` selects the session for every subsequent CLI call. Never point
it at the user's session to satisfy a request for a pane, tab, or workspace.

## Safety and cleanup

- Pass `--cwd "$PWD"` so commands run in the requested repository.
- Pass `--no-focus` unless the user asked to be taken to the new container.
- Do not stop the user's server, delete their sessions, or close panes,
  tabs, or workspaces the agent did not create. `herdr server stop` kills every
  pane process in that session.
- Clean up agent-only sessions when finished. Leave user-requested containers
  intact unless the user asks to close them.
- For commands with complex quoting, write a temporary **zsh** script and run
  it with `herdr pane run "$pane" 'zsh /absolute/path/to/script.zsh'` rather
  than building a fragile one-liner.
