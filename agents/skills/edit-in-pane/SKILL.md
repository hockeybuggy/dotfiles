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

It also works as `$GIT_EDITOR` for commit messages and rebase todo lists:

```zsh
GIT_EDITOR="$skill_dir/edit-in-pane.sh" git commit
```

Without `$HERDR_ENV` the script exits 1. Say so, and fall back to asking in
chat.
