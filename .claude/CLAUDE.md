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

Include a body (~72 char wrap) for non-trivial changes. The body
should answer: what was the state before, how does this address it,
and are there side effects. Skip the body when the subject says it all.

Keep commit messages high-level and summary-focused, not exhaustive
detail dumps. Aim for a clear subject and a few bullets of intent,
not a changelog of every edit.

## General

Be concise. Don't over-explain or add ceremony. Focus on getting
things done over getting things perfect.

## Pull request reviews

Don't reply to PR review comments. When asked to address feedback,
make the code changes and push them — let the diff speak. I'll write
the replies myself.
