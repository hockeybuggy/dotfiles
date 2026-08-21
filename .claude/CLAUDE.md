## Output Formatting

When providing research, plans, comparisons, or tables, output as
raw markdown inside a code fence so it's copyable. Do not render
markdown directly.

## Local Files
- Do not create Claude artifacts unless explicitly requested. Write documents, reports, plans, and other deliverables to a local file instead, then provide its path.

## Links
- Prefer providing direct links to referenced resources when available, including files, documentation, commits, issues, pull requests, and web pages.
- For local resources, provide an openable file path or link. Keep links alongside a brief description so the user does not need to search for the referenced resource.
- Never refer to a GitHub PR, issue, commit, or repo by shorthand alone (`repo#123`, `#123`, a bare SHA). Always give the full `https://github.com/...` URL, optionally with the shorthand as the link text: `[repo#123](https://github.com/owner/repo/pull/123)`. The exception is text that GitHub itself renders — see "Pull request bodies".

## Git Conventions

Use this as my default commit style. Check for repository-specific
commit guidance and respect it where present. Choose a suitable commit
message without asking for approval by default. Ask only when the scope
or message is genuinely ambiguous, or when the user explicitly asks to
review it first.

Imperative mood, capitalize the first word, keep the subject under 50
characters. No trailing period. No conventional commits prefixes.

Good verbs: Fix, Add, Change, Improve, Remove

Use backticks around commands, file names, and aliases in subjects:

    Fix the quoting of the `clip` command

Include a body (~72 char wrap) for non-trivial changes. Commit
message bodies should have at least two paragraphs: a problem
paragraph describing the prior state, then one or more solution
paragraphs explaining how this change addresses it. Complex changes
often need multiple solution paragraphs. Optionally add a final
"alternatives considered" paragraph when the chosen approach isn't
obvious. Bullet points are fine when they genuinely fit. Skip the
body when the subject says it all.

Keep commit messages high-level and summary-focused, not exhaustive
detail dumps. The body explains intent, not a changelog of every edit.

Reference GitHub PRs and issues by full URL in commit messages. Most
commit messages get read in a terminal, where `#123` autolinks to
nothing.

## Pull request bodies

Shorthand references like `#123` and bare SHAs are fine here — GitHub
autolinks them when it renders the description.

For single-commit PRs, reuse the commit message: the commit subject
becomes the PR title and the commit body becomes the PR body. Don't
write a separate PR description that says the same thing differently.

Do not hard-wrap PR descriptions. Reflow each paragraph onto a single
line and let Markdown handle wrapping — GitHub renders hard line
breaks as paragraph-internal line breaks, which looks bad. Hard
wrapping at ~72 is only for commit message bodies. When reusing a
commit message as a PR description, strip the hard line breaks within
each paragraph but keep blank lines between paragraphs.

## General

Be concise. Don't over-explain or add ceremony. Focus on getting
things done over getting things perfect.

## Pull request reviews

Don't reply to PR review comments. When asked to address feedback,
make the code changes and push them — let the diff speak. I'll write
the replies myself.

## Verification & Testing
- Do NOT run the full test suite or docker test stack before committing unless explicitly asked. Run the targeted tests for files you changed, then commit/push. If you believe a broader run is needed, ask first.

## Shell commands

Always use `python3`, never the bare `python` command — it isn't
guaranteed to exist or point at Python 3.
