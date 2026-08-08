---
name: use-agy-in-pane
description: Run Google's `agy` (Antigravity CLI) as a headless subagent (--output-format stream-json) inside a visible, named tmux window so the user can watch it stream while the agent still captures and verifies its structured output. Use when asked to "run agy", "run antigravity", "run agy in a pane", "let me watch agy work", or to delegate to agy with a live view. Requires running inside tmux.
allowed-tools: Bash
---

# Running agy in a visible tmux window

Use this whenever you delegate a discrete task to `agy` (Google's Antigravity
CLI). agy runs **headless in stream-json mode** — you drive it, capture the
full event stream, and verify the result — but it runs in a new, named tmux
window so the user can watch it stream in real time. When agy exits, control
returns to you with the JSON log to parse.

This mirrors the `use-pi-in-pane` skill; see that skill if you're delegating
to `pi` instead. The visible window makes delegation auditable and lets the
user follow along without sacrificing structured output.

## How it works

`run-agy-pane.sh` (shipped with this skill) does the plumbing:

- opens a new tmux window (named after the task via `TASK_NAME`, see below)
  and runs agy there with the canonical headless flags
  (`--output-format stream-json --dangerously-skip-permissions`);
- the window shows a readable activity stream via `pretty.jq`: response text
  as it streams, plus one concise line for each tool call as it starts —
  `tee` sits **upstream** of the pretty-printer, so the raw `.jsonl` log is
  captured in full even if the view hiccups;
- it **blocks until agy exits**, then prints `KEY=VALUE` lines back to you;
- the window stays open afterward so the user can scroll the transcript —
  they close it themselves with `Ctrl-D`.

The window is a live view for the human. The `.jsonl` log is the source of
truth for you.

## Prerequisites

- **Must be inside tmux.** The wrapper needs `$TMUX` to open a window, and it
  uses the **user's own tmux server** so the window is visible to them. Start
  the agent from tmux before delegating.
- `agy` and `jq` on `PATH`. The wrapper resolves `agy` absolutely from your
  shell.
- agy must already be authenticated (`agy` reads OS-keyring credentials or
  its own session state) — this skill does not handle sign-in.

## How to invoke

Write the full task prompt to a file first. Each run starts a fresh
conversation (no `--continue`/`--conversation`), so include the exact task
and scope, relevant repository conventions, files to inspect, required
validation, and the expected output. Then hand it and a unique log path to
the wrapper:

```bash
skill_dir="$AGENT_STUFF/skills/use-agy-in-pane"   # resolve from where SKILL.md lives
prompt_file="/abs/path/to/task.prompt.md"
json_log="/abs/path/to/run.jsonl"                  # unique per attempt

TASK_NAME="fix-login-bug" bash "$skill_dir/run-agy-pane.sh" \
  "$prompt_file" \
  "$json_log" \
  --model "Gemini 3.6 Flash (High)"
```

Set `TASK_NAME` to a short slug describing the delegated task — it becomes the
new tmux window's name, so the user can tell what it's for at a glance without
opening it. It defaults to `agy-task` if omitted; always set it.

Any extra arguments after the log path pass straight through to agy, so
per-task flags work as usual:

```bash
TASK_NAME="fix-login-bug" bash "$skill_dir/run-agy-pane.sh" "$prompt_file" "$json_log" \
  --model "Gemini 3.6 Flash (High)" --effort high
```

Resolve the wrapper's absolute path from this skill's directory — don't hardcode
`~/.agent-stuff/...`.

## Launching into a fresh worktree

Each run should start from a clean, up-to-date base — don't reuse a stale
worktree from an earlier attempt:

- Create a **fresh worktree rebased on `origin/main`** immediately before
  launching agy, so the window starts from current `main`.
- **Prefix the launch with `cd <worktree-path> && `.** The window does not
  inherit your working directory — without the `cd` it runs agy from the
  wrong cwd and its relative paths and workspace discovery resolve against
  the wrong repo:

  ```bash
  cd "$worktree_path" && TASK_NAME="fix-login-bug" bash "$skill_dir/run-agy-pane.sh" "$prompt_file" "$json_log" ...
  ```

- If you self-test the tmux wiring, use an **isolated tmux server**
  (`tmux -L test-$$`), never the user's default server, so a test window
  can't disturb their live session.

## Reading the result

The wrapper prints, on its own stdout:

```
JSON_LOG=/abs/path/to/run.jsonl
STDERR_LOG=/abs/path/to/run.stderr.log
AGY_EXIT=0            # agy's own exit code
STATUS=complete        # "complete", or "aborted" if the user closed the window early
```

`STATUS=aborted` (wrapper exit 1) means the window was closed before agy
finished — the run is incomplete; do not treat its output as done. On
`STATUS=complete`, parse the log's final `result` event:

```bash
# The agent's final answer text
jq -r 'select(.event=="result") | .result.response' "$json_log"

# Did it succeed? SUCCESS, ERROR, CANCELED, INTERRUPTED, INVALID
jq -r 'select(.event=="result") | .result.status' "$json_log"

# Token usage for the whole run
jq -c 'select(.event=="result") | .result.usage' "$json_log"
```

For a delegated coding task, **don't trust the final text alone** — verify the
files agy claims to have changed, run the relevant tests/lint yourself, and
check `git status` before treating the work as done.

## Pitfalls

- **No `$TMUX`.** The wrapper can't open a window; it exits 1 with a clear
  message. Start the agent from tmux, then retry — don't try to force a window.
- **`--dangerously-skip-permissions` is load-bearing.** Without it, agy's
  headless mode soft-denies any tool that would otherwise need an approval
  prompt (it "cannot prompt for" one), and the run silently produces no
  output. The wrapper always passes this flag; don't drop it unless you also
  pre-approve the needed tools in `~/.gemini/antigravity-cli/settings.json`.
- **The window lingers on purpose.** After agy exits, the window drops to a
  shell so the user can read the transcript. That's intended; the user closes
  it. You are already unblocked and holding the log — don't wait on the window.
- **Window closure is an unreliable signal.** Don't infer success or failure
  from the window disappearing. Rely on the exit sentinel / `STATUS` line, and
  before declaring an abort or failure, re-verify with `git log` in the
  worktree — the work may have committed even if the window closed early.
- **Give unique log filenames per attempt** so retries don't clobber the audit
  trail. The wrapper derives `STDERR_LOG`, the exit-code file, and its sentinel
  from the log path.
- **Always set `TASK_NAME`.** Without it the window is just named `agy-task`,
  which is indistinguishable from any other delegated run in the tmux window
  list.
