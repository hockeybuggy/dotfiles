---
name: subagent-driven-development
description: Implements a plan task-by-task using a two-stage review cycle — spec compliance first, then code quality. Use when an implementation plan is ready and the user wants to execute it with discipline. Triggers on "execute the plan", "implement this plan", "start working through the tasks", "let's build this", or when a writing-plans skill output is ready to be worked. Each task gets a fresh context and two-stage review before moving on.
---

# Subagent-Driven Development

**Announce:** "I'm using the subagent-driven-development skill. I'll work through the plan task by task with review after each."

## The Loop

For each task in the plan:

```
1. IMPLEMENT — work the task as specified
2. REVIEW STAGE 1 — spec compliance
3. REVIEW STAGE 2 — code quality
4. COMMIT — only after both reviews pass
5. REPORT — summary to user before next task
```

Never start the next task until the current one passes both reviews.

## Stage 1: Spec Compliance Review

Check the implementation against the plan:

- [ ] Does it implement exactly what the task specified?
- [ ] Are all the required files created/modified?
- [ ] Are the tests written and passing?
- [ ] Does it match the interfaces defined in the plan?
- [ ] No extra features or "while I'm here" additions?

If anything fails: fix it before Stage 2.

## Stage 2: Code Quality Review

Check the code itself:

- [ ] No magic numbers or unexplained constants
- [ ] No dead code or commented-out blocks
- [ ] Names are clear and consistent with the codebase
- [ ] No obvious performance issues (N+1 queries, unnecessary loops)
- [ ] Error cases handled appropriately
- [ ] No debug output left in

If anything fails: fix it before committing.

## After Each Task

Commit the work:
```bash
git add [changed files]
git commit -m "[type]: [what was implemented]"
```

Report to the user:
```
✅ Task [N] complete: [task name]
Files changed: [list]
Tests: [X passing]

Next: Task [N+1] — [task name]
Proceed?
```

Wait for confirmation before the next task.

## If a Task is Blocked

If a task can't be completed as specified (missing dependency, spec is ambiguous, discovered a problem):

1. **Stop** — don't improvise around it
2. **Report** what's blocking and why
3. **Propose** options: skip, modify spec, or address the blocker first
4. **Wait** for user decision

## Checklist Before Declaring Plan Complete

- [ ] All tasks completed and committed
- [ ] Full test suite passing
- [ ] No tasks skipped without user sign-off
- [ ] Ready to invoke finishing-a-development-branch
