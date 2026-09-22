---
name: shots
description: "Capture before/after screenshots of a web UI change and embed them in a pull request description. Use when asked for before/after shots, UI screenshots for a PR, or visual evidence of a frontend change. Triggers on 'take before/after screenshots', 'add shots to the PR', 'show the visual diff'."
---

# Shots

Capture matched before/after screenshots of a web UI change, collect them
in one flat directory, then hand them to the user to upload to GitHub and
embed the returned `<img>` tags in the PR description.

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
- Screenshot the whole affected region — the full page or the full
  component. Never crop to a single row or detail unless asked.
- Let the page settle before capturing: fonts loaded, animations done,
  spinners gone.

## Where the files go

All screenshots go in a single **flat** directory — no per-view
subdirectories. Default to a temp directory outside the repo (e.g.
`$TMPDIR/shots/`) so nothing is accidentally committed; use a
repo-relative path only if the user asks for one.

Name files `<view>-before.png` / `<view>-after.png` so pairs sort next
to each other.

## Hand-off to the user

GitHub image uploads require a browser session, so the user does this
part. Tell them:

1. The full absolute path of the directory holding the screenshots
   (expand `$TMPDIR`), and the list of files.
2. To open the PR description editor and drag the whole directory's
   contents into the comment box.
3. To paste back the resulting markdown/`<img>` tags, in any order —
   filenames in the URLs are enough to match them up.

Wait for the user's paste. Do not invent, guess, or reuse URLs.

## Updating the PR

Once the user returns the tags, build a two-column markdown table and
update the PR description with `gh pr edit --body-file`:

```markdown
| Before | After |
| --- | --- |
| <img src="..." width="400"> | <img src="..." width="400"> |
```

- One row per view, with a preceding heading or a leading label column
  when there is more than one view.
- Keep the existing PR body and append the table under a `## Screenshots`
  heading, unless the user says otherwise.
- Re-read the rendered body (`gh pr view --web` or `gh pr view`) to
  confirm the table renders as a table and every image resolves.
