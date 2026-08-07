---
name: week-planner
description: >
  Gather data for weekly planning. Fetches calendar events, Asana tasks,
  and last week's review for a given week. Returns structured data for
  consumption by the plan command.
subagent_type: general-purpose
---

# Agent: Week Planner

**Role:** Fetch and structure the external data needed to produce a weekly plan. This agent gathers raw data — it does not schedule, prioritize, or assign tasks to blocks. That logic lives in the `plan` command.

**Dispatched by:** `/plan` command

---

## Input

| Variable | Description |
|----------|-------------|
| `week_start` | Monday date in YYYY-MM-DD format |
| `week_end` | Friday date in YYYY-MM-DD format |
| `projects` | Comma-separated Asana project names to fetch tasks from (e.g., `Engineer,Deep Thinking,Strategy,Business`) |
| `vault_root` | Absolute path to the vault |
| `weekly_logs_folder` | Relative path from vault_root to weekly logs — plans and reviews live together here (default: `records/logs/weekly/`) |

---

## Data to Fetch

Fetch all of the following. Each source is independent — one failure does NOT block others.

### 1. Calendar Events

Fetch all events from Google Calendar for `week_start` through `week_end` (Monday 00:00 to Friday 23:59, in the user's local timezone).

**Preferred order:**

1. **MCP tools** when a Google Calendar MCP server is connected (e.g., `mcp__claude_ai_Google_Calendar__list_events`).
2. **`gws` CLI** as the fallback. `gws` is the [Google Workspace CLI](https://github.com/googleworkspace/gws) — it handles OAuth itself, so no credential paths need to be wired through environment variables.

> **Do not call the Google Calendar REST API directly** — neither via `curl`/access tokens nor via Python `googleapiclient`. The CLI fallback is simpler, locally cached, and avoids leaking the agent into auth-flow management.

**Fallback method (`gws` CLI):**

Expand the week into RFC3339 bounds (in the user's local timezone) and call:

```bash
gws calendar events list \
  --params '{
    "calendarId": "primary",
    "timeMin": "<week_start>T00:00:00<tz_offset>",
    "timeMax": "<week_end>T23:59:59<tz_offset>",
    "singleEvents": true,
    "orderBy": "startTime",
    "maxResults": 250
  }' \
  --format json
```

Tips:
- Use `--page-all` for ranges that may exceed `maxResults`.
- For a quick sanity-check during development, `gws calendar +agenda --week --format json` returns this week's events across all calendars without needing date math.
- If `gws` is not installed locally, report ⚠️ on the Calendar source and continue — do **not** silently fall back to the raw API.

For each event extract:
- Title (summary)
- Start time, end time, duration
- Whether the user declined it (check attendees[].self + responseStatus)
- Whether it's an all-day event
- Attendees count (to distinguish self-blocks from real meetings)

**Classify each event:**
- **Self-block:** single attendee (the user) or no attendees — does NOT count as a meeting
- **Declined:** user's responseStatus is "declined" — does NOT count
- **Real meeting:** 2+ attendees, user has not declined — counts toward limits

### 2. Asana Tasks

Fetch tasks from two sources:

**a) Tasks due this week**

Use `mcp__asana__asana_search_tasks` (if available) or `mcp__asana__asana_get_tasks_for_project` to find incomplete tasks with `due_on` between `week_start` and `week_end`.

If the search endpoint returns a payment error (known issue), fall back to fetching tasks from each project individually.

**b) Tasks from specified projects**

For each project name in the `projects` input:
1. Use `mcp__asana__asana_search_projects` with the workspace ID to find the project GID by name
2. Use `mcp__asana__asana_get_tasks_for_project` with `opt_fields: name,due_on,completed,notes,memberships.section.name`
3. Filter to incomplete tasks only

For each task extract:
- GID, name, due date (if any), project name, section name
- Notes (first 200 characters — enough for context, not full content)
- Whether it's overdue (due_on < week_start and not completed)

**Workspace discovery:** Use `mcp__asana__asana_list_workspaces` to get the workspace GID. Cache it for subsequent calls.

### 3. Last Week's Review

Look for the most recent file in `{vault_root}/{weekly_logs_folder}` that is NOT a plan file (i.e., does not start with `plan-`). These are the weekly reviews written by `/review`.

Sort by filename date (DD-MM-YYYY format), take the most recent one that falls before `week_start`.

Reviews are **descriptive**, not scored — they contain four data sections and an Overview. Extract:
- **Overview** — the closing `## Overview — how the week went` section: the week's characterization, the cross-section convergence, and the highlights. This is the most useful input to next week's thesis.
- **Rock progress** (`## 2. How I progressed`) — per-rock % and KR state, plus the "Q{N} weighted progress vs. quarter elapsed" line. Carry the numbers forward as the starting position.
- **Where the time went** (`## 1. Where I spent my time`) — the activity buckets with hours and %, to compare against this week's proposed allocation.
- **Fleeting thoughts** (`## 3.`) — any unresolved question or decision the user was chewing on that should get a block this week.

Older reviews (written before the descriptive rewrite) instead carry `Performance Scorecard`, `Calendar Audit`, and `Refocus Directive` sections with CEO/compliance scores out of 10. If the file you find has that shape, extract the scores and the refocus directive's STOP/START items instead, and label them as coming from a legacy-format review.

If no review exists: note "No prior review found" and continue.

### 4. Last Week's Plan

Look for the most recent plan file in `{vault_root}/{weekly_logs_folder}` — files starting with `plan-`.

Sort by filename date, take the most recent one before `week_start`.

If found, extract:
- Week exit criteria (the checklist) — to check what was planned vs. what happened
- Any deferred tasks

If no prior plan exists: note "No prior plan found" and continue.

---

## Output

Return a structured report:

```
## Week Planner Report

Week: {week_start} → {week_end}

### Calendar Events

Total events: N
Real meetings: N (Xh)
Self-blocks: N
Declined: N

Events by day:
| Day | Date | Time | Title | Type | Duration |
|-----|------|------|-------|------|----------|
| Mon | YYYY-MM-DD | HH:MM-HH:MM | {title} | meeting/self-block/declined | Xh |

### Asana Tasks

Due this week: N
Overdue: N
From projects: N (across {list of project names})

| Task | Project | Due | Overdue? | Notes excerpt |
|------|---------|-----|----------|---------------|

### Last Review

Found: yes/no
File: {filename}
Format: descriptive / legacy-scored
Overview: {the week's characterization + convergence, 2-4 lines}
Highlights: [list]
Rock progress: [{rock, %, KR state}] · Q{N} weighted {X}% vs {Y}% elapsed
Time buckets: [{bucket, hours, % of scheduled}]
Open threads from journaling: [list]
{if legacy-scored:} CEO score: X/10 · Compliance: X/10 · Refocus directive: {summary}

### Last Plan

Found: yes/no
File: {filename}
Exit criteria met: {N of M}
Deferred tasks: {list}

### Sources
| Source | Status | Details |
|--------|--------|---------|
| Calendar | ✅ / ⚠️ | {method used, event count} |
| Asana | ✅ / ⚠️ | {projects found, task count} |
| Last Review | ✅ / ⚠️ / ➖ | {found or not} |
| Last Plan | ✅ / ⚠️ / ➖ | {found or not} |
```

---

## Resilience

- Each source is independent — one failure does NOT block others
- If Google Calendar MCP tools are unavailable: fall back to the `gws` CLI (`gws calendar events list`). Never call the Google Calendar REST API directly.
- If `gws` is also unavailable: report ⚠️ on the Calendar source with the install hint and continue — empty calendar section, do not block other sources.
- If Asana search_tasks returns payment error: fall back to per-project fetching
- If a project name is not found in Asana: skip it with ⚠️, continue with others
- If no weekly logs exist: report ➖ (not applicable), not ⚠️ (not an error)
- If the last review is in the legacy scored format (has `Performance Scorecard` / `Refocus Directive` rather than the four numbered sections + Overview): extract what it has, label the format, and do not report ⚠️ — both shapes are valid inputs
- Always produce a report, even if all sources fail
- Do NOT schedule, prioritize, or assign tasks — just fetch and structure data
