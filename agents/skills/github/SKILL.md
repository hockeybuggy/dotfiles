---
name: github
description: "Interact with GitHub using the `gh` CLI. Use `gh issue`, `gh pr`, `gh run`, and `gh api` for issues, PRs, CI runs, and advanced queries."
---

# GitHub Skill

Use the `gh` CLI to interact with GitHub. Always specify `--repo owner/repo` when not in a git directory, or use URLs directly.

## Pull Requests

Check CI status on a PR:
```bash
gh pr checks 55 --repo owner/repo
```

List recent workflow runs:
```bash
gh run list --repo owner/repo --limit 10
```

View a run and see which steps failed:
```bash
gh run view <run-id> --repo owner/repo
```

View logs for failed steps only:
```bash
gh run view <run-id> --repo owner/repo --log-failed
```

## Label the tmux window with the issue

When you start work on a specific issue or PR, record its identifier so the
tmux window title says which one you are on:

```bash
bash ~/.claude/hooks/tmux-title.sh --task '#123'
```

Use `owner/repo#123` when the issue lives in a different repo than the working
directory. The script is a no-op outside tmux, and it only shows the task while
the agent has the window to itself — in a split window the title stays generic.
The status hooks keep the identifier in the title on every later rename, so set
it once when the work starts. Clear it when you move off the issue:

```bash
bash ~/.claude/hooks/tmux-title.sh --task
```

Under pi the same script is at `~/.pi/agent/scripts/tmux-title.sh`.

## Returning URLs to the user

When you hand back a PR or any URL the user will click, print it as a **bare
plain-text URL on its own line** — not a Markdown link. A bare URL is
unambiguous and reliably clickable in a terminal; `[text](url)` is not.

```
https://github.com/owner/repo/pull/55
```

## API for Advanced Queries

The `gh api` command is useful for accessing data not available through other subcommands.

Get PR with specific fields:
```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
```

## JSON Output

Most commands support `--json` for structured output.  You can use `--jq` to filter:

```bash
gh issue list --repo owner/repo --json number,title --jq '.[] | "\(.number): \(.title)"'
```
