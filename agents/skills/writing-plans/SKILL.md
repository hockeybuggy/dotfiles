---
name: writing-plans
description: Writes detailed implementation plans with bite-sized tasks, exact file paths, complete code, and TDD steps. Use when a design or spec has been approved and is ready to be turned into an implementation plan. Triggers on "write a plan for this", "create an implementation plan", "how do we build this", "plan out the implementation", or after brainstorming/design is complete. Always write plans before starting implementation — never skip to code.
---

# Writing Plans

**Announce:** "I'm using the writing-plans skill to create the implementation plan."

## Principles

Write for an engineer who is **skilled but has zero context** on your codebase, tooling, or domain. Assume they:
- Don't know file locations or naming conventions
- Won't make good test design decisions without guidance
- Will implement tasks out of order if the plan allows it
- Will add extra features if the spec leaves room

**DRY. YAGNI. TDD. Frequent commits.**

## Plan Format

Save to: `docs/plans/YYYY-MM-DD-<feature-name>.md`

```markdown
# [Feature Name] Implementation Plan

> **For implementors:** Work through tasks using the executing-plans or subagent-driven-development skill.

**Goal:** [One sentence]  
**Architecture:** [2–3 sentences]  
**Tech stack:** [Key technologies]

---

### Task 1: [Component Name]

**Files:**
- Create: `exact/path/to/new-file.py`
- Modify: `exact/path/to/existing.py`
- Test: `tests/exact/path/to/test_file.py`

- [ ] **Step 1: Write the failing test**
  ```python
  def test_specific_behavior():
      result = function_under_test(input_value)
      assert result == expected_value
  ```

- [ ] **Step 2: Run test — confirm it fails**
  ```
  pytest tests/exact/path/to/test_file.py::test_specific_behavior -v
  ```
  Expected: FAIL — `function_under_test` not defined

- [ ] **Step 3: Write minimal implementation**
  ```python
  def function_under_test(input_value):
      return expected_value
  ```

- [ ] **Step 4: Run test — confirm it passes**
- [ ] **Step 5: Commit**
  ```
  git commit -m "feat: add function_under_test"
  ```
```

## Required in Every Task

- **Exact file paths** — no "put it somewhere in the models directory"
- **Complete code** — no "similar to Task 3", no TBD, no "add appropriate error handling"
- **Working test code** — not "write tests for the above"
- **Run commands** — exact commands the implementor should run to verify
- **Commit message** — what to commit after the task

## Forbidden Patterns (These Make a Plan Fail)

- `"TBD"`, `"TODO"`, `"implement later"`, `"fill in details"`
- `"Add appropriate error handling"` without showing what the handler looks like
- `"Write tests for the above"` without actual test code
- `"Similar to Task N"` — repeat the code; tasks may be done out of order
- Steps that say what to do without showing how

## After Writing the Plan

Self-review checklist:
- [ ] Every requirement in the spec maps to at least one task
- [ ] No placeholders anywhere
- [ ] Every task has test code, implementation code, and a run command
- [ ] Tasks are ordered so each one can be done without needing a later task
- [ ] Total task count is realistic for the scope (2–5 min per task is ideal)
