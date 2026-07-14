---
name: finishing-a-development-branch
description: Guides the process of completing a feature branch — verifying tests, choosing merge/PR/keep/discard, and cleaning up the worktree. Use when all tasks on a feature branch are done, or when the user says "I'm done", "ready to merge", "wrap this up", or "finish the branch". Always verify tests pass and get an explicit merge decision before cleanup.
---

# Finishing a Development Branch

**Announce:** "I'm using the finishing-a-development-branch skill."

## Step 1: Final Verification

Before anything else, confirm the branch is actually done:

```bash
# All tests pass?
[your test command]

# Any uncommitted changes?
git status

# Review what changed
git diff main...HEAD --stat
git log main..HEAD --oneline
```

If tests are failing: **do not proceed**. Fix the failures first.

## Step 2: Self-Review

Read through the diff with fresh eyes:

```bash
git diff main...HEAD
```

Ask:
- Does this match the spec/plan?
- Any debug code, TODOs, or print statements left in?
- Any files accidentally modified?

## Step 3: Choose a Path

Present these options to the user:

**A) Merge directly**
```bash
cd ../project-main
git merge feature/feature-name
git worktree remove ../project-feature-name
git branch -d feature/feature-name
```

**B) Open a Pull Request**
```bash
git push origin feature/feature-name
# Then open PR via GitHub/GitLab/etc.
# Worktree stays until PR is merged
```

**C) Keep branch, not merging yet**
```bash
git push origin feature/feature-name
# Worktree can stay or be removed
git worktree remove ../project-feature-name  # optional
```

**D) Discard the work**
```bash
cd ../project-main
git worktree remove ../project-feature-name
git branch -D feature/feature-name  # -D forces deletion
```

## Step 4: Cleanup

After merge (options A or after B's PR merges):

```bash
# Remove the worktree directory
git worktree remove ../project-feature-name

# Delete the local branch
git branch -d feature/feature-name

# Optionally delete remote branch
git push origin --delete feature/feature-name
```

## Checklist

- [ ] All tests passing
- [ ] No uncommitted changes
- [ ] Diff reviewed against spec
- [ ] Merge decision made and executed
- [ ] Worktree and branch cleaned up
