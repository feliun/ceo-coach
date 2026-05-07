---
name: ceo-coach:plan
description: >
  Generate a weekly execution plan. Cross-references quarterly objectives, calendar
  availability, Asana tasks, and calendar rules to produce a day-by-day schedule
  with task assignments mapped to protected blocks and hat targets.
---

## Command: ceo-coach:plan

Produce a concrete weekly plan: what to work on, when, and why — grounded in quarterly objectives, actual calendar availability, and scheduling rules. The plan assigns tasks to the protected blocks defined in calendar rules, flags violations in the upcoming week, and ensures time allocation aligns with rock weights and hat targets.

---

### Input

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--week` | upcoming Monday | ISO date (YYYY-MM-DD) of the Monday to plan. Defaults to the next Monday from today. If today is Monday, plans the current week. |
| `--projects` | `Engineer,Deep Thinking,Strategy,Business` | Comma-separated Asana project names to pull tasks from, in addition to due-date search. **These are example defaults from the maintainer's setup — replace with your own Asana project names** (typical categories: deep-work focus, strategic initiatives, business operations). |

---

### Execution Steps

#### 1. Manifest resolution

Invoke `manifest-resolver` for domain `ceo-coach`.
Resolve:
- `rocks` (required) — quarterly objectives, KR progress, weights, status
- `calendar-rules` (required for this command) — day themes, protected blocks, meeting limits, delegation defaults
- `leadership-framework` — hat model and time targets

#### 2. Load rocks and resolve quarterly plan

Read the resolved `rocks.yaml`. Extract the `quarter` field (e.g., `Q2-2026`).

Locate the quarterly execution plan at `$WORKSPACE/logs/quarterly/{quarter-lowercase}.md` (e.g., `logs/quarterly/q2-2026.md`). This file contains monthly targets, exit criteria, key activities, and the dependency map.

If the quarterly plan file does not exist: note with ⚠️ and proceed using rocks.yaml alone. The plan will lack monthly targets and exit criteria but can still produce a schedule.

#### 3. Load calendar rules

Read the resolved calendar rules file. Extract:

- **Day themes:** which hat each day belongs to (e.g., Monday = Strategy/Architect)
- **Protected blocks:** name, day, time range, purpose (e.g., Strategy Block Mon 11:00-14:00)
- **Non-negotiable rules:** meeting-free days, morning rule, max meetings/day, max hours/week, delegation defaults
- **Time allocation budget:** hours per category per week
- **Flex slots:** day, time range, purpose
- **Meeting acceptance filter:** the decision tree for accepting/declining invitations
- **Delegation defaults:** meetings and activities formally delegated to others

#### 4. Load leadership framework

Read the resolved leadership framework. Extract hat definitions and time distribution targets.

#### 5. Gather external data

Dispatch the `week-planner` agent (see `agents/week-planner.md`) with:
- `week_start`: the Monday date for the plan
- `week_end`: the Friday date (week_start + 4 days)
- `projects`: the Asana project names from `--projects`
- `vault_root`: absolute path to the workspace
- `weekly_logs_folder`: `logs/weekly/`

The agent returns:
- Calendar events for Monday-Friday
- Asana tasks (due this week + from specified projects)
- Last week's review summary (if exists)

#### 6. Identify current month targets

From the quarterly plan, extract the **current month's** section:
- Rock targets for this month (which KRs should move, what the exit value is)
- Key activities listed for this month
- Exit criteria for this month

This is critical — it determines task priority. A task that serves a rock targeted for completion this month outranks one that serves a rock targeted for next month.

#### 7. Audit upcoming calendar

Cross-reference the week's actual calendar events against calendar rules. For each rule, check compliance:

| Check | How |
|-------|-----|
| Meeting-free days | Any events on days marked meeting-free? |
| Morning rule | Any events before the configured cutoff (e.g., 14:00) that aren't self-blocks? |
| Max meetings/day | Count real meetings per day (exclude self-blocks, declined events) |
| Max weekly hours | Sum all real meeting hours for the week |
| Delegation defaults | Any events matching delegated meetings the user shouldn't attend? |
| Protected blocks | Any events that overlap with protected blocks? |

Produce a violations table with: rule, issue, and recommended resolution (decline, move, or delegate).

#### 8. Calculate available blocks

For each day Monday-Friday:

1. Start with the protected blocks from calendar rules for that day
2. Overlay actual calendar events (after applying violation resolutions)
3. Add flex slots and async blocks from the time allocation budget
4. Calculate net available deep work hours per day

Present as a summary table:

| Day | Theme | Protected block | Meetings (after fixes) | Available deep work |
|-----|-------|----------------|----------------------|-------------------|

#### 9. Prioritize tasks

Rank all tasks (from Asana + quarterly plan key activities) using this priority stack:

1. **Overdue tasks** — immediate
2. **Tasks due this week** — by due date
3. **Tasks serving rocks targeted for completion this month** — by rock weight
4. **Tasks serving the at-risk rock** — by rock weight
5. **Key activities from the quarterly plan's current month section** — even if no Asana task exists
6. **Undated tasks from specified projects** — by rock alignment

For each task, determine:
- Which rock it serves (match by project name, task name, or notes content against rock descriptions)
- Which hat it requires (Architect, Engineer, Learner, Coach, Player)
- Estimated time needed (use task complexity as heuristic: simple = 30min, medium = 1-2h, deep = 2-3h)

#### 10. Assign tasks to blocks

Map prioritized tasks onto available blocks following these rules:

- **Tasks must match the day's hat theme.** A Strategy task goes on Monday (Architect day), not Wednesday (Engineer day). If no matching day has capacity, use the flex slot or buffer time.
- **Protected blocks get the highest-priority matching task.** The Strategy Block on Monday gets the #1 Architect-hat task, not a low-priority one.
- **Respect block durations.** Don't overload a 3-hour block with 5 hours of tasks.
- **Async/email blocks get decision-making and delegation tasks** — things that don't need deep focus.
- **If a task doesn't fit any block this week:** note it in a "Deferred" section with the reason.

#### 11. Estimate hat distribution

Based on the assigned schedule, calculate estimated hours per hat:

```
Architect   ~Xh   X%   (target: X%)
Learner     ~Xh   X%   (target: X%)
Engineer    ~Xh   X%   (target: X%)
Coach       ~Xh   X%   (target: X%)
Player      ~Xh   X%   (target: ≤X%)
Admin       ~Xh   X%
```

Flag any hat significantly over or under target.

#### 12. Assemble and save

Combine all outputs into the weekly plan document:

```markdown
---
type: weekly
created: {DD-MM-YYYY}
week: {YYYY-WNN}
tags: [weekly, plan, log]
---

# Weekly Plan — {DD-Mon} to {DD-Mon YYYY}

> **Week thesis:** {one sentence — what this week is about, derived from quarterly plan monthly theme and the highest-priority rock}

## Starting Position

{Table: rocks with weight, status, KR progress, current month target from quarterly plan}

Last week's weighted rock score: {from last review, or "N/A — no prior review"}

---

## Calendar Audit

### Violations detected

{Table: rule, issue, resolution — from step 7}

### Corrected meeting load

{Table: day, meetings after fixes, hours — from step 8}

---

## Daily Plan

### {Day} — {Theme} ({Hat})

{Table per day: Block | Time | Task | Serves}

{Notes: declined meetings, moved meetings, delegation actions}

### {repeat for each day}

---

## Week Exit Criteria

{Checklist: what should be true by Friday COB — derived from monthly exit criteria + this week's task assignments}

## Hat Distribution Target

{Hat distribution estimate from step 11}

---

*Next review: {Friday date} Friday COB.*
```

Save to: `$WORKSPACE/logs/weekly/plan-{DD-MM-YYYY}.md` where the date is the Monday of the planned week.

#### 13. Report

```
PLAN CREATED — Week of {Monday date}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rocks in focus:  {list rocks targeted this month}
Violations:      {N} detected, {N} resolved
Meeting hours:   {X}h (ceiling: {Y}h)
Deep work:       {X}h available across the week
File:            {path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Present the three most important actions for the user to take before the week starts (e.g., decline a meeting, move an event, message a delegate).

---

### Resilience

- If quarterly plan file is missing: proceed with rocks.yaml alone, note ⚠️ — the plan will lack monthly targets but can still schedule based on rock weights and status
- If calendar data fails: produce a plan based on the ideal schedule from calendar rules, note ⚠️ that it's not verified against actual events
- If Asana fails: produce a plan using only quarterly plan key activities, note ⚠️
- If last week's review is missing: skip the "Last week's score" line, note first-time plan
- If calendar rules are missing: this command cannot produce a meaningful plan — report ❌ and instruct the user to configure calendar rules first
- Never produce an empty plan — always output at least the ideal block structure from calendar rules
