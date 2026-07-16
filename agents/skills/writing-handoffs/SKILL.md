---
name: writing-handoffs
description: Writes a self-contained handoff document that briefs another agent or person to execute a scoped task without the originating context. Triggers when the user asks to "write a handoff", "hand this off", "brief another agent", "create a delegation doc", or prep work for a sub-agent / worktree agent to pick up. Emits a markdown file following a fixed template.
---

# Writing Handoffs

**Announce:** "I'm using the writing-handoffs skill to write the handoff document."

## What a handoff is

A handoff is a delegation artifact. The receiving agent starts fresh with **no
memory of this conversation**, so the handoff must carry everything needed to do
the job correctly and stop at the right place: the goal, the *why*, exactly which
files or locations to touch, the concrete change, constraints, how to set up the
environment, how to verify, and how to land the work.

A good handoff is scoped tightly enough that the receiver doesn't have to make
judgment calls the author already made. Prefer concrete instructions over
open-ended exploration. When you know the exact edit, write it out (literal
snippets, old → new) so the receiver doesn't re-derive it.

## 1. Gather the inputs

Infer as much as possible from the conversation and the codebase. Ask the user
**only** for what's genuinely missing or ambiguous. You need:

- **Task and scope** — what to do, what's explicitly in, what's explicitly out.
- **Why / background** — the motivation and the problem it solves; anything the
  receiver can't infer from the code alone.
- **Target file(s) / location** — exact paths, directories, or surfaces.
- **The concrete change** — literal snippets or old → new text where known; be
  explicit about what NOT to touch.
- **Constraints / style** — scope limits, tone, conventions to follow or avoid.
- **Environment / setup** — worktree? services? migrations? or none (docs only)?
- **Verification** — commands to run, what to eyeball, linters/specs.
- **Done criteria** — commit? open a PR? merge, or stop short?

## 2. Right-size it

Match the handoff to the task. Small tasks get a short handoff — don't pad, and
drop sections that genuinely don't apply rather than leaving empty headers. Large
or risky tasks warrant more detail on scope boundaries and verification.

Fill in defaults from project conventions instead of punting decisions to the
receiver. If the handoff targets a specific repo, read that repo's `CLAUDE.md`
for commit/PR/worktree rules and bake them into the relevant sections. Detect
whether the repo is a bare/worktree layout or a standard clone and say which.
Stay generic when no specific repo is in play.

## 3. Emit a markdown file

Write the handoff to a file named `handoff-<short-slug>.md` (the user prefers a
copyable `.md` file over rendered chat output). Default to the current working
directory unless the user names another location. **Report the path back** when
done.

## Template

Use the structure below. Drop sections that don't apply; don't leave empty
headers.

```markdown
# Handoff: <one-line task title>

## Objective
<what to do, in 1–3 sentences; state the scope and whether it's small or large>

## Why (context)
<background and motivation; what problem this solves; anything the receiver
can't infer from the code alone>

## The file(s) / location
<exact paths and, where helpful, the current structure the receiver will edit>

## The change / task
<the concrete deliverable; include literal snippets or old → new text when
known; be explicit about what NOT to touch>

## Constraints / style
<scope limits, tone/style to match, conventions to follow, things to avoid>

## Environment / setup
<worktree layout (bare vs standard), services, migrations, or "none — docs
only"; branch name and base branch>

## Verification
<how to confirm it's correct: commands to run, what to eyeball, linters/specs,
or "no linter/specs apply">

## Commit / PR
<commit-message conventions, whether to open a PR, whether to merge or stop>
```

## Quality check before handing off

- Could a fresh agent execute this without asking a follow-up question?
- Are the target paths exact, and is the concrete change spelled out (not "figure
  out the edit")?
- Is the scope boundary clear — what's out, what not to touch?
- Does it say where to stop (commit / PR / merge / halt)?
