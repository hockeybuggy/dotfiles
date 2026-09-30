---
name: using-git-worktrees
description: Creates and manages isolated git worktrees for feature development. Use when starting a new feature, working on a plan, or any time development work should be isolated from the main branch. Triggers on "start working on", "new feature", "create a branch", "implement the plan", or after a design/spec has been approved. Always set up a worktree before implementation begins. Also use when cleaning up a merged PR's branch or worktree.
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
cleanup, use the checked helper from the main checkout. Don't remove a
worktree another agent is still using.

```bash
~/.bin/git-cleanup-merged-pr --repo /path/to/repo 123
```

Add `--delete-remote` only when the user or repository rules call for remote
branch deletion. Check each PR independently; leave unmerged PRs alone.

The helper verifies the PR is merged on GitHub before any deletion. Local
and remote branch tips must match the merged PR's head exactly, and the
branch's actual worktree must be clean. It rejects fork PRs, default/base
branches, locked worktrees, and differing origin fetch/push URLs. Remote
deletion uses an explicit SHA lease to protect changes made during cleanup.
It tries `git branch -d` first; `-D` is only a fallback after merge and tip
verification, so squash/rebase merges don't block safe cleanup.

Bootstrap installs the helper in `~/.bin` and its narrowly scoped Claude
permission rule. Do not add blanket permissions for Git deletion commands.
If the helper is missing, ask the user to run bootstrap with their recorded
mode. If tool permissions block it, report the exact command and denial and
request scoped approval; in Claude, direct the user to `/permissions` →
Recently denied to approve a retry. Don't disguise the command or bypass
the block with an interpreter or alternative deletion commands.
