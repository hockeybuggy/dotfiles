---
name: create-linear-issue
description: "Create a Linear issue with consistent structure, inheriting context from related issues when possible"
---

Create a Linear issue from the current conversation. Triggers on
"create a Linear issue", "file a ticket", "open a Linear issue",
"make a Linear issue for X".

## Load the tools first

The Linear MCP tools are deferred and must be loaded before they can
be called. Run:

```
ToolSearch query="select:mcp__claude_ai_Linear__save_issue,mcp__claude_ai_Linear__get_issue"
```

Calling either tool without loading its schema first will fail with
`InputValidationError`.

## String values

The Linear MCP server requires real newlines in markdown content, not
literal `\n` escape sequences. Pass description strings with actual
line breaks.

## Inherit context from a related issue

If the new issue is a follow-up, cleanup, child, or otherwise tied to
an existing issue, call `mcp__claude_ai_Linear__get_issue` on that
issue first and reuse:

- `team` ID
- `project` ID
- `projectMilestone` ID (if set)
- Labels, if they obviously apply

Don't ask the user for fields you can pull from the related issue.

When the user references issues for `parent`, `blocks`, or `related`,
use the Linear identifier format (e.g. `DRWFA-1234`), not the internal
UUID.

## Required fields

- `title`
- `team` (UUID)

Everything else is optional. Set what you can infer; ask about the
rest only when it matters.

## Clarifying questions

Use `AskUserQuestion` for fields that can't be inferred and are likely
to matter. Typical asks:

- Assignee: me (Douglas) / unassigned / someone else
- Priority: Urgent / High / Medium / Low / none
- Due date
- Labels

Skip the question when context makes the answer obvious. Don't ask
about the team or project if you inherited them.

## Description style

- Concrete file paths, function names, PR numbers, and issue IDs.
- Structured sections with `##` headings (e.g. `## What to remove`,
  `## What to keep`, `## When`, `## Context`).
- Reference the originating PR or conversation under a `## Context`
  section so the reader can find the source of truth.
- No generic boilerplate, no marketing language, no emojis.
- Use `@displayName` to mention people.

## Steps

1. Identify whether the issue relates to an existing one. If so,
   `get_issue` on the related issue and capture team / project /
   milestone IDs.
2. Draft a title (short, imperative, specific) and a structured
   description with concrete identifiers.
3. Ask only the clarifying questions you actually need
   (assignee, priority, due date, labels).
4. Show the user the proposed title, description, and metadata, and
   wait for approval before creating. If the user explicitly opts out
   ("just create it"), skip the prompt.
5. Call `mcp__claude_ai_Linear__save_issue` with the collected fields.
6. Return the issue URL and a one-line summary:
   `DRWFA-1234 — <title> (assignee: X, priority: Y, due: Z)`.
