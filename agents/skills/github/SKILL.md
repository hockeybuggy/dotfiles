---
name: github
description: "Interact with GitHub using the `gh` CLI. Use `gh issue`, `gh pr`, `gh run`, and `gh api` for issues, PRs, CI runs, PR review comments, and advanced queries."
---

# GitHub Skill

Use the `gh` CLI to interact with GitHub. Always specify `--repo owner/repo` when not in a git directory, or use URLs directly.

## Pull Requests

Check CI status on a PR:
```bash
gh pr checks 55 --repo owner/repo
```

List recent workflow runs:
```bash
gh run list --repo owner/repo --limit 10
```

View a run and see which steps failed:
```bash
gh run view <run-id> --repo owner/repo
```

View logs for failed steps only:
```bash
gh run view <run-id> --repo owner/repo --log-failed
```

## Commenting on a PR

**Default to inline comments anchored to a line of the diff.** A top-level
comment (`gh pr comment`, or `gh pr review --comment -b ...`) is never marked
outdated, so it sits on the PR forever even after the code it referred to is
gone. An inline comment is attached to a commit and a line, so GitHub collapses
it as outdated once that line changes — the conversation cleans itself up.

Reserve top-level comments for things that genuinely have no single home:
a summary of a multi-file review, a question about the overall approach, or a
status update. If a remark can point at a line, point it at a line.

### Mark agent-written comments as such

Every comment you post to a PR — inline, review body, or top-level — ends with
an attribution footer on its own line, separated by a blank line:

```
(:robot: written with <model name>)
```

Use your own model's name, e.g. `(:robot: written with Claude Opus 5)`. A human
reading the thread should never have to guess whether they're replying to a
person. Do not omit it to keep a one-line comment short, and do not substitute a
vaguer wording — the footer is the same every time so it's easy to scan for and
easy to filter out.

Inline comments are where the footer goes missing: each `comments[].body` in a
review payload needs its **own** footer, and the review's top-level `body`
doesn't cover them. The same goes for comments posted by any other route — a
review command's `--comment` mode, an MCP tool, a reply to a thread. Check every
payload before sending it (see the check below).

Post a review with all its inline comments in a single call. **Build the payload
as a JSON file and pass `--input`** — do not try to assemble the comment list
out of `-f`/`-F` field flags (see the warning below):

```bash
cat > "$TMPDIR/review.json" <<'JSON'
{
  "commit_id": "COMMIT_SHA",
  "event": "COMMENT",
  "comments": [
    {
      "path": "lib/parser.rb",
      "line": 42,
      "side": "RIGHT",
      "body": "This drops the nil case — `value` can be nil here.\n\n(:robot: written with Claude Opus 5)"
    },
    {
      "path": "lib/parser.rb",
      "start_line": 51,
      "line": 58,
      "side": "RIGHT",
      "body": "This loop re-reads the file on every pass.\n\n(:robot: written with Claude Opus 5)"
    }
  ]
}
JSON

gh pr view 55 --repo owner/repo --json headRefOid --jq .headRefOid  # fill in COMMIT_SHA

jq -e '[.body, .comments[]?.body]
  | map(select(. != null and . != ""))
  | all(test("\n\n\\(:robot: written with [^)]+\\)$"))' "$TMPDIR/review.json" \
  && gh api repos/owner/repo/pulls/55/reviews --method POST --input "$TMPDIR/review.json"
```

Always gate the POST on that `jq -e` check. If it prints `false`, add the footer
to each comment that's missing it and run the check again. Don't post first and
fix afterwards.

Omit `body` (or leave it `""`) when the review has no overall summary — the
inline comments already carry their own footer.

Useful fields:

- `line` — the line number **in the file as of the head commit**, not a diff
  offset. Must be a JSON number, not a string.
- `side` — `RIGHT` for added/unchanged lines, `LEFT` for removed ones.
- `start_line` plus `line` to span a range.
- `subject_type: "file"` instead of `line` to comment on a whole file.

> **Don't use `comments[][key]=value` field flags for this.** gh's
> array-of-objects syntax has no delimiter between objects — it opens a new one
> whenever a key repeats, so a second comment's fields get smeared across
> objects. These flags:
>
> ```
> -f 'comments[][path]=a.rb' -F 'comments[][line]=42'
> -f 'comments[][path]=b.rb' -F 'comments[][line]=99'
> ```
>
> produce `[{"path":"a.rb"}, {"line":42,"path":"b.rb"}, {"line":99}]`, which the
> API rejects. It looks like it works for exactly one comment, then breaks
> silently. Note also that `-f`/`--raw-field` always sends strings, so
> `line` would arrive as `"42"` and be rejected even in the single-comment case.

A comment on a line that isn't part of the diff is rejected. If that happens,
move the comment to the nearest changed line and say which line you actually
mean, rather than falling back to a top-level comment.

When continuing a discussion on a review you're conducting, reply within the
existing inline thread rather than starting a new top-level one:

```bash
gh api repos/owner/repo/pulls/55/comments/<comment-id>/replies \
  --method POST --field body="Fixed in the latest push.

(:robot: written with Claude Opus 5)"
```

## Returning URLs to the user

When you hand back a PR or any URL the user will click, print it as a **bare
plain-text URL on its own line** — not a Markdown link. A bare URL is
unambiguous and reliably clickable in a terminal; `[text](url)` is not.

```
https://github.com/owner/repo/pull/55
```

## API for Advanced Queries

The `gh api` command is useful for accessing data not available through other subcommands.

Get PR with specific fields:
```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
```

## JSON Output

Most commands support `--json` for structured output.  You can use `--jq` to filter:

```bash
gh issue list --repo owner/repo --json number,title --jq '.[] | "\(.number): \(.title)"'
```
