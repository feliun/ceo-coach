---
name: ceo-coach:review
description: >
  Performance review for a configurable time window. Orchestrates data gathering,
  performance scorecard, calendar audit, delegation tracking, and refocus directive.
  Period-agnostic — the user decides when to run it.
---

## Command: ceo-coach:review

The core command. Produces a comprehensive performance review by orchestrating all ceo-coach skills.

---

### Input

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--window` | `7d` | Time window to review (e.g., `7d`, `14d`, `30d`) |

---

### Execution Steps

#### 1. Manifest resolution

Invoke `manifest-resolver` for domain `ceo-coach`.
Resolve: `rocks` (required), `calendar-rules`, `delegation-log`, `leadership-framework`, `quarterly-plan`.

#### 2. Load references

Read:
- `references/leadership-framework.md` — hat model, time targets, constraint theory
- `references/values.md` — objectives hierarchy

#### 3. Gather behavioral data

Dispatch the `performance-analyst` agent (see `agents/performance-analyst.md`) with the resolved `rocks` path and `quarterly-plan` folder. The agent fetches:
- Calendar events for the window
- Emails sent and received in the window
- Tasks completed and overdue in the window
- Meeting notes from the window
- Daily logs from the window
- Weekly plan(s) covering the window (from `logs/weekly/plan-*.md`)
- Quarterly plan for the current month (monthly targets, exit criteria, key activities)
- Fleeting thoughts from the window

#### 4. Run performance scorecard

Invoke `skills/performance-scorecard.md` with the gathered data, the `--window` parameter, and the plan data (weekly plans + quarterly plan). The scorecard uses these as baselines: actual performance is measured against what was planned, not just against abstract targets.

#### 5. Run calendar audit

Invoke `skills/calendar-audit.md` with calendar data and resolved calendar rules.

#### 6. Run delegation tracker

Invoke `skills/delegation-tracker.md`. This is interactive — it asks the user what they should have delegated.

#### 7. Generate refocus directive

Invoke `skills/refocus-directive.md` with scorecard and audit output.

#### 8. Assemble and save

Save the review to: `logs/weekly/DD-MM-YYYY.md` (using the end date of the window).
This is the same directory as weekly plans — reviews and plans live together as the
weekly accountability loop.

Combine all outputs into a single review document:

```markdown
---
type: reflection
created: {DD-MM-YYYY}
tags: [review, performance, log]
---

# Performance Review — {DD-MM-YYYY}

Window: {window parameter} ({start date} → {end date})

## Performance Scorecard
{from performance-scorecard skill}

## Calendar Audit
{from calendar-audit skill}

## Delegation Review
{from delegation-tracker skill}

## Plan vs. Actual
{Compare what was planned against what actually happened. This section is the
accountability core of the review — it makes drift visible.}

### Weekly Plan Compliance
{For each weekly plan in the window:}
- **Week of {date}:** {N of M} exit criteria met
- Unmet criteria: {list with brief explanation of what blocked each}
- Planned hat distribution vs. actual: {side-by-side comparison}
- Calendar violations at plan time: {were the proposed resolutions applied?}

### Monthly Target Progress
{From the quarterly plan's current month section:}
- Rock targets for this month: {each rock with target KR value vs. current value}
- Key activities status: {done / in progress / not started / blocked}
- Month exit criteria: {on track / at risk / missed — with evidence}

{If no weekly plan exists: "No weekly plan found for this period. Operating
without a plan makes performance measurement unreliable — recommend running
/plan before each week."}

{If no quarterly plan exists: "No quarterly plan found. Monthly targets
unavailable — scoring against rock weights only."}

## Fleeting Thoughts
{from performance-analyst fleeting thoughts data — list all journaling entries,
free thinking entries, and company notes from the window. Group by date.
Include the full content of each entry. If none found, note "No fleeting thoughts
captured this period." and flag as a reflection gap.}

## Refocus Directive
{from refocus-directive skill}
```

#### 9. Report

```
REVIEW COMPLETE — {DD-MM-YYYY}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Window:     {window}
CEO Score:  {X}/10
Compliance: {X}/10
Delegation: {N items logged, M escalated}
File:       {path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Resilience

- If performance-analyst fails: attempt inline data gathering, note with ⚠️
- If calendar-rules config is missing: skip calendar audit with ⚠️
- If delegation-log is missing: create a new one
- Never produce a review without the performance scorecard — that's the core
