---
name: edit-in-pane
description: "Hand a file to the user in nvim in a new herdr pane, wait until they quit, then read what they wrote and carry on. Use when the user wants to answer questions, review a plan, edit a draft, or write or tweak a commit message in their editor instead of in chat — e.g. \"put these in a file and open it in vim\", \"let me edit that\", \"let me write the commit message\", \"open it in a pane\". Requires running inside herdr."
---

# Edit in pane

Write the content to a file, open it for the user, and block until they are
done:

```zsh
bash "$skill_dir/edit-in-pane.sh" "$file"
```

`edit-in-pane.sh` (in this skill's directory) splits a focused pane below
yours, runs `nvim <file>; exit` in it, prints `PANE=<id>`, and returns once
the user quits nvim and the pane closes, printing `CHANGED=yes` or
`CHANGED=no`. Then read the file and continue.

- **Write the file outside the repo** (under `$TMPDIR`) unless the user wants
  it kept, and give them its absolute path.
- **Make it easy to fill in.** For questions, put each on its own heading with
  an empty `>` line for the answer and any suggested default in brackets, and
  say at the top that blank means "take the default".
- **Don't let the wait time out.** The user may take an hour. In Claude
  Code, whose Bash tool caps at 10 minutes, run the script with
  `run_in_background` and you'll be woken when it exits. In pi, pass no
  timeout. If a wait is cut short anyway, the pane is still open, so wait
  on it again rather than opening another:

  ```zsh
  until [[ "$(herdr pane get "$pane" 2>&1)" == *'"pane_not_found"'* ]]; do sleep 1; done
  ```

- **`CHANGED=no` means they bailed**, e.g. `:q!`. Ask in chat before
  treating that as "all defaults".

## Commit messages

When the user wants to write or edit a commit message, use the script as
`$GIT_EDITOR` rather than writing the message yourself and passing `-F`:

```zsh
GIT_EDITOR="$skill_dir/edit-in-pane.sh" git commit          # or --amend
GIT_EDITOR="$skill_dir/edit-in-pane.sh" git rebase -i HEAD~3
```

Git stays in charge, so `commit.verbose` shows the diff, comments are
stripped, hooks run, and an empty message aborts the commit. A rebase opens
one pane per editor stop.

Without `$HERDR_ENV` the script exits 1. Say so, and fall back to asking in
chat.
