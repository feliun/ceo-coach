---
name: refocus-directive
description: >
  Synthesize the next-period focus from performance scorecard and calendar audit.
  Produces: #1 constraint, hat to wear, stop/start actions, calendar fix, role reminder.
---

# Skill: Refocus Directive

Purpose:
Produce a crisp, actionable directive for the next period based on the performance scorecard and calendar audit findings. This is the "so what" synthesis.

When to use:
- Called by the `review` command as the final component
- Always runs after performance-scorecard and calendar-audit

---

## Input

- Performance scorecard output (constraint diagnosis, hat distribution, scores)
- Calendar audit output (compliance scorecard, violations)

---

## Output

```markdown
## Refocus Directive

- **#1 constraint for next period:** {based on evidence, not assumption}
- **Hat to wear most:** {which hat and why}
- **STOP:** {one specific thing from this period's activities}
- **START:** {one specific, actionable thing}
- **Calendar fix:** {specific: which meeting to move/decline/delegate, based on audit failures}
- **Role reminder:** {sharp, 2-sentence statement of what the user's job actually is right now}
```

---

## Tone

Direct, challenging, no flattery. Think trusted board advisor, not cheerful assistant.

---

## Anti-patterns

- Do NOT produce generic advice ("focus more on strategy") — be specific to the data
- Do NOT list more than one STOP and one START — force prioritization
- Do NOT skip the calendar fix — it must reference a specific audit failure
