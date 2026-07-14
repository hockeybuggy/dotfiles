---
name: commit
description: "Read this skill before making git commits"
---

Create a git commit for the current changes. Match the repo's existing
commit style — don't impose a format the repo doesn't already use.

## Determining the format

Run `git log -n 30 --pretty=format:%s` and look at recent subjects:

- If most subjects use Conventional Commits (`feat:`, `fix(scope):`,
  etc.), follow that convention.
- Otherwise, write a plain imperative subject (e.g., `Fix the quoting
  of the clip command`). Capitalize the first word, no trailing period.

Project `CLAUDE.md` or user instructions take precedence over what you
infer from history. If they specify a style, follow it.

## Subject

- Imperative mood, no trailing period.
- Keep it short. Match the repo's typical length; if unclear, aim for
  ~50 characters and stop at 72.
- Wrap file names, variables, commands, and code references in
  backticks.

## Body

Include a body when the subject doesn't say it all — typically for
non-trivial changes. The body should answer: what was the state
before, how does this change address it, and are there side effects.

Skip the body for trivial changes where the subject is self-explanatory
(typo fixes, renames, simple config tweaks).

When you do write a body:

- Wrap lines at ~72 characters.
- Separate paragraphs with a blank line.
- Use backticks around file names, variables, and code references.
- Optionally add a final paragraph on alternatives considered, when
  the chosen approach isn't obvious.

## Other notes

- Do NOT include breaking-change markers or footers.
- Do NOT add sign-offs (no `Signed-off-by`).
- Only commit; do NOT push.
- If it is unclear whether a file should be included, ask the user
  which files to commit.
- Treat any caller-provided arguments as additional commit guidance:
  - Freeform instructions should influence scope, summary, and body.
  - File paths or globs should limit which files to commit. If files
    are specified, only stage/commit those unless the user explicitly
    asks otherwise.
  - If arguments combine files and instructions, honor both.

## Steps

1. Infer from the prompt if the user provided specific file paths/globs
   and/or additional instructions.
2. Check the current branch. If on `main` or `master`, ask the user to
   confirm they really want to commit there. If they don't, ask for the
   branch name they'd like to use and switch (or create) that branch
   before continuing.
3. Review `git status` and `git diff` to understand the current changes
   (limit to argument-specified files if provided).
4. Run `git log -n 30 --pretty=format:%s` to determine the repo's
   commit style and commonly used scopes.
5. If there are ambiguous extra files, ask the user for clarification
   before committing.
6. Stage only the intended files (all changes if no files specified).
7. Show the user the proposed commit message (subject and body) and
   wait for approval before creating the commit. Apply any requested
   edits and re-confirm. Use `AskUserQuestion` for a structured
   approve/edit prompt when available, otherwise plain text. If the
   user explicitly opts out of review for the current task (e.g.
   "just commit", "no need to review"), skip the prompt.
8. Run `git commit -m "<subject>"` (and `-m "<body>"` if needed).
