---
name: use-pi-in-pane
description: Run the `pi` coding agent as a headless subagent (--mode json) inside a visible tmux pane so the user can watch it stream while the agent still captures and verifies its structured output. Use when asked to "run pi in a pane", "let me watch pi work", "run pi where I can see it", or to delegate to pi with a live view. Requires running inside tmux. For a fully headless run with no pane, use use-pi-subagent instead.
allowed-tools: Bash
---

# Running pi in a visible tmux pane

This is the [[use-pi-subagent]] flow with a window into it. pi still runs
**headless in JSON mode** — you drive it, capture the full event stream, and
verify the result — but it runs in a new tmux pane so the user can watch it
stream in real time. When pi exits, control returns to you with the JSON log to
parse, exactly as in the headless skill.

Reach for this when the user wants to *see* pi work. When they just want the
work done, the plain [[use-pi-subagent]] skill is simpler (no tmux needed).

## How it works

`run-pi-pane.sh` (shipped with this skill) does the plumbing:

- splits a new tmux pane and runs pi there with the canonical headless flags
  (`--mode json --print --approve --no-session`);
- the pane shows a readable activity stream via `pretty.jq`: text and
  reasoning as it arrives, plus one concise summary for each tool execution
  with its name, most useful argument, and any failure — `tee` sits
  **upstream** of the pretty-printer, so the raw `.jsonl` log is captured in
  full even if the view hiccups;
- it **blocks until pi exits**, then prints `KEY=VALUE` lines back to you;
- the pane stays open afterward so the user can scroll the transcript — they
  close it themselves with `Ctrl-D`.

The pane is a live view for the human. The `.jsonl` log is the source of truth
for you.

## Prerequisites

- **Must be inside tmux.** The wrapper needs `$TMUX` to split a pane, and it
  uses the **user's own tmux server** so the pane is visible to them. Without
  `$TMUX` it exits with a clear error — fall back to [[use-pi-subagent]].
- `pi` and `jq` on `PATH`. The wrapper resolves `pi` absolutely from your
  shell, so fnm's shim works even though the pane's shell may have a leaner
  `PATH`.

## How to invoke

Write the full task prompt to a file first (a cold `--no-session` run carries no
context — see [[use-pi-subagent]] for what a good delegation prompt must
include), then hand it and a unique log path to the wrapper:

```bash
skill_dir="$AGENT_STUFF/skills/use-pi-in-pane"   # resolve from where SKILL.md lives
prompt_file="/abs/path/to/task.prompt.md"
json_log="/abs/path/to/run.jsonl"                 # unique per attempt

bash "$skill_dir/run-pi-pane.sh" \
  "$prompt_file" \
  "$json_log" \
  --model openai-codex/gpt-5.6-terra
```

Any extra arguments after the log path pass straight through to pi, so
per-task flags work as usual:

```bash
bash "$skill_dir/run-pi-pane.sh" "$prompt_file" "$json_log" \
  --model openai-codex/gpt-5.6-terra --thinking high --no-tools
```

Resolve the wrapper's absolute path from this skill's directory — don't hardcode
`~/.agent-stuff/...`.

## Launching into a fresh worktree

Each run should start from a clean, up-to-date base — don't reuse a stale
worktree from an earlier attempt:

- Create a **fresh worktree rebased on `origin/main`** immediately before
  launching pi, so the pane starts from current `main`.
- **Prefix the launch with `cd <worktree-path> && `.** The pane does not inherit
  your working directory — without the `cd` it runs pi from the wrong cwd and
  its relative paths and context-file discovery resolve against the wrong repo:

  ```bash
  cd "$worktree_path" && bash "$skill_dir/run-pi-pane.sh" "$prompt_file" "$json_log" ...
  ```

- If you self-test the tmux wiring, use an **isolated tmux server**
  (`tmux -L test-$$`), never the user's default server, so a test pane can't
  disturb their live session.

## Reading the result

The wrapper prints, on its own stdout:

```
JSON_LOG=/abs/path/to/run.jsonl
STDERR_LOG=/abs/path/to/run.stderr.log
PI_EXIT=0            # pi's own exit code
STATUS=complete      # "complete", or "aborted" if the user closed the pane early
```

`STATUS=aborted` (wrapper exit 1) means the pane was closed before pi finished —
the run is incomplete; do not treat its output as done. On `STATUS=complete`,
parse the log the same way as [[use-pi-subagent]]:

```bash
# The agent's final answer text
jq -r 'select(.type=="agent_end") | .messages[-1].content[]?
       | select(.type=="text") | .text' "$json_log"

# Did it hit an error and intend to retry?
jq -c 'select(.type=="agent_end") | {willRetry}' "$json_log"

# Total cost of the run
jq -r 'select(.type=="agent_end") | .messages[-1].usage.cost.total' "$json_log"
```

For a delegated coding task, **don't trust the final text alone** — verify the
files pi claims to have changed, run the relevant tests/lint yourself, and check
`git status` before treating the work as done.

## Pitfalls

- **No `$TMUX`.** The wrapper can't open a pane; it exits 1 with a clear
  message. Use [[use-pi-subagent]] instead — don't try to force a pane.
- **The pane lingers on purpose.** After pi exits, the pane drops to a shell so
  the user can read the transcript. That's intended; the user closes it. You are
  already unblocked and holding the log — don't wait on the pane.
- **Pane closure is an unreliable signal.** Don't infer success or failure from
  the pane disappearing. Rely on the exit sentinel / `STATUS` line, and before
  declaring an abort or failure, re-verify with `git log` in the worktree — the
  work may have committed even if the pane closed early.
- **Give unique log filenames per attempt** so retries don't clobber the audit
  trail. The wrapper derives `STDERR_LOG`, the exit-code file, and its sentinel
  from the log path.
- **Split direction / size.** The wrapper uses a stacked top/bottom split
  (`-v`). To change it, edit the `tmux split-window` line in `run-pi-pane.sh`.
