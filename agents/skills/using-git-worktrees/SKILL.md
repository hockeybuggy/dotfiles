---
name: using-git-worktrees
description: Creates and manages isolated git worktrees for feature development. Use when starting a new feature, working on a plan, or any time development work should be isolated from the main branch. Triggers on "start working on", "new feature", "create a branch", "implement the plan", or after a design/spec has been approved. Always set up a worktree before implementation begins. Also use when cleaning up merged branches or worktrees.
---

# Using Git Worktrees

Worktrees let you work on a feature branch in a separate directory without disturbing your main working tree. Each feature gets its own directory and branch.

## Setup (run these commands)

```bash
# 1. Create a worktree on a new branch from the latest main
git fetch origin
git worktree add -b feature/feature-name .worktrees/feature-name origin/main

# 2. Move into the worktree
cd .worktrees/feature-name

# 3. Run your project setup (install deps, etc.)
# e.g.: npm install / pip install -r requirements.txt / bundle install
```

Don't run the full test suite to get a baseline.

## Naming Convention

- Directory: `.worktrees/<feature-name>` (repo root, alongside `.git`)
- Branch: `feature/<feature-name>` or `fix/<bug-name>`

Always put worktrees under `.worktrees/`, never in sibling directories.
`.worktrees/` is in the global git ignore, so the nested worktrees don't
show up as untracked content in the main tree.

## Working in the Worktree

All development happens in the worktree directory. Your main branch directory is untouched. You can switch between them freely.

```bash
# Check which worktrees exist
git worktree list
```

## Cleaning up

When the user confirms a merge, or repository rules require post-merge
cleanup, carry it out rather than handing back commands for the user to run.
Verify before removing anything:

- Confirm the PR is merged and identify its branch. Use `git worktree list`
  to find the actual worktree; its directory name may differ from the branch.
- Check the worktree's status and whether the branch has work outside the
  merge. Preserve uncommitted, untracked, and unmerged work. Don't remove
  a worktree another agent is still using.
- Work from the main checkout. Leave default, shared, and release branches
  alone.

Use ordinary Git commands, adapting paths and branches to the repository:

```bash
git worktree remove .worktrees/feature-name
git branch -d feature/feature-name
```

If `-d` refuses after a squash/rebase merge, use `-D` only after confirming
the merge and that no additional work would be lost. Never force removal
of a dirty worktree.

Delete the remote branch only when the user or repository rules call for
it. Check its current tip for work outside the merge before deleting it;
use an explicit SHA lease if it may be changing concurrently.

```bash
git push origin --delete feature/feature-name
```

Claude's global `autoMode.allow` rule permits verified post-merge cleanup
without requiring a wrapper or a particular Git invocation. If permissions
still block a command, report the exact command and denial and request
scoped approval. Don't disguise or reroute the same command to bypass the
block.
