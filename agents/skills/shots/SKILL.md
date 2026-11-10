---
name: shots
description: "Capture before/after screenshots of a web UI change and embed them in a pull request description. Use when asked for before/after shots, UI screenshots for a PR, or visual evidence of a frontend change. Triggers on 'take before/after screenshots', 'add shots to the PR', 'show the visual diff'."
---

# Shots

Capture matched before/after screenshots of a web UI change, collect them
in one flat directory, then upload them into the PR description with
`gh pr edit --attach`.

## Steps

1. Work out how to reach the changed UI in a browser: the dev server or
   preview command, the URL or route, and any state needed to make the
   change visible (logged-in user, fixture, query param, feature flag).
   Ask the user if any of that is ambiguous — a screenshot of the wrong
   screen is worse than none.
2. Pick a fixed viewport (default 1440x900) and reuse it for every shot
   in the run.
3. Capture the **before**: stash or check out the pre-change state, load
   the page, screenshot it.
4. Capture the **after**: restore the change, reload the *same* URL in the
   *same* state, screenshot again. Confirm the working tree is back to
   where it started before moving on.
5. Repeat for each distinct view the change affects (states, breakpoints,
   themes). Every view needs both a before and an after.

## Capture rules

- Same URL, same viewport, same data, same scroll position for a pair.
  Anything else makes the pair unreadable as a diff.
- Capture the full affected region for every view — the full page or
  the full component. When the change is a small detail, also capture
  a cropped close-up pair of it.
- Let the page settle before capturing: fonts loaded, animations done,
  spinners gone.

## Where the files go

All screenshots go in a single **flat** directory — no per-view
subdirectories. Default to a temp directory outside the repo (e.g.
`$TMPDIR/shots/`) so nothing is accidentally committed; use a
repo-relative path only if the user asks for one.

Name files `<view>-before.png` / `<view>-after.png` so pairs sort next
to each other, and close-ups `<view>-closeup-before.png` /
`<view>-closeup-after.png`.

## Updating the PR

Write the new PR body to a file: the existing body (`gh pr view --json
body -q .body`) plus a labelled table that references each screenshot by
its absolute local path. Use Markdown image syntax — `gh` only rewrites
`![alt](path)` references, not `<img>` tags.

```markdown
| View | Before | After |
| --- | --- | --- |
| Login | ![Login before](/abs/path/login-before.png) | ![Login after](/abs/path/login-after.png) |
```

Then pass the body and every referenced file in one command. `gh`
uploads each attachment and swaps its local path for the uploaded URL:

```zsh
gh pr edit <number> --body-file "$TMPDIR/shots/body.md" \
  --attach "$TMPDIR/shots/login-before.png" \
  --attach "$TMPDIR/shots/login-after.png"
```

- One row per view or close-up.
- Attach exactly the files the table references; unreferenced
  attachments get appended to the end of the body.
- Append the table under a `## Screenshots` heading, or into the
  testing section if the repo's PR template has one, unless the user
  says otherwise.
- If some uploads fail, `gh` still updates the PR with the rest and
  exits non-zero. Check the exit status, then re-read the body with
  `gh pr view` to confirm the table renders and no local paths remain.

## Fallback: manual upload

`--attach` needs `gh` 2.101 or newer and push access to the repository,
so it fails on PRs from forks. In that case, give the user the full
absolute path of the screenshot directory and the list of files, ask
them to drag the files into the PR description editor and paste back
the resulting tags, then build the same table from those URLs. Do not
invent, guess, or reuse URLs.
