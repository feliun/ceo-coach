---
name: delegation-tracker
description: >
  Track delegation patterns over time in a YAML log. Fuzzy-match recurring items,
  increment streaks, escalate at configurable thresholds. Interactive — asks the
  user what they should have delegated.
---

# Skill: Delegation Tracker

Purpose:
Maintain a running log of tasks the user did but should have delegated. Track recurring patterns and escalate when something becomes a habit (configurable streak threshold, default: 3).

When to use:
- **Ad-hoc, on request only.** `/review` no longer calls this skill, so the delegation prompt is no longer part of the weekly loop — the log only advances when the user asks: "let's do a delegation check".
- If the user wants the streak counters to keep meaning something, they need to run this on a deliberate cadence. Say so plainly if the log has gone stale.

---

## Dependencies

- `config/delegation-log.yaml` (resolved via manifest) — the running log

---

## Process

### 1. Ask the user

Ask: **"What did you do this period that you should have delegated?"**

Wait for the answer. If the user says "nothing," log it and skip.

### 2. Process each item

For each item the user mentions:

1. Fuzzy-match against existing `recurring` entries in `delegation-log.yaml` (same activity even if worded differently)
2. **Match found:** append the current date to `weeks_logged`. If the previous entry is within one period, increment `streak`. Otherwise reset `streak` to 1.
3. **No match:** add a new entry with `streak: 1`

### 3. Escalate streaks

If any item's streak reaches the threshold (default: 3):

Ask: *"This is the Nth time in a row you did [item]. Who should own this, and when can you hand it off?"*

Once answered, move the item from `recurring` to `delegated` with `delegated_to`, `handoff_date`, and `escalated_from_streak`.

### 4. Update the log

Write the updated `delegation-log.yaml`.

---

## Log Format

```yaml
recurring:
  - item: "Reviewed all inbound partnership emails"
    first_seen: 2026-03-06
    weeks_logged:
      - 2026-03-06
      - 2026-03-13
    streak: 2

delegated:
  - item: "Wrote social media copy for launches"
    delegated_to: "Maria"
    handoff_date: 2026-03-20
    escalated_from_streak: 3
```

---

## Output

A markdown section for embedding in the review:

```markdown
## Delegation Review

**Items logged this period:**
- {item} (streak: N)
- ...

**Formal delegations triggered:**
- {item} → {person} (handoff: {date})

**No items identified.** *(if user had nothing to report)*
```

---

## Anti-patterns

- Do NOT skip the interactive question — the self-reflection is the point
- Do NOT auto-populate items without asking — the user must identify them
- Do NOT lose existing log entries when updating
