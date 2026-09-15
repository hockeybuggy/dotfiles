---
name: deslop
description: "Strip the slop out of work you just finished — narrating comments, single-use wrappers, defensive checks for impossible states, speculative options, redundant tests — without changing behaviour. Use when the user says 'deslop', 'clean this up', 'simplify what you wrote', 'this is overbuilt', or asks for a tidy-up pass after a feature or fix is done."
---

# Deslop

Go back over the change you just made and remove what doesn't earn its place.
The goal is code a careful human would have written: direct, and no bigger than
the problem.

## Scope

- Work only on the current change: the uncommitted diff plus the branch's
  commits against its base (`git diff $(git merge-base HEAD origin/main)`).
  Touch surrounding code only where the simplification needs it.
- Read each changed file in full before editing, along with its callers and
  tests. You can't tell what's removable from a diff hunk alone.
- Behaviour stays the same. This is not the moment for fixes or features; note
  any you spot and leave them.

## What to look for

- **Comments** that restate the code, narrate steps, or describe the change
  ("now uses X instead of Y"). Keep ones that explain a constraint or a
  non-obvious why.
- **Indirection**: helpers, wrappers, and interfaces with one caller and no
  real job. Inline them.
- **Defensive code inside trusted boundaries**: null checks the types rule out,
  `try`/`catch` that only logs and rethrows, fallbacks for states that can't
  happen. Validate at the edges — user input, the network, files — and trust
  the invariants inside.
- **Speculative flexibility**: options, flags, parameters, and extension points
  nothing uses yet.
- **Compatibility shims** for code that never shipped.
- **Duplication** the change introduced, when an existing helper already does
  the job.
- **Tangled state**: boolean flags and branches that a better data shape would
  remove.
- **Test bloat**: near-duplicate cases, assertions that only check a mock was
  called, tests of the language or framework rather than the change.
- **Noise**: leftover debug logging, unused imports and variables, over-long
  docstrings.

## Just do it, or ask first

**Just do it** when the change is clearly behaviour-preserving and local:
deleting a narrating comment, inlining a single-use helper, removing a branch
the types prove unreachable, collapsing duplication you added.

**Ask first** when removing something could be deliberate or is visible
outside the change. That covers public APIs, persisted or wire formats,
validation, auth, retries and error handling, anything with more than one
consumer, and anything whose purpose you can't pin down. Unused code isn't
automatically dead: check for exports, entry points, reflection, and config
references before calling it removable.

Gather every ask-first candidate into one numbered list before touching any of
them, then wait for the user to pick:

```
1. Drop the `retries` option on `fetchReport` — no caller sets it.
   Risk: external callers of the public client lose it.
2. Remove the empty-string fallback in `parseName` — the type is non-null.
   Risk: a JSON payload could still send `null`.
```

## Finish

1. Run the targeted tests and linters for the files you touched. Don't weaken a
   test to make a simplification pass.
2. Re-read the final diff for anything you've made harder to follow, or any
   behaviour you changed by accident.
3. Report briefly: what you removed, which ask-first items were skipped, and
   what you ran to verify it.
