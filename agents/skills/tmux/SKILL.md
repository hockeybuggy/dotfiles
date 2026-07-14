---
name: tmux
description: "Spawn and drive tmux sessions from the agent — background long-lived processes (dev servers, watchers) and interact with REPLs/TUIs (python, ipython, debuggers). Always use the dedicated `agent` socket so user sessions are untouched."
---

# Tmux Skill

Use tmux when a regular `bash` tool call won't do, specifically:

- **Long-lived processes** that must keep running across turns
  (dev servers, file watchers, `cargo watch`, log followers).
- **Interactive REPLs / TUIs** where state must persist between
  inputs (python, ipython, node, gdb/lldb, `psql`, etc.).

For anything that finishes on its own in a reasonable time, just use
`bash` — don't reach for tmux.

## Isolation: always use the `agent` socket

Every tmux command in this skill uses `-L agent`. This puts the
agent's sessions on a separate tmux server from whatever the user is
running, so we can't accidentally kill or read their panes.

```bash
alias t='tmux -L agent'   # mental model only; use the full flag in commands
```

Never run plain `tmux ...` — always `tmux -L agent ...`.

## Naming

Pick short, descriptive session names: `dev`, `build`, `py`, `pg`.
One concern per session. If you need multiples, suffix:
`dev-api`, `dev-web`.

## Core verbs

### Start a detached session running a command

```bash
tmux -L agent new-session -d -s dev -- npm run dev
```

- `-d` detached (don't attach)
- `-s NAME` session name
- `--` everything after is the command (no shell quoting surprises)

If the command exits, the session ends. To keep the pane alive after
the command exits (useful when debugging why it died), start a shell
and send the command separately (see next).

### Start an empty shell session, then send commands

```bash
tmux -L agent new-session -d -s py
tmux -L agent send-keys -t py 'python3 -i' Enter
```

Use this when you want a persistent REPL you'll drive interactively.

### Send input to a session

`send-keys` takes a string and/or named keys as separate arguments.
**`Enter` is its own argument** — it does not work to append `\n`.

```bash
tmux -L agent send-keys -t py 'x = 1 + 1' Enter
tmux -L agent send-keys -t dev C-c              # interrupt
tmux -L agent send-keys -t dev 'q'              # no Enter (single keystroke)
```

For strings that contain characters tmux would interpret as keys (e.g.
`;`, `Space`, things that look like key names), use `-l` for literal:

```bash
tmux -L agent send-keys -t py -l 'print("hello; world")'
tmux -L agent send-keys -t py Enter
```

### Capture pane output

`capture-pane -p` prints to stdout. Use `-S` to include scrollback:

```bash
tmux -L agent capture-pane -t py -p              # visible pane only
tmux -L agent capture-pane -t py -p -S -         # full scrollback
tmux -L agent capture-pane -t py -p -S -200      # last 200 lines
```

For long sessions, prefer logging to a file (next section) and `tail`
that instead of repeatedly capturing.

### Continuous logging with `pipe-pane`

Mirror everything the pane prints to a file. Set this up immediately
after creating the session:

```bash
tmux -L agent new-session -d -s build
tmux -L agent pipe-pane  -t build -o 'cat >>/tmp/agent-build.log'
tmux -L agent send-keys  -t build 'npm run build:watch' Enter
```

Now you can `tail -n 50 /tmp/agent-build.log` or `grep ERROR` it from
later turns without disturbing the pane. `-o` means "only open the
pipe if not already open", making the call idempotent.

Clean up the log file when killing the session.

### List what's running

```bash
tmux -L agent list-sessions                       # sessions
tmux -L agent list-windows -t dev                 # windows in a session
tmux -L agent list-panes   -t dev -F '#{pane_pid} #{pane_current_command}'
```

If `list-sessions` errors with "no server running", there are no
agent sessions — that's a normal state, not a failure.

### Kill things

```bash
tmux -L agent kill-session -t dev
tmux -L agent kill-server                         # nuke ALL agent sessions
```

Always kill sessions you started once you're done with them. Leaving
orphans behind is the main way this skill goes wrong.

## Patterns

### Run a dev server in the background, then check its output

```bash
tmux -L agent new-session -d -s dev
tmux -L agent pipe-pane  -t dev -o 'cat >>/tmp/agent-dev.log'
tmux -L agent send-keys  -t dev 'npm run dev' Enter

# ...do other work...

sleep 2
tail -n 100 /tmp/agent-dev.log
```

### Drive a Python REPL

```bash
tmux -L agent new-session -d -s py
tmux -L agent send-keys   -t py 'python3 -i' Enter
sleep 0.3

tmux -L agent send-keys   -t py -l 'import json; data = json.load(open("x.json"))'
tmux -L agent send-keys   -t py Enter
tmux -L agent send-keys   -t py -l 'len(data)'
tmux -L agent send-keys   -t py Enter
sleep 0.3
tmux -L agent capture-pane -t py -p -S -
```

### Know when a command has finished (sentinel pattern)

tmux is asynchronous: `send-keys` returns immediately, before the
command runs. If you need to wait for completion, append a sentinel
and poll:

```bash
tmux -L agent send-keys -t dev 'long_command; echo __AGENT_DONE_$$__' Enter

for i in $(seq 1 30); do
  if tmux -L agent capture-pane -t dev -p -S - | grep -q '__AGENT_DONE_'; then
    break
  fi
  sleep 1
done

tmux -L agent capture-pane -t dev -p -S -
```

Skip this for fire-and-forget servers — they never "finish".

## Worked example: dev server with readiness check and cleanup

A realistic flow that exercises most of this skill: start a Vite dev
server, wait until it is actually serving, do some work, later check
the log for errors introduced by edits, then shut everything down.

```bash
# 1. Start from a clean slate (idempotent — safe to re-run).
tmux -L agent kill-session -t dev 2>/dev/null
rm -f /tmp/agent-dev.log

# 2. Create the session, attach a log, then start the server.
#    Doing pipe-pane BEFORE send-keys ensures we capture startup output.
tmux -L agent new-session -d -s dev
tmux -L agent pipe-pane  -t dev -o 'cat >>/tmp/agent-dev.log'
tmux -L agent send-keys  -t dev 'npm run dev' Enter

# 3. Wait for readiness. Poll the log for Vite's "ready in" banner
#    instead of a blind sleep — fast when it's fast, patient when it isn't.
for i in $(seq 1 30); do
  grep -q 'ready in' /tmp/agent-dev.log && break
  sleep 1
done

if ! grep -q 'ready in' /tmp/agent-dev.log; then
  echo 'dev server did not start in 30s; last log lines:'
  tail -n 50 /tmp/agent-dev.log
  tmux -L agent kill-session -t dev
  exit 1
fi

# 4. ...go off and edit files in other tool calls...

# 5. After edits, look for new errors. Track a byte offset so we only
#    inspect output produced since the last check.
MARK=$(wc -c </tmp/agent-dev.log)
# ...make another edit...
tail -c +$((MARK + 1)) /tmp/agent-dev.log | grep -E 'error|Error|ERROR' \
  || echo 'no new errors'

# 6. Tear down. Kill the session AND remove the log file.
tmux -L agent kill-session -t dev
rm -f /tmp/agent-dev.log
```

Key things this example demonstrates:

- `kill-session` + `rm` at the top makes the whole block re-runnable.
- `pipe-pane` is set up **before** `send-keys` so startup output is
  not lost.
- Readiness is detected by **grepping for a known string**, not a
  fixed sleep — robust to slow machines and fast ones.
- A byte offset (`wc -c` → `tail -c +N`) lets later turns scan only
  *new* log output, avoiding false positives from earlier runs.
- Cleanup removes both the tmux session and the on-disk log.

## Pitfalls

- **Forgetting `Enter`.** `send-keys 'cmd'` types the text but doesn't
  run it. Always pass `Enter` as a separate argument when you want
  execution.
- **Quoting strings with `;`, `Space`, or anything that looks like a
  key name.** Use `send-keys -l` (literal mode) when in doubt.
- **Capturing too early.** The command may not have produced output
  yet. `sleep` briefly, or use the sentinel pattern.
- **Targeting the wrong server.** If `-L agent` is missing, you're
  poking the user's tmux. Always include it.
- **Leaving sessions running.** Kill what you started; `tmux -L agent
  list-sessions` at the end of a task is a cheap sanity check.
- **Assuming the session exists.** Before `send-keys`, either create
  the session in the same turn or check with `has-session`:

  ```bash
  tmux -L agent has-session -t dev 2>/dev/null || \
    tmux -L agent new-session -d -s dev
  ```
