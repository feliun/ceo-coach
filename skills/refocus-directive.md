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
- **Ad-hoc, on request only.** `/review` no longer calls this skill — its closing Overview synthesizes what happened, it does not prescribe what to do next. Invoke this when the user wants a directive.
- Still requires `performance-scorecard` and `calendar-audit` to have run first — it synthesizes their output and has nothing to work from otherwise. Run those two ad-hoc as well before this one.

---

## Input

- Performance scorecard output (constraint diagnosis, hat distribution, plan execution, scores)
- Calendar audit output (compliance scorecard, violations)
- Plan-vs-actual data (unmet exit criteria, monthly target gaps)

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
