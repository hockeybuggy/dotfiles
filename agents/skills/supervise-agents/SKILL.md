---
name: supervise-agents
description: "Launch a dedicated agent in its own tmux window that watches your other agents in tmux through drover and reacts the moment one goes `blocked` -- auto-answering prompts it judges safe and escalating everything else to you. Use when asked to \"supervise my agents\", \"watch my agents for blocked state\", \"let me know when an agent needs me\", \"babysit my agents\", or to keep an eye on several agent panes while you're away. For checking on a single agent from the current session, use the `tmux` skill's watching recipe instead. Requires running inside tmux."
---

# Supervising agents in tmux

Use this when the user wants one agent watching their other agents for
drover's `blocked` state (a permission prompt, confirmation, or other
input the agent can't proceed past on its own) so they don't have to poll
every pane themselves.

This launches a **fresh, persistent, interactive** agent instance into its
own tmux window -- it is not a one-shot check. That instance becomes the
supervisor: it runs indefinitely, reacting to state changes as they happen,
and reports in its own transcript. Because it's an ordinary interactive
session (not a headless run), the user can reconnect to it later -- e.g. via
Claude Code's Remote mode from another device -- to see what it's done.

## How it works

- Agents report their state to tmux with OSC 7501 (`idle`, `working`,
  `blocked`, `done`, or `error`), and drover reads that state (see the
  `tmux` skill). `drover wait <pane_id> --until blocked` **blocks until
  that pane's state flips**, so a supervisor doesn't need to poll on an
  interval.
- `launch-supervisor.sh` (shipped with this skill) creates a new labelled
  window, starts an interactive agent in it with `drover start`, and hands
  it `mission-template.md` (plus a watch list) as its first prompt.
- The mission tells that agent to keep one background `drover wait`
  outstanding per watched pane, react when one reports `blocked`, judge the
  prompt against a written policy, and either answer it
  (`tmux send-keys`) or escalate to the user in its own transcript.
  Read `mission-template.md` for the exact loop and judgment policy -- it's
  the actual operating instructions the supervisor follows, not just
  background for you.
- `blocked-context.sh` bundles the three calls the supervisor needs to judge
  a blocked pane (`drover get`, `drover explain`, `drover read`) into one
  shot.

## Prerequisites

- **Must be inside tmux** (`$TMUX` set) -- the wrapper creates a window in
  the user's own session so it's visible to them.
- `drover` (with tmux 3.9 or a `HEAD` build) and `jq` on `PATH`.
- The agent command you launch (`claude`, `opencode`, `pi`, `agy`, ...) must
  already be set up (authenticated, on `PATH`) the way it would be for a
  normal interactive session -- this skill doesn't handle onboarding a new
  agent CLI.

## How to invoke

Decide the watch list first:

- **Default -- supervise everything.** Don't pass any pane ids; the mission
  tells the supervisor to enumerate `drover list` itself and keep that set
  refreshed, so agents created after it starts are picked up too.
- **Explicit set.** Pass the pane ids the user actually means (e.g. "just
  the two agy panes in the halcyon_cruise session") if they scoped the
  request rather than asking for everything.

Then launch it:

```bash
skill_dir="$AGENT_STUFF/skills/supervise-agents"   # resolve from where SKILL.md lives

# Watch everything:
bash "$skill_dir/launch-supervisor.sh" claude supervisor "$skill_dir/mission-template.md"

# Watch specific panes only:
bash "$skill_dir/launch-supervisor.sh" claude supervisor "$skill_dir/mission-template.md" \
  %12 %15
```

The first argument is the agent command to run as supervisor -- default to
whichever agent you are yourself (`claude` if you're Claude Code, `pi` if
you're pi) unless the user asks for a different one. The second is the
window label; keep it short and recognisable (`supervisor` is fine unless
the user is running more than one, in which case distinguish them, e.g.
`supervisor-halcyon`).

Resolve the wrapper's absolute path from this skill's directory -- don't
hardcode `~/.agent-stuff/...`.

The script prints:

```
WINDOW_ID=@6
PANE_ID=%17
MISSION=/tmp/drover-supervisor-mission.XXXXXX
```

Tell the user which window to check (`WINDOW_ID`/its label) and that it will
run until they close it or ask it to stop. You are not blocked on it -- the
script returns as soon as the supervisor has been launched and started
working, not when it finishes (it isn't meant to finish).

## Pitfalls

- **No `$TMUX`.** The wrapper can't create a window; it exits 1 with a
  clear message. Start from inside tmux and retry.
- **Don't let the supervisor watch itself.** The wrapper appends its own
  pane id to the mission with an explicit instruction to exclude it;
  don't remove that if you customise the mission.
- **Auto-answering is a judgment call, not a fixed allowlist.** The policy
  in `mission-template.md` is deliberately principle-based rather than a
  strict list of approved commands -- it leans toward answering ordinary,
  reversible, in-repo actions and escalating anything destructive,
  credential-touching, external-facing, or unclear. If the user wants it
  tuned tighter or looser, edit that file's "Judging the prompt" section
  rather than hardcoding exceptions elsewhere.
- **`drover prompt` cannot answer a blocked dialog.** It's rejected with
  exit status 3 while the pane is blocked. Answering means
  `tmux send-keys` with whatever the on-screen prompt actually asks for (a
  menu digit, `y`, `Enter`, ...) -- read the screen first.
  `drover prompt` is for submitting a fresh instruction once the pane is
  unblocked, not for clearing the block itself.
- **One outstanding wait per watched pane, not a polling loop.** If the
  supervisor starts re-listing and re-waiting on every pane every cycle
  instead of keeping single long-lived waits running in the background, it
  will burn far more tool calls than necessary and can miss the point of
  using `drover wait` at all.
- **Stopping it is manual.** There's no separate "stop supervising" command
  -- closing the window (`tmux kill-window -t <window_id>`) or telling the
  supervisor directly to stop are the two ways to end it.
