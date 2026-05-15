## Output Formatting

When providing research, plans, comparisons, or tables, output as
raw markdown inside a code fence so it's copyable. Do not render
markdown directly.

## Git Conventions

Write commits like my existing style. Imperative mood, capitalize
the first word, keep the subject under 50 characters. No trailing
period. No conventional commits prefixes.

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

## Pull request bodies

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
