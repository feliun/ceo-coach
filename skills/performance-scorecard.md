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
- Weekly plan(s) for the window — planned tasks, exit criteria, hat distribution targets
- Quarterly plan for the current month — rock targets, key activities, exit criteria

---

## Input

| Parameter | Description |
|-----------|-------------|
| `--window` | Time window to analyze (e.g., `7d`, `14d`, `30d`) |
| data | Calendar events, emails, tasks completed/overdue, meeting notes, daily logs for the window |
| weekly_plans | Weekly plan(s) covering the window — exit criteria, task assignments, hat targets |
| quarterly_plan | Current month section from quarterly plan — rock targets, key activities, exit criteria |

---

## Process

### 1. Constraint Diagnosis

- Based on where time was actually spent in the window, what appears to be the current #1 constraint?
- Is the user actually working on it, or working around it?
- Is there a risk to the business that should take priority?

### 2. Hat Distribution

Estimate time allocation across the hats defined in `references/leadership-framework.md` based on calendar, tasks, and meetings:

```
Learner:   ██░░░░░░░░ X% (target: always on)  [planned: X%]
Architect: ██░░░░░░░░ X% (target: ~25%)        [planned: X%]
Coach:     ██░░░░░░░░ X% (target: ~25%)        [planned: X%]
Engineer:  ██░░░░░░░░ X% (target: ~25%)        [planned: X%]
Player:    ██░░░░░░░░ X% (target: ≤25%)        [planned: X%]
```

Compare actual distribution against both the leadership framework targets AND the weekly plan's hat distribution target (if available). Flag deviations from the plan specifically — the plan represents the user's intentional allocation for the week, so drift from plan is more actionable than drift from abstract targets.

Be specific about which activities drove the distribution.

### 3. Delegation Audit

- What was done in the window that someone else could have done at 70%?
- Where was Player mode entered unnecessarily?
- Was coaching focused on outcomes or micromanaging methods?

### 4. Strategic vs. Tactical Split

- How much time was spent on 12+ month horizon work (strategic) vs. <12 month (tactical)?
- Is the balance appropriate for the current stage?

### 5. Plan Execution

Score how well the user executed against their own plans. This is the highest-signal dimension — it measures self-accountability.

**Weekly plan compliance:**
- Exit criteria hit rate: {N of M met} → percentage
- Were planned tasks completed in the blocks they were assigned to, or did they drift?
- Were calendar violation resolutions actually applied?
- Did deferred tasks get addressed or carried forward silently?

**Monthly target progress (from quarterly plan):**
- For each rock targeted this month: is the KR on track to hit the exit value?
- Key activities: how many were completed vs. planned?
- Are month exit criteria on track, at risk, or already missed?

If no weekly plan existed: score 0/10 for this dimension. Operating without a plan means there's no baseline to measure against — that itself is the problem.

If no quarterly plan existed: note that monthly scoring is unavailable but still score weekly plan compliance if plans exist.

### 6. Hard Questions

Answer honestly based on evidence:
- *"Was every hour this period spent at the point of constraint?"*
- *"What was waste?"*
- *"Am I building moats or just running faster?"*
- *"Are ideas and energy bubbling up from the team, or am I the only source?"*
- *"Who on the team would I NOT rehire today?"* (flag if this recurs)
- *"Did I do what I said I would do?"* (from plan exit criteria — the most direct accountability question)

### 7. CEO Score

| Dimension | Score | Evidence |
|-----------|-------|----------|
| Focus on constraint | /10 | |
| Time at CEO-level work | /10 | |
| Plan execution | /10 | {exit criteria hit rate, monthly target progress} |
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
