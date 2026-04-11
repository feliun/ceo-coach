---
name: performance-scorecard
description: >
  Score CEO performance across 6 dimensions using behavioral data.
  Period-agnostic — accepts a time window. Produces constraint diagnosis,
  hat distribution, delegation audit, strategic split, hard questions, and score.
---

# Skill: Performance Scorecard

Purpose:
Produce an evidence-based CEO performance score for a given time window. Every finding must cite specific data — calendar events, emails, tasks, meeting notes.

When to use:
- Called by the `review` command as a core component
- Standalone: "score my performance for the last 2 weeks"

---

## Dependencies

- `references/leadership-framework.md` — hat definitions, time targets, constraint theory
- `references/values.md` — objectives hierarchy for goal alignment
- Behavioral data from `performance-analyst` agent or equivalent

---

## Input

| Parameter | Description |
|-----------|-------------|
| `--window` | Time window to analyze (e.g., `7d`, `14d`, `30d`) |
| data | Calendar events, emails, tasks completed/overdue, meeting notes, daily logs for the window |

---

## Process

### 1. Constraint Diagnosis

- Based on where time was actually spent in the window, what appears to be the current #1 constraint?
- Is the user actually working on it, or working around it?
- Is there a risk to the business that should take priority?

### 2. Hat Distribution

Estimate time allocation across the hats defined in `references/leadership-framework.md` based on calendar, tasks, and meetings:

```
Learner:   ██░░░░░░░░ X% (target: always on)
Architect: ██░░░░░░░░ X% (target: ~25%)
Coach:     ██░░░░░░░░ X% (target: ~25%)
Engineer:  ██░░░░░░░░ X% (target: ~25%)
Player:    ██░░░░░░░░ X% (target: ≤25%)
```

Flag any hat significantly over or under target. Be specific about which activities drove the distribution.

### 3. Delegation Audit

- What was done in the window that someone else could have done at 70%?
- Where was Player mode entered unnecessarily?
- Was coaching focused on outcomes or micromanaging methods?

### 4. Strategic vs. Tactical Split

- How much time was spent on 12+ month horizon work (strategic) vs. <12 month (tactical)?
- Is the balance appropriate for the current stage?

### 5. Hard Questions

Answer honestly based on evidence:
- *"Was every hour this period spent at the point of constraint?"*
- *"What was waste?"*
- *"Am I building moats or just running faster?"*
- *"Are ideas and energy bubbling up from the team, or am I the only source?"*
- *"Who on the team would I NOT rehire today?"* (flag if this recurs)

### 6. CEO Score

| Dimension | Score | Evidence |
|-----------|-------|----------|
| Focus on constraint | /10 | |
| Time at CEO-level work | /10 | |
| Delegation quality | /10 | |
| Strategic thinking time | /10 | |
| Talent development | /10 | |
| **Overall CEO Score** | **/10** | |

---

## Output

A markdown section with all 6 subsections above, suitable for embedding in the `review` command output.

---

## Anti-patterns

- Do NOT use generic praise or motivational language — be direct and evidence-based
- Do NOT fabricate data or scores — if evidence is insufficient, say so
- Do NOT skip data gathering before producing scores
