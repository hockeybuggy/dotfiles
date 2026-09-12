---
name: supervise-herdr-agents
description: "Launch a dedicated agent in its own herdr tab that watches your other herdr-tracked agents and reacts the moment one goes `blocked` -- auto-answering prompts it judges safe and escalating everything else to you. Use when asked to \"supervise my agents\", \"watch my agents for blocked state\", \"let me know when an agent needs me\", \"babysit my agents\", or to keep an eye on several agent panes while you're away. Requires running inside herdr."
---

# Supervising herdr agents

Use this when the user wants one agent watching their other agents for
herdr's `blocked` state (a permission prompt, confirmation, or other
input the agent can't proceed past on its own) so they don't have to poll
every pane themselves.

This launches a **fresh, persistent, interactive** agent instance into its
own herdr tab -- it is not a one-shot check. That instance becomes the
supervisor: it runs indefinitely, reacting to state changes as they happen,
and reports in its own transcript. Because it's an ordinary interactive
session (not a headless run), the user can reconnect to it later -- e.g. via
Claude Code's Remote mode from another device -- to see what it's done.

## How it works

- herdr already classifies every agent pane it recognises as `idle`,
  `working`, `blocked`, `done`, or `unknown` (see the `herdr` skill and
  `.config/herdr/agent-detection/`), and exposes that over its socket API.
  `herdr agent wait <pane_id> --until blocked` **blocks until that pane's
  state flips**, so a supervisor doesn't need to poll on an interval.
- `launch-supervisor.sh` (shipped with this skill) creates a new labelled
  tab, starts an interactive agent in it with `herdr agent start`, and hands
  it `mission-template.md` (plus a watch list) as its first prompt.
- The mission tells that agent to keep one background `herdr agent wait`
  outstanding per watched pane, react when one reports `blocked`, judge the
  prompt against a written policy, and either answer it
  (`herdr agent send-keys`) or escalate to the user in its own transcript.
  Read `mission-template.md` for the exact loop and judgment policy -- it's
  the actual operating instructions the supervisor follows, not just
  background for you.
- `blocked-context.sh` bundles the three calls the supervisor needs to judge
  a blocked pane (`agent get`, `agent explain`, `pane read`) into one shot.

## Prerequisites

- **Must be inside herdr** (`$HERDR_ENV` set) -- the wrapper creates a tab in
  the user's own session so it's visible to them. If the user is on tmux
  instead, this skill does not apply.
- `herdr agent wait`, `herdr agent start`, and `herdr agent prompt` (herdr
  0.9.0 tested). `jq` on `PATH`.
- The agent kind you launch (`claude`, `pi`, `agy`, ...) must be one of
  `herdr agent start`'s supported `--kind` values and already set up
  (authenticated, on `PATH`) the way it would be for a normal interactive
  session -- this skill doesn't handle onboarding a new agent CLI.

## How to invoke

Decide the watch list first:

- **Default -- supervise everything.** Don't pass any pane ids; the mission
  tells the supervisor to enumerate `herdr agent list` itself and keep that
  set refreshed, so agents created after it starts are picked up too.
- **Explicit set.** Pass the pane ids the user actually means (e.g. "just
  the two agy panes in the halcyon_cruise workspace") if they scoped the
  request rather than asking for everything.

Then launch it:

```bash
skill_dir="$AGENT_STUFF/skills/supervise-herdr-agents"   # resolve from where SKILL.md lives

# Watch everything:
bash "$skill_dir/launch-supervisor.sh" claude supervisor "$skill_dir/mission-template.md"

# Watch specific panes only:
bash "$skill_dir/launch-supervisor.sh" claude supervisor "$skill_dir/mission-template.md" \
  w3:p1 w3:p4
```

The first argument is the agent kind to run as supervisor -- default to
whichever kind you are yourself (`claude` if you're Claude Code, `pi` if
you're pi) unless the user asks for a different one. The second is the tab
label; keep it short and recognisable (`supervisor` is fine unless the user
is running more than one, in which case distinguish them, e.g.
`supervisor-halcyon`).

Resolve the wrapper's absolute path from this skill's directory -- don't
hardcode `~/.agent-stuff/...`.

The script prints:

```
TAB_ID=w1:t6
PANE_ID=w1:p7
MISSION=/tmp/herdr-supervisor-mission.XXXXXX
```

Tell the user which tab to check (`TAB_ID`/its label) and that it will run
until they close it or ask it to stop. You are not blocked on it -- the
script returns as soon as the supervisor has been launched and started
working, not when it finishes (it isn't meant to finish).

## Pitfalls

- **No `$HERDR_ENV`.** The wrapper can't create a tab; it exits 1 with a
  clear message. Start from inside herdr and retry.
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
- **`herdr agent prompt` cannot answer a blocked dialog.** It's rejected
  with `agent_blocked` while the pane is blocked. Answering means
  `herdr agent send-keys` with whatever the on-screen prompt actually asks
  for (a menu digit, `y`, `enter`, ...) -- read the screen first.
  `agent prompt` is for submitting a fresh instruction once the pane is
  unblocked, not for clearing the block itself.
- **One outstanding wait per watched pane, not a polling loop.** If the
  supervisor starts re-listing and re-waiting on every pane every cycle
  instead of keeping single long-lived waits running in the background, it
  will burn far more tool calls than necessary and can miss the point of
  using `herdr agent wait` at all.
- **Stopping it is manual.** There's no separate "stop supervising" command
  -- closing the tab (`herdr tab close <tab_id>`) or telling the supervisor
  directly to stop are the two ways to end it.
