---
name: report
description: "Produce a self-contained, styled HTML report answering a question about the codebase. Use when the user asks for a report, a written summary, or a shareable write-up of how part of the codebase works. Triggers on 'write a report', 'make me a report', 'generate an HTML report'. Researches the codebase (delegating to a subagent for broad topics), then writes a single styled HTML file that links back to the source with GitHub permalinks."
---

# Report

Research a topic in the codebase and produce a self-contained, styled
HTML report.

## Steps

1. Research the codebase for the requested topic. If the topic is broad,
   dispatch a subagent to gather the relevant files and context rather
   than reading everything inline.
2. Confirm the output file path with the user before writing.
3. Produce a self-contained, styled HTML file. Inline all CSS so the
   file opens standalone with no external dependencies.
4. Include GitHub permalinks for every code reference so readers can jump
   to the exact lines on GitHub.

## Building GitHub permalinks

A permalink pins the reference to a specific commit so it doesn't drift.
Resolve the pieces first:

- Remote: `git remote get-url origin`
- Commit: `git rev-parse HEAD`

Then link to `<repo-url>/blob/<sha>/<path>#L<start>-L<end>`, for example
`https://github.com/owner/repo/blob/<sha>/src/app.ts#L10-L24`.
