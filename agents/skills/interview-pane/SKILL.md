---
name: interview-pane
description: "Ask the user a set of interview questions by writing them to a Markdown file, opening it in vim/nvim in a new pane in the user's own tmux session, waiting until they close the editor, then reading their answers back. Use when you want to interview the user, collect answers in an editor rather than chat, or when the user says things like 'open interview questions in vim', 'ask me questions in a tmux pane', or 'let me answer in my editor'. Requires the agent to be running inside a tmux session."
---

# Interview Pane Skill

Interview the user in their editor instead of in chat: write the
questions to a Markdown file, open it in a new pane in *their* tmux
session, block until they close the editor, then read their answers.

This is the right tool when the answers are long-form, when several
questions are easier to answer together in one buffer, or when the
user simply prefers typing in vim/nvim over the chat box.

## When to use

- The user asks to answer questions in their editor / a tmux pane.
- You have a batch of questions and want them all answered at once.
- The answers benefit from editing (reordering, code snippets, prose).

For a single quick question, just ask in chat — don't bother.

## Prerequisites

- **The agent must be running inside the user's tmux session.** The
  pane has to be visible to the user, so `$TMUX` must be inherited.
  If `$TMUX` is empty, bail with a clear message and ask the question
  in chat instead — do not proceed.
- `nvim` (preferred, at `/opt/homebrew/bin/nvim`) or `vim` on `$PATH`.

## The critical caveats (read these — they are the exact bugs hit before)

### 1. Use the user's tmux, NOT an isolated socket

The `tmux` skill's `-L agent` socket is **wrong here**. The user is not
attached to that server, so they can never see or type in the pane.
This skill splits inside the user's own session on the **default tmux
socket** (plain `tmux ...`, no `-L`).

Detect the session from `$TMUX`, whose format is
`<socket-path>,<server-pid>,<session-id>`:

```bash
[ -n "${TMUX:-}" ] || { echo "not inside tmux; ask in chat instead"; exit 1; }
```

Plain `tmux split-window` (no `-t`) splits the session's active pane —
exactly what we want.

### 2. Sandbox: tmux commands need `dangerouslyDisableSandbox: true`

Under Claude Code's default sandbox, connecting to the user's tmux
socket fails with:

```
error connecting to /private/tmp/tmux-501/default (Operation not permitted)
```

So **every `tmux` command that touches the user's socket must be run
with the Bash tool's `dangerouslyDisableSandbox: true`.** That means
the `split-window` and any `list-panes`/`kill-pane` calls. The
`watch-editor.sh` watcher does **not** touch tmux (it only reads the
process table), so it runs fine inside the sandbox.

### 3. Split orientation is a parameter — and easy to get backwards

`tmux split-window`'s flags are the opposite of how people say it out
loud:

| Flag | tmux meaning        | Divider    | Panes are   | Colloquial name    |
| ---- | ------------------- | ---------- | ----------- | ------------------ |
| `-h` | split horizontally  | vertical   | left/right  | "vertical split"   |
| `-v` | split vertically    | horizontal | top/bottom  | "horizontal split" |

So when the user says "split horizontally" they almost always mean
**top/bottom**, which is `-v`. Confirm which they want if unsure.
Default here is `-h` (side-by-side), which gives the editor a full-
height column.

### 4. Editor and working directory are parameters

Default to `nvim`; fall back to `vim`. Resolve concretely — tmux runs
the pane command via `/bin/sh -c`, which does not read shell aliases.
Set the pane's working directory with `-c <cwd>`:

```bash
tmux split-window <orient> -c "<cwd>" "<editor> '<file>'"
```

### 5. The watcher race condition (the single most important fix)

A naive `until ! pgrep -f "<editor> <file>"; do sleep; done` **exits
immediately and falsely reports the editor closed** — because it runs
before tmux has even spawned the editor process. The watcher must be
two phases: first wait for the process to **appear** (with a timeout),
*then* wait for it to **disappear**. That is exactly what
`watch-editor.sh` (shipped with this skill) does. Run it as a
**backgrounded** Bash tool call (`run_in_background: true`) so you get
a completion notification the moment the editor closes.

### 6. pgrep pattern gotcha

`pgrep -f "vim ..."` also matches `nvim` (substring), so track a
precise pattern anchored on the unique interview filename:
`pgrep -f "n?vim .*<basename>"`. The watcher builds this for you.

## The flow

### 1. Write the questions file

Use a **unique** filename (the watcher matches on it) somewhere
writable, e.g. `"$TMPDIR/interview-$(date +%s).md"`. One `> ANSWER:`
block per question, so the user types inline:

```markdown
# Interview

Answer inline under each question, on the `> ANSWER:` line. Save and
quit (`:wq`) when you're done, or `:q!` to cancel.

## 1. <first question>

> ANSWER:

## 2. <second question>

> ANSWER:
```

Write this with the `Write` tool — that path is inside the sandbox, no
override needed.

### 2. Split a pane and open the editor (needs sandbox override)

```bash
# dangerouslyDisableSandbox: true — touches the user's tmux socket
[ -n "${TMUX:-}" ] || { echo "not inside tmux"; exit 1; }
ED=$(command -v nvim || command -v vim)
FILE="$TMPDIR/interview-1234.md"   # the file you just wrote
PANE=$(tmux split-window -h -c "$PWD" -P -F '#{pane_id}' "$ED '$FILE'")
echo "opened pane $PANE"
tmux list-panes -F '#{pane_id} #{pane_current_command}'   # verify
```

Capturing `#{pane_id}` lets you verify and clean up later.

### 3. Wait for the editor to close (backgrounded, in-sandbox)

Run the watcher as a background tool call so a notification fires on
close. Pass the **basename** of the file:

```bash
# run_in_background: true — no sandbox override needed (no tmux here)
/abs/path/to/interview-pane/watch-editor.sh "interview-1234.md" 120
```

Resolve the absolute path from where this `SKILL.md` lives; don't
hardcode `~/.claude/...`. Exit codes: `0` = editor opened and closed,
`3` = it never appeared within the timeout (investigate the pane).

### 4. Read the answers back

Once the watcher reports `CLOSED`, read the file with the `Read` tool
and extract the text after each `> ANSWER:`.

**Handle the empty / unchanged case honestly.** If the user quit with
`:q!` or saved without typing, every `ANSWER:` line will still be
blank. Do **not** fabricate answers — report that no answers were
provided and offer to reopen the pane (the flow is safe to re-run).

```bash
# quick check: any non-empty answer?
grep -A0 '> ANSWER:' "$FILE" | grep -qv '> ANSWER:[[:space:]]*$' \
  || echo "no answers were entered"
```

### 5. Cleanup and re-runnability

- The pane closes itself when the user quits the editor, so there is
  usually nothing to tear down. If a launch failed and left a stray
  pane, close it explicitly (this touches the socket — sandbox
  override): `tmux kill-pane -t "$PANE"`.
- Verify with `tmux list-panes` if in doubt — an earlier version of
  this flow once left an orphan pane behind.
- Every step uses a fresh unique filename, so re-running to re-ask or
  to reopen after a `:q!` is safe and collides with nothing.

## Pitfalls

- **`-L agent`.** Wrong server; the user can't see it. Use the default
  socket (plain `tmux`).
- **Forgetting the sandbox override** on `tmux` calls — you'll get
  "Operation not permitted". The watcher does not need it.
- **The immediate-exit watcher bug.** Always wait for *appear* before
  waiting for *disappear*. Use `watch-editor.sh`; don't inline a naive
  loop.
- **`vim` vs `nvim` substring match** in pgrep — anchor on the unique
  filename with the `n?vim` pattern.
- **Orientation backwards.** `-v` is top/bottom, `-h` is side-by-side.
- **No `$TMUX`.** Don't try to open a pane; ask in chat.
- **Fabricating blank answers.** If the file is unchanged, say so and
  offer to reopen.
