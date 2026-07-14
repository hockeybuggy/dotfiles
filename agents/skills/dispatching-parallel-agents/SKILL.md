---
name: dispatching-parallel-agents
description: Structures and dispatches independent tasks for parallel execution across multiple Claude sessions or subagents. Use when a plan contains tasks that don't depend on each other and could be worked on simultaneously. Triggers on "do these in parallel", "work on multiple tasks at once", "split the work", or when an implementation plan has clearly independent components. Identify parallelizable work and provide ready-to-paste prompts for each parallel workstream.
---

# Dispatching Parallel Agents

**Announce:** "I'm using the dispatching-parallel-agents skill to identify parallel workstreams."

## When to Parallelize

Tasks are parallelizable when they:
- Touch different files/modules
- Don't depend on each other's output
- Could be code-reviewed independently
- Have clearly defined interfaces between them

**Do NOT parallelize** tasks that share state, modify the same files, or where Task B requires Task A's output.

## Process

### 1. Identify Independent Groups

Review the plan and group tasks by independence:

```
Group A (can run in parallel with B):
  - Task 2: Add User model
  - Task 3: Add auth middleware

Group B (can run in parallel with A):
  - Task 4: Add API client wrapper
  - Task 5: Write API integration tests

Sequential (must run after A and B):
  - Task 6: Wire auth to API client
```

### 2. Write a Dispatch Prompt for Each Agent

For each parallel workstream, write a self-contained prompt that includes:
- The full context the agent needs (don't assume it has project knowledge)
- The specific tasks to complete
- How to verify success (test commands)
- What to commit when done

**Template:**
```
You are working in a git worktree for feature/[name].
The codebase is a [brief description].

Your task: [specific tasks]

Files to modify:
- [exact file paths]

How to verify your work:
- Run: [test command]
- Expected: [expected output]

When done, commit with message: "[prefix]: [description]"
```

### 3. Launch and Monitor

Open one Claude session per workstream. Paste the dispatch prompt. Let them run independently. Collect and review their outputs before merging.

## Merging Results

After all agents complete:
1. Review each branch's diff before merging
2. Look for conflicts in shared files
3. Run the full test suite after merging all branches
4. Resolve any integration issues before declaring done
