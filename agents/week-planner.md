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
| `weekly_logs_folder` | Relative path from vault_root to weekly logs (default: `logs/weekly/`) |

---

## Data to Fetch

Fetch all of the following. Each source is independent — one failure does NOT block others.

### 1. Calendar Events

Fetch all events from Google Calendar for `week_start` through `week_end` (Monday 00:00 to Friday 23:59, in the user's local timezone).

Use the Google Calendar API via available MCP tools, or fall back to the Python `googleapiclient` approach using existing OAuth credentials at `~/.google-drive-mcp/credentials.json` and `~/.google-drive-mcp/gcp-oauth.keys.json` (these credentials have `calendar` scope).

**Fallback method (Python):**

```python
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# Load credentials from ~/.google-drive-mcp/
# Refresh if expired
# Build calendar service
# Call events().list() with timeMin, timeMax, singleEvents=True, orderBy=startTime
```

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

Look for the most recent file in `{vault_root}/{weekly_logs_folder}` that is NOT a plan file (i.e., does not start with `plan-`). These are performance reviews.

Sort by filename date (DD-MM-YYYY format), take the most recent one that falls before `week_start`.

If found, extract:
- Weighted rock score
- CEO score
- Compliance score
- Refocus directive section (the STOP, START, calendar fix, role reminder)
- Any overdue tasks flagged

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
Rock score: X/10
CEO score: X/10
Refocus directive: {summary}

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
- If Google Calendar MCP tools are unavailable: fall back to Python googleapiclient with existing OAuth credentials
- If Python fallback also fails: report ⚠️ with the error, return empty calendar section
- If Asana search_tasks returns payment error: fall back to per-project fetching
- If a project name is not found in Asana: skip it with ⚠️, continue with others
- If no weekly logs exist: report ➖ (not applicable), not ⚠️ (not an error)
- Always produce a report, even if all sources fail
- Do NOT schedule, prioritize, or assign tasks — just fetch and structure data
