---
name: edit-commit-message
description: "Run `git commit` (or `--amend`) with the message editor opened in a new tmux pane so the user can hand-edit interactively. Uses git's own editor flow, so `commit.verbose=true` shows the diff as usual. Waits for the editor to close, then continues. Use when the user wants to write or tweak a commit message in vim/nvim. Requires the agent to be running inside a tmux session."
---

# Edit Commit Message Skill

Hand commit-message editing off to nvim in a new tmux pane, then
resume once the user saves and quits.

The key idea: don't reinvent git's editor flow. Just point `GIT_EDITOR`
at a tiny wrapper script (shipped alongside this skill) that opens its
file argument in a tmux pane and blocks until the pane closes. Git
takes care of including the diff, stripping comments, and aborting on
empty messages.

## When to use

- User asks to edit a proposed commit message themselves.
- User wants to see the diff in the editor (their `commit.verbose=true`
  setting just works through this skill).
- Reword / amend flows: `git commit --amend`, fixing the last message.

For trivial subjects ("typo: fix x") just commit directly via the
`commit` skill — don't bother with this.

## Prerequisites

- The agent must inherit `$TMUX` from the user's session. Without it,
  the wrapper script bails with a clear error. If `$TMUX` is empty,
  ask the user to either run the agent from inside tmux or approve
  the message in chat.
- The wrapper uses the **user's default tmux server** (no `-L agent`)
  — the pane has to be visible to the user.

## How to invoke

```bash
GIT_EDITOR="$AGENT_STUFF/skills/edit-commit-message/git-editor.sh" \
  git commit
```

For amend:

```bash
GIT_EDITOR="$AGENT_STUFF/skills/edit-commit-message/git-editor.sh" \
  git commit --amend
```

Resolve the absolute path to `git-editor.sh` from this skill's
directory — don't hardcode `~/.agent-stuff/...` paths into the
command, derive them from where `SKILL.md` lives.

If the user does *not* have `commit.verbose=true` in their gitconfig
and wants the diff this one time, add `-v`:

```bash
GIT_EDITOR=".../git-editor.sh" git commit -v
```

## What the wrapper does

`git-editor.sh` is what git invokes in place of vim. It:

1. Refuses to run if `$TMUX` is unset.
2. Resolves an editor: `nvim` if available, else `vim`. (Shell aliases
   don't apply because tmux runs commands via `/bin/sh -c`.)
3. `tmux split-window` runs the editor on the file git passed in,
   with `; touch <sentinel>; tmux kill-pane` appended so the pane
   closes even when the user has `remain-on-exit on`.
4. Polls for the sentinel file (normal exit) or pane disappearance
   (external kill).
5. Returns to git, which then commits / aborts as usual.

Read the script if you need to tweak the split direction or polling:
`skills/edit-commit-message/git-editor.sh`.

## Variations

### Use a horizontal split or a new window

Edit `git-editor.sh` and change `split-window -v` to `split-window -h`
or `new-window`. The capture / poll logic is the same regardless.

### Use with interactive rebase

`GIT_EDITOR` is also what git uses for the rebase todo list and for
reword stops, so this works transparently:

```bash
GIT_EDITOR=".../git-editor.sh" git rebase -i HEAD~3
```

Each editor invocation opens its own pane in turn.

### Use as the default editor everywhere

If the user wants this behavior outside the agent too, they can put
the script on their `GIT_EDITOR` permanently in their shell profile.
That's their call, not the agent's.

## Pitfalls

- **No `$TMUX`.** The wrapper exits 1 with a clear message. Don't
  swallow that — surface it to the user and fall back to approving
  the message in chat.
- **Don't write the message and pass `-F -`.** That was the previous
  version of this skill, and it bypasses `commit.verbose`, comment
  stripping, and the user's normal git hooks. Always go through
  `git commit` so git stays in charge.
- **Shell aliases don't apply inside the pane.** tmux runs commands
  with `/bin/sh -c`. The wrapper resolves `nvim`/`vim` directly. If
  nvim plugins still error, check that `nvim` is on `$PATH` in the
  non-interactive shell — set it in `.zprofile`/`.zshenv`, not just
  `.zshrc`.
- **`remain-on-exit on`** would otherwise strand the pane after the
  editor exits. The wrapper appends `tmux kill-pane` to defeat this.
- **Empty / aborted message.** Git itself aborts the commit when the
  message is empty (or unchanged from the template). The wrapper
  doesn't need to do anything special.
