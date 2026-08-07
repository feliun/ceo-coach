---
name: calendar-audit
description: >
  Audit calendar compliance against configured scheduling rules.
  Period-agnostic — accepts a time window. Produces a pass/fail scorecard.
---

# Skill: Calendar Audit

Purpose:
Run the calendar compliance checklist from configured rules against actual calendar data for a given period. Produces a pass/fail scorecard with evidence.

When to use:
- **Ad-hoc, on request only.** `/review` no longer calls this skill; it reports where the time went without checking it against rules. Invoke on request: "audit my calendar for this week".
- Note that `/plan` runs its own equivalent check inline (step 7) against the *upcoming* week rather than invoking this skill. This one looks backward.

---

## Dependencies

- `config/calendar-rules.yaml` or equivalent (resolved via manifest)
- `references/leadership-framework.md` — hat targets for the distribution check
- Calendar data for the window

---

## Input

| Parameter | Description |
|-----------|-------------|
| `--window` | Time window to audit (e.g., `7d`, `14d`, `30d`) |
| data | Calendar events for the window |
| rules | Calendar rules from config |

---

## Process

For each rule in the calendar rules config, check the actual calendar and report pass/fail with evidence. Common rules to check (configure in `calendar-rules.yaml`):

- Meeting-free days respected? (e.g., Monday, Friday)
- Morning rule respected? (e.g., no meetings before 14:00)
- Maximum meetings per day? (e.g., flag days with 4+)
- Total meeting hours within limit? (e.g., ≤6h/week)
- Protected blocks held? (e.g., Strategy Block, Deep Think)
- Content production blocks used?
- Personal/admin blocks respected?
- Delegated meetings not attended?
- Hat distribution targets met?

---

## Output

A scorecard table:

| Rule | Pass/Fail | Evidence |
|------|-----------|----------|
| Meeting-free Monday | ✅ / ❌ | {specific events if failed} |
| Morning rule | ✅ / ❌ | {violations listed} |
| Max 3 meetings/day | ✅ / ❌ | {days that exceeded} |
| ... | | |
| **Compliance score** | **X/10** | |

---

## Anti-patterns

- Do NOT invent calendar rules not present in the config — only audit configured rules
- Do NOT count all-day events or self-blocks as "meetings" unless the config says to
- Do NOT skip checking any configured rule
