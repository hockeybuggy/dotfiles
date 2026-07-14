---
name: executing-plans
description: Executes an implementation plan in batches with human checkpoints between each batch. Use when a plan exists and should be worked through with periodic human review rather than full automation. Triggers on "execute this plan", "work through the plan", "implement step by step", or when the user wants to be involved at each checkpoint rather than letting it run fully autonomous. Prefer subagent-driven-development for full task-by-task review; use this when batch checkpoints are preferred.
---

# Executing Plans

**Announce:** "I'm using the executing-plans skill. I'll work through the plan in batches and check in with you between each."

## Setup

Before starting:
1. Confirm which plan file to use
2. Confirm batch size (default: 3 tasks per batch, or natural groupings)
3. Confirm the test command to run between batches

## The Batch Loop

### Start of Each Batch

Show the user which tasks are in this batch:
```
Batch [N] — Tasks [X–Y]:
- Task X: [name]
- Task X+1: [name]
- Task Y: [name]

Starting...
```

### Work Through the Batch

For each task:
- Implement it following TDD (write test first)
- Verify tests pass
- Commit

### End of Batch Checkpoint

After completing the batch, run the full test suite, then report:

```
Batch [N] complete ✅

Tasks done:
- [X]: [brief description of what was implemented]
- [X+1]: [brief description]
- [Y]: [brief description]

Tests: [N passing, 0 failing]
Commits: [N]

Issues encountered: [none / description of any deviations]

Next batch: Tasks [A–B] — [brief description]
Continue?
```

**Wait for user confirmation before the next batch.**

## Handling Problems Mid-Batch

If a task hits a blocker:
1. Complete any tasks in the batch that don't depend on the blocked task
2. Report the blocker clearly at the checkpoint
3. Propose options before proceeding

## Tracking Progress

Maintain a running summary using the plan's checkbox syntax:
```
- [x] Task 1: Done
- [x] Task 2: Done
- [ ] Task 3: In progress (current batch)
- [ ] Task 4: Pending
```

Show this at each checkpoint so the user can see where you are.

## Checklist for Completion

- [ ] All tasks checked off
- [ ] Full test suite passing
- [ ] No skipped tasks without user sign-off
- [ ] Proceed to finishing-a-development-branch
