---
name: test-driven-development
description: Enforces RED-GREEN-REFACTOR test-driven development. Use when implementing features, fixing bugs, or writing any code. Triggers on phrases like "implement this", "add a feature", "write code for", "fix this bug", "TDD", "write tests first". Never write implementation code before a failing test exists — always enforce this order regardless of how the request is phrased.
---

# Test-Driven Development

**Announce:** "I'm using the test-driven-development skill. I'll write a failing test before any implementation."

## The Cycle

```
RED → write failing test → verify it fails for the RIGHT reason
GREEN → write minimal code to pass → verify it passes
REFACTOR → clean up → keep all tests green
REPEAT
```

## RED Phase

Write ONE minimal test that captures the desired behavior. Show it to the user. The test must:
- Test a single behavior
- Have a descriptive name (no "and" — if you need "and", split it)
- Fail because the code doesn't exist yet, not because of a syntax error

```python
# Example
def test_retries_failed_operation_three_times():
    attempts = []
    def flaky():
        attempts.append(1)
        if len(attempts) < 3:
            raise RuntimeError("not yet")
        return "ok"
    assert retry(flaky) == "ok"
    assert len(attempts) == 3
```

Show the expected failure output. Ask the user to run it and confirm it fails.

## GREEN Phase

Write the **minimal** code that makes the test pass. No extras. No "while I'm here" improvements. If the test passes, confirm with the user before moving on.

## REFACTOR Phase

Clean up duplication, naming, structure — without adding behavior. Re-run the scoped tests after each change. If anything goes red, revert immediately.

## Scope of Test Runs

Every run in the cycle is the **narrowest** one that answers the question — usually the single test, at most its file:

```
pytest path/to/test_file.py::test_name    # RED and GREEN
pytest path/to/test_file.py               # REFACTOR, if the file is small
```

If the project has a test wrapper (`./scripts/test.sh`, `make test`, `bin/rspec`), use it with the same path/test argument rather than running it bare.

Run the **full suite** only when there's a reason to:
- Right before opening a PR or handing the branch back
- After a change with wide blast radius (migrations, shared interfaces, config)
- When a scoped run fails in a way that suggests unrelated breakage
- When the plan or the user explicitly asks for it

Full runs are slow — often a Docker stack — and re-running one after every task burns time without finding anything a scoped run missed. Don't run it "just to be safe" between tasks. This applies just as much when running headless with nobody to confirm with.

## Rules

- **Test fails for wrong reason?** Fix the test, not by adding code — go back to RED.
- **Bug found?** Write a failing test that reproduces it first. Never fix bugs without a test.
- **Code written before a test?** Delete it. Start over. The sunk cost is already gone.
- **"I'll write tests after"?** No. Tests-after prove nothing — you already know it works.

## Checklist Before Moving to Next Task

- [ ] Test was written and confirmed failing before implementation
- [ ] Implementation is minimal (nothing beyond what the test requires)  
- [ ] Scoped tests for the changed code are passing
- [ ] Code committed
