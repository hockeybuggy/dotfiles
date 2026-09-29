---
name: executing-plans
description: Carry out an implementation plan written with the writing-plans skill, from worktree to draft PR. Use when asked to "execute this plan", "work through the plan", or "implement the plan".
---

# Executing Plans

## Before starting

1. Read the whole plan.
2. Create a worktree for the work with the `using-git-worktrees` skill and do
   everything there.

## Working through it

- Work through the tasks in order without stopping to check in.
- Stop and ask the user only when you're blocked, or when you'd need to do
  something the plan doesn't say (a different approach, extra files, skipping
  a task). Explain what you found and what you propose.
- Write the failing test first, as the plan says, and check it fails before
  implementing.
- Run only the targeted tests the plan gives you, or the tests for files you
  changed. **Never run the full test suite** unless the user asks.
- Tick each step's checkbox (`- [x]`) in the plan file as you finish it, so
  another session can pick up where you left off.
- Commit in groups a reviewer would want to read together, not one commit
  per task. Follow the `commit` skill for messages.

## When every task is done

1. Check `git status` is clean and read the full diff against the base
   branch for leftovers: debug output, stray files, unrelated changes.
2. If the repo's `AGENTS.md`/`CLAUDE.md` says to merge locally, do that.
   Otherwise push the branch and open a **draft** PR without asking. Ask
   before marking it ready for review.
3. Report the PR link and anything you deviated from in the plan.
