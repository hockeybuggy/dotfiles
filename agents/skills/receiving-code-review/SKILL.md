---
name: receiving-code-review
description: Guides how to process and respond to code review feedback — categorizing comments, making changes systematically, and responding to reviewers. Use when a pull request or code has received review comments, or when the user says "I got feedback on my PR", "reviewer left comments", "how do I respond to this review", or "addressing review feedback". Never dismiss feedback without engaging with it; never make changes without understanding why.
---

# Receiving Code Review

**Announce:** "I'm using the receiving-code-review skill."

## Mindset

Code review is collaborative, not adversarial. The reviewer wants the code to be good. Even if a comment feels wrong, engage with the underlying concern before disagreeing.

## Step 1: Read Everything Before Responding

Read all comments before making any changes. You need the full picture to understand if comments are related, if there's a theme, or if early changes affect later ones.

## Step 2: Categorize Each Comment

| Category | Meaning | Action |
|---|---|---|
| **Must fix** | Correctness, security, data loss | Fix it, no debate |
| **Should fix** | Maintainability, convention, clarity | Fix it unless you have a strong reason |
| **Suggestion** | Style, preference, "consider..." | Discuss, then decide |
| **Question** | Reviewer wants to understand | Answer it in the PR or in code comments |
| **Praise** | 👍, "nice" | Acknowledge, move on |

## Step 3: Work Through Fixes Systematically

For each must-fix and should-fix:

1. Understand **why** the reviewer flagged it before writing the fix
2. Make the change
3. Run tests — don't assume a "small change" is safe
4. Commit changes (one logical commit per distinct concern, or squash at the end)

## Step 4: Respond to Each Comment

On every comment, leave a response:
- **Fixed:** "Done — changed X to Y"
- **Agreed with discussion:** "Good point, I've updated this. The key thing I missed was..."
- **Disagree (respectfully):** "I see the concern about X. My thinking was [reason]. Would [alternative] address it?"
- **Question answered:** Answer it in the reply; if the code was unclear, fix the code too

**Never:**
- Resolve a comment without explaining what you did
- Reply "fixed" without actually fixing it
- Ignore a comment silently

## Step 5: Re-Request Review

Once all comments are addressed:

```
Addressed all feedback. Summary of changes:
- [comment 1]: [what you did]
- [comment 2]: [what you did]
- [comment 3]: Left as-is because [reason] — let me know if you'd like to discuss

Ready for another look.
```

## Checklist

- [ ] All comments read before making changes
- [ ] Every must-fix and should-fix addressed
- [ ] Tests still passing after changes
- [ ] Every comment responded to (even if just "acknowledged")
- [ ] Review re-requested with summary
