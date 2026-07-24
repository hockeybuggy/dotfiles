---
name: use-pi-subagent
description: Invoke the `pi` coding agent as a non-interactive subagent from the shell — delegate a self-contained coding or analysis task to a fresh pi process and read its structured JSON output. Use when asked to "run pi", "use pi as a subagent", "delegate this to pi", or to orchestrate pi coder/reviewer agents (see prompt.md).
allowed-tools: Bash(pi:*)
---

# Using pi as a subagent

`pi` is a standalone AI coding assistant (read/bash/edit/write tools). You can
drive it from a Bash call as a **subagent**: hand it a self-contained prompt, let
it run to completion non-interactively, and inspect its structured output plus
whatever it changed on disk. Each run is independent — pi does not share your
context, so the prompt must carry everything the task needs.

Use this when you're asked to delegate a discrete unit of work to pi, or to act
as a supervisor orchestrating pi coder/reviewer agents.

## Canonical invocation

Always run pi in **JSON mode**, non-interactively, one shot per task:

```bash
prompt_file="/path/to/task.prompt.md"   # write the full task prompt here first
json_log="/path/to/run.jsonl"           # unique per attempt so logs never overwrite
stderr_log="/path/to/run.stderr.log"

if pi \
  --mode json \
  --print \
  --model openai-codex/gpt-5.6-terra \
  --approve \
  --no-session \
  "$(cat "$prompt_file")" \
  >"$json_log" \
  2>"$stderr_log" \
  </dev/null
then
  echo "pi exited 0"
else
  echo "pi failed: $?"
fi
```

Write the prompt to a file first, then pass it as a single positional argument
via `"$(cat "$prompt_file")"`. This keeps the prompt out of your shell history,
makes it auditable, and works with any path.

## What each flag does

| Flag | Purpose |
| --- | --- |
| `--mode json` | Emit one JSON object per line (an event stream), not prose. Inherently **non-interactive**: pi runs bash/edit/write tools with no approval prompt and exits on its own. |
| `--print` / `-p` | Force one-shot non-interactive execution and exit. Redundant with JSON mode today, but makes intent explicit and is harmless. |
| `--model openai-codex/gpt-5.6-terra` | `provider/id` form — no separate `--provider` needed. Pick the model per task (see below). |
| `--approve` / `-a` | Trust project-local resources (the repo's `CLAUDE.md`/`AGENTS.md`, extensions, custom tools) for this run. It does **not** gate tool execution — that is already auto-approved in non-interactive mode. |
| `--no-session` | Ephemeral run: nothing is saved, and the agent starts with fresh context. Use this for independent subagent tasks. |
| `</dev/null` | Guarantees pi never blocks trying to read stdin. |

Add `--thinking <off|low|medium|high|max>` when a task needs more or less
reasoning. Add `--no-tools` / `--tools a,b` / `--exclude-tools x` to restrict what
the subagent may do (e.g. a review-only agent that must not edit files).

## Choosing a model

List what's available and confirm the exact provider/id before using it:

```bash
pi --list-models              # everything
pi --list-models 'gpt-5.6'    # fuzzy search; prints one row per match
```

Each row is `provider  model  context  max-out  thinking  images`. Use the
`provider/model` pair verbatim in `--model`. Do not silently substitute a
different model than the task asked for.

## Reading the result

pi is synchronous — when the command returns, the run is done. Judge it from the
**exit status, stderr, the JSON stream, and the actual filesystem/git changes**,
in that order of reliability.

The stream begins with a `session` / `agent_start` event, streams
`message` / `thinking` / `toolcall` / `tool_execution` events, and ends with
`agent_end` then `agent_settled` right before exit. A stream missing
`agent_settled` means pi was killed or crashed mid-run.

Useful `jq` extractions against the `.jsonl` log:

```bash
# The agent's final answer text
jq -r 'select(.type=="agent_end") | .messages[-1].content[]
       | select(.type=="text") | .text' "$json_log"

# Did it intend to retry (i.e. hit an error)?
jq -c 'select(.type=="agent_end") | {willRetry}' "$json_log"

# Total cost of the run
jq -r 'select(.type=="agent_end") | .messages[-1].usage.cost.total' "$json_log"

# Every tool the subagent actually executed
jq -c 'select(.type=="tool_execution_start") | .' "$json_log"
```

For a delegated coding task, **do not trust the final text alone** — verify the
files it claims to have changed, run the relevant tests/lint yourself, and check
`git status` before treating the work as done.

## Writing the delegation prompt

Because `--no-session` gives pi a cold start, the prompt must be complete:

- The exact task and what is explicitly out of scope.
- Relevant repo conventions and any hard rules (e.g. "never commit financial
  data" in this repo).
- Which files to read first, and the tests/validation to run.
- Exactly what output you expect: files changed, a committed SHA, a written
  report file, etc.
- If you're supervising multiple pi agents, a machine-readable hand-off:
  instruct the agent to write a marker file (e.g. `task-complete.md`) rather than
  relying on parsing prose. See `prompt.md` in this repo for the full
  coder/reviewer/supervisor protocol.

## Supervisor autonomy

When you're supervising a multi-plan or multi-agent run, keep it moving — don't
stop for approval on routine, reversible steps:

- Proceed without asking on: worktree creation, rebases, test runs, and opening
  or merging a PR once CI is green. Batch any genuine questions and surface them
  together rather than interrupting per-step.
- **Only stop for decisions that are destructive, irreversible, or
  scope-changing.** `--force` on a throwaway container or worktree is fine
  without asking; anything touching real data or `main` history needs explicit
  confirmation first.

## Definition of done

A delegated plan is complete only when **all** of these hold — report the PR
number and a one-line summary of what you actually verified:

- Tests pass in an **isolated stack** (see [[isolating-test-stacks]]), not
  against shared or live services.
- The diff is **independently re-verified** — you read it yourself, not just
  trusting the coder subagent's final text.
- **CI is green** on the PR.
- The PR is **merged**.

## Output hygiene

- **Never glob or `cat` secret stores into tool output** — anything under
  `~/.pi/`, `~/.config/`, or any `*credentials*` / `*.json` secret file. Use
  `jq` to extract only the specific non-secret field you need.

## Gotchas

- **Prefer `"$(cat file)"` over pi's `@file` include syntax.** `@file` silently
  fails on nested paths (no error, empty message, exit 0). `"$(cat file)"` is
  reliable for any path.
- **JSON mode is not `--mode rpc`.** pi also has `--mode rpc`, a persistent
  bidirectional stdin/stdout protocol for driving one long-lived agent turn by
  turn. That is a different, heavier interaction model. For one-shot subagent
  delegation, use `--mode json`, not `rpc`.
- **Each run is stateless with `--no-session`.** To continue a specific prior
  run instead, drop `--no-session` and use `--continue` / `--resume` /
  `--session <id>` — but for clean, independent subagents, fresh is better.
- **The subagent inherits your working directory.** `cd` to the right repo (or
  ensure the Bash call runs there) so its relative paths and context-file
  discovery resolve correctly.
- **Give unique log filenames per attempt** so retries don't clobber the audit
  trail.
