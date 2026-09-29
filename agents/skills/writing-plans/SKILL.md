---
name: writing-plans
description: Write an implementation plan for another, usually less capable, model to carry out with the executing-plans skill. Use when the user asks for a plan ("write a plan", "plan out the implementation", "how do we build this"), or before starting large work.
---

# Writing Plans

Write a plan when the user asks for one, or before starting large work.

## Who will execute it

The plan is carried out by another model, often a much less capable one. If
the user hasn't said which model, ask before writing. Scale the detail to it:
a slightly weaker model needs the approach and the traps, while a small local
model needs every file, function name and command spelled out, plus code for
anything easy to get wrong.

## Where it goes

Follow the repo's convention if it has one (check `AGENTS.md`/`CLAUDE.md` and
existing plan directories). Otherwise save it to
`.plans/YYYY-MM-DD-<name>.md`, which is ignored globally. Don't commit it.

## Format

```markdown
# <Feature> plan

Execute with the `executing-plans` skill. Executor: <model>.

**Goal:** <one sentence>
**Approach:** <2–3 sentences on the design and why>
**Out of scope:** <what not to touch>

### Task 1: <name>

**Files:** `path/to/file.py` (modify), `tests/path/test_file.py` (create)

**Approach:** <what to change and how, the functions involved, edge cases>

- [ ] Write a failing test for <behaviour> in `tests/path/test_file.py`
- [ ] Run `<targeted test command>` and check it fails because <reason>
- [ ] Implement <change>
- [ ] Run `<targeted test command>` and check it passes
```

## Rules

- Every task has test-first steps and exact, **targeted** test commands.
  Never have the executor run the full suite.
- Order tasks so each one only depends on earlier ones.
- Keep code to what the executor would otherwise get wrong. Don't write the
  whole implementation into the plan.
- No placeholders: no "TBD", "add appropriate error handling", or "similar
  to Task 2".
- Say where commit boundaries fall if it isn't obvious, e.g. "commit after
  Tasks 1–3: the parser change".
