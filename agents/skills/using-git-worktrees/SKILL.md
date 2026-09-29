---
name: using-git-worktrees
description: Creates and manages isolated git worktrees for feature development. Use when starting a new feature, working on a plan, or any time development work should be isolated from the main branch. Triggers on "start working on", "new feature", "create a branch", "implement the plan", or after a design/spec has been approved. Always set up a worktree before implementation begins.
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

When the user says the branch is merged, remove its worktree and local
branch from the main checkout:

```bash
git worktree remove .worktrees/feature-name
git branch -d feature/feature-name
```

If `git branch -d` refuses because the PR was squash-merged, confirm it's
merged on GitHub before using `-D`. Leave the worktree alone until then.
