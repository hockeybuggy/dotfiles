---
name: using-git-worktrees
description: Creates and manages isolated git worktrees for feature development. Use when starting a new feature, working on a plan, or any time development work should be isolated from the main branch. Triggers on "start working on", "new feature", "create a branch", "implement the plan", or after a design/spec has been approved. Always set up a worktree before implementation begins.
---

# Using Git Worktrees

**Announce:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

Worktrees let you work on a feature branch in a separate directory without disturbing your main working tree. Each feature gets its own directory and branch.

## Setup (run these commands)

```bash
# 1. Make sure your main branch is clean
git status

# 2. Create a worktree for the feature
git worktree add ../project-feature-name feature/feature-name
# This creates: a new directory at ../project-feature-name
#               a new branch: feature/feature-name

# 3. Move into the worktree
cd ../project-feature-name

# 4. Run your project setup (install deps, etc.)
# e.g.: npm install / pip install -r requirements.txt / bundle install

# 5. Verify tests pass before touching anything
# e.g.: pytest / npm test / rails test
```

## Naming Convention

- Directory: `../project-<feature-name>` (sibling of your main project dir)
- Branch: `feature/<feature-name>` or `fix/<bug-name>`

## Working in the Worktree

All development happens in the worktree directory. Your main branch directory is untouched. You can switch between them freely.

```bash
# Check which worktrees exist
git worktree list

# Remove a worktree when done (after merge)
cd ../project-main
git worktree remove ../project-feature-name
git branch -d feature/feature-name
```

## Checklist Before Starting Work

- [ ] Main branch is clean (`git status` shows nothing uncommitted)
- [ ] Worktree created on a new branch
- [ ] Dependencies installed in worktree
- [ ] Test suite passes in clean state (baseline confirmed)
