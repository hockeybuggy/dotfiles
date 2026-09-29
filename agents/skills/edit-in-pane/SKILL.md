---
name: edit-in-pane
description: "Hand a file to the user in nvim in a new herdr pane, wait until they quit, then read what they wrote and carry on. Use when the user wants to answer questions, review a plan, or edit a draft in their editor instead of in chat — e.g. \"put these in a file and open it in vim\", \"let me edit that\", \"open it in a pane\". Requires running inside herdr."
---

# Edit in pane

Write the content to a file, open it for the user, and block until they are
done:

```zsh
bash "$skill_dir/edit-in-pane.sh" "$file"
```

`edit-in-pane.sh` (in this skill's directory) splits a focused pane below
yours, runs `nvim <file>; exit` in it, prints `PANE=<id>`, and returns once
the user quits nvim and the pane closes. Then read the file and continue.

- **Write the file outside the repo** (under `$TMPDIR`) unless the user wants
  it kept, and give them its absolute path.
- **Make it easy to fill in.** For questions, put each on its own heading with
  an empty `>` line for the answer and any suggested default in brackets, and
  say at the top that blank means "take the default".
- **Wait without a short timeout.** The user may take a long time. If your
  tool call times out anyway, the pane is still open, so wait again rather
  than reopening it:

  ```zsh
  while herdr pane get "$pane" >/dev/null 2>&1; do sleep 1; done
  ```

- **An unchanged file means they bailed**, e.g. `:q!`. Ask in chat before
  treating that as "all defaults".

It also works as `$GIT_EDITOR` for commit messages and rebase todo lists:

```zsh
GIT_EDITOR="$skill_dir/edit-in-pane.sh" git commit
```

Without `$HERDR_ENV` the script exits 1. Say so, and fall back to asking in
chat.
