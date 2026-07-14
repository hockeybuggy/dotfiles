---
name: rebasing-prs
description: Rebases the current PR branch onto its base (usually `origin/main`), resolves conflicts with intent-aware decisions, and offers a safe force-push afterwards. Use when the user says "rebase", "rebase on main", "update branch with latest", "sync with main", "fix rebase conflicts", or when a PR is behind its base. Never rebase `main`/`master` itself; never plain `--force`-push.
---

# Rebasing PRs

**Announce:** "I'm using the rebasing-prs skill."

## Step 1: Pre-flight Checks

Refuse to proceed unless all of these hold:

```bash
# Current branch — must NOT be main/master/develop
git rev-parse --abbrev-ref HEAD

# Working tree must be clean (no uncommitted changes, no untracked files
# that would be clobbered). If dirty, ask the user whether to stash or stop.
git status --porcelain

# Confirm there is an upstream / a base to rebase onto
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no upstream"
```

If on `main`/`master`/`develop`, **stop** and tell the user. Do not rebase the trunk.

If the working tree is dirty, ask: stash and continue, or abort?

## Step 2: Identify the Base Branch

The base is the branch the PR will merge into — usually `main`, but check:

```bash
# If there's an open PR, ask GitHub for its base
gh pr view --json baseRefName -q .baseRefName 2>/dev/null

# Otherwise default to the repo's default branch
gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null \
  || echo "main"
```

Record the result as `BASE` (e.g. `main`). The remote ref to rebase onto is `origin/$BASE`.

## Step 3: Fetch and Understand What Changed

```bash
git fetch origin

# Commits on the base since this branch diverged — read these to understand
# the *intent* of upstream changes before resolving conflicts.
git log --oneline HEAD..origin/$BASE

# For files that are likely to conflict, look at *why* they changed upstream:
git log -p HEAD..origin/$BASE -- <path>
```

This is the key insight from how others do this well: resolving conflicts blind produces bad merges. Read upstream commit messages and diffs first so you can preserve the intent of both sides.

## Step 4: Rebase

```bash
git rebase origin/$BASE
```

If it completes cleanly, skip to Step 6.

## Step 5: Resolve Conflicts

For each conflicted file, decide which bucket it falls into:

| File type | Strategy |
|---|---|
| **Lock files** (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Gemfile.lock`, `poetry.lock`, `uv.lock`, `Cargo.lock`) | Accept theirs (`git checkout --theirs <file>`), then regenerate from the resolved manifest (`npm install`, `pnpm install`, `bundle install`, `poetry lock`, `cargo build`, etc.). |
| **DB migrations** (sequential numbering matters) | **Stop and ask the user.** Reordering migrations can break the database. |
| **Generated files** (snapshots, build artifacts) | Regenerate after resolving the source. |
| **Code** | Read both sides + the relevant upstream commit to understand intent. Preserve both changes when they're orthogonal. Pick one side only when they truly conflict on the same concern. |

After resolving each file:

```bash
git add <file>
git rebase --continue
```

If you get stuck or it's clear the resolution is non-trivial, stop and surface the conflict to the user with context (which file, what upstream did, what this branch did, your proposed resolution).

At any point, `git rebase --abort` returns to the pre-rebase state safely.

## Step 6: Verify

```bash
# Sanity check — branch should now be ahead of, not behind, base
git log --oneline origin/$BASE..HEAD
git log --oneline HEAD..origin/$BASE   # should be empty

# Run the project's tests / typecheck / lint as appropriate
```

If tests fail, the rebase semantically broke something even if it merged textually. Investigate before pushing.

## Step 7: Offer to Push (only if conflicts were trivial)

Classify the rebase as **trivial** if all of these hold:
- No conflicts, OR conflicts were only lock-file regenerations / pure-formatting / clearly-orthogonal hunks
- Tests still pass
- No migration / schema / generated-code conflicts
- You did not have to make a judgment call between two competing implementations

If trivial, ask the user:

> Rebase looks clean (or: only conflicts were `<lock-file>`, regenerated). Want me to push with `--force-with-lease`?

If they say yes:

```bash
git push --force-with-lease --force-if-includes
```

If **non-trivial** (real code conflicts, judgment calls, test changes, migrations): **do not offer to push.** Summarize what you did and let the user review the rebased branch first. They push when they're satisfied.

## Hard Rules

- Never `git push --force` (without `--with-lease`). Always `--force-with-lease`, ideally with `--force-if-includes`.
- Never rebase `main`/`master`/`develop`/release branches.
- Never `git rebase --skip` to make conflicts go away — that silently drops commits.
- Never run `git reset --hard` to "fix" a bad rebase mid-flight; use `git rebase --abort`.
- If the branch is shared with other contributors, warn the user before force-pushing — rebasing rewrites history they may have pulled.

## Checklist

- [ ] Not on `main`/`master`
- [ ] Working tree clean (or stashed with user's OK)
- [ ] Base branch identified, `origin/$BASE` fetched
- [ ] Read upstream commits before resolving conflicts
- [ ] Conflicts resolved with intent preserved; lock files regenerated
- [ ] Tests pass after rebase
- [ ] Trivial → asked user about `--force-with-lease` push; non-trivial → handed back for review
