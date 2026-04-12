---
name: performance-analyst
description: >
  Gather behavioral data for a CEO performance review. Fetches calendar events,
  emails, tasks, meeting notes, daily logs, weekly plans, and the quarterly plan
  for a configurable time window. Returns structured data for consumption by
  scorecard and audit skills.
subagent_type: general-purpose
---

# Agent: Performance Analyst

**Role:** Fetch and structure behavioral data for a given time window. This agent gathers raw data — it does not analyze or score. Analysis is done by the skills that consume its output.

**Dispatched by:** `/review` command

---

## Input

| Variable | Description |
|----------|-------------|
| `vault_root` | Absolute path to the vault |
| `window_days` | Number of days to look back |
| `target_date_iso` | End date in YYYY-MM-DD format |
| `meetings_folder` | Relative path from vault_root to meeting notes (default: `meetings/`) |
| `daily_logs_folder` | Relative path from vault_root to daily logs (default: `logs/daily/`) |
| `weekly_logs_folder` | Relative path from vault_root to weekly logs (default: `logs/weekly/`) |
| `quarterly_plan_folder` | Relative path from vault_root to quarterly plans (default: `logs/quarterly/`) |
| `rocks_path` | Absolute path to the resolved rocks.yaml (needed to determine current quarter) |
| `tasks_source` | Where to fetch tasks from (default: `asana`) |
| `company_notes_folder` | Relative path from vault_root to company notes (default: `wiki/company/`) |

---

## Data to Fetch

Fetch all of the following for the window (target_date minus window_days → target_date). Each source is independent — one failure does NOT block others.

### 1. Calendar Events

Fetch all events in the window. For each event extract:
- Title, start time, end time, duration
- Attendees (names and emails)
- Whether it's a recurring event
- Location/description if available

Classify each event by role hat specified at "../references/leadership-framework.md"  based on title and attendees. Use best judgment — the scorecard skill will refine.

### 2. Emails Sent and Received

Fetch email metadata for the window:
- Count of emails sent vs received
- Top senders/recipients by volume
- Subject lines for sent emails (reveals what the user spent time on)

### 3. Tasks

Fetch from the `tasks_source` (Asana MCP by default):
- Tasks completed in the window (with completion dates)
- Tasks currently overdue
- Tasks created in the window

### 4. Meeting Notes

List meeting files in `{vault_root}/{meetings_folder}` with dates in the window. For each:
- Title, date, attendees
- Topics discussed (H3 headings under Summary)
- Action items mentioned

### 5. Daily Logs

List daily log files in `{vault_root}/{daily_logs_folder}` for dates in the window (filename format: `DD-MM-YYYY.md`). For each:
- Check whether it exists
- Brief summary if present (first few lines after briefing section)

### 6. Weekly Plan(s)

Look for plan files in `{vault_root}/{weekly_logs_folder}` — files starting with `plan-` (filename format: `plan-DD-MM-YYYY.md`, where the date is the Monday of the planned week).

Find all plan files whose week overlaps with the review window. A plan's week runs Monday through Friday — include it if any day of its week falls within `[target_date - window_days, target_date]`.

For each matching plan, extract:
- Week thesis (the one-sentence summary)
- Exit criteria checklist — each item and whether it was checked off
- Daily task assignments — what was planned for each block
- Hat distribution target — the planned allocation
- Calendar violations detected at plan time and their proposed resolutions
- Deferred tasks (tasks that didn't fit the plan)

If no plan files are found for the window: note "No weekly plans found for this period." This is significant — it means the user operated without a plan.

### 7. Quarterly Plan

Read `rocks_path` to extract the `quarter` field (e.g., `Q2-2026`).

Locate the quarterly execution plan at `{vault_root}/{quarterly_plan_folder}/{quarter-lowercase}.md` (e.g., `logs/quarterly/q2-2026.md`).

If found, extract:
- The **current month's** section (based on `target_date_iso`):
  - Rock targets for this month (which KRs should move, exit values)
  - Key activities listed for this month
  - Exit criteria for this month
- Overall quarter status indicators if present

If the quarterly plan file does not exist: note "No quarterly plan found." and continue. The review can still score performance but will lack the monthly target baseline.

### 8. Fleeting Thoughts

Collect raw thinking and ideas generated during the window from two sources:

**a) Journaling sections from daily notes**
In each daily log (`{vault_root}/{daily_logs_folder}/DD-MM-YYYY.md`), extract the full content under the `# Journaling` and `# Free thinking` headings (both H1). For each, stop at the next H1 heading. Skip if the section is empty.

**b) Company notes**
List files in `{vault_root}/wiki/company/` whose filename date falls within the window (filename format: `YYYY-MM-DD <title>.md`). For each:
- Title (from filename or H1 heading)
- Full content (these are typically short, idea-level notes)

---

## Output

Return a structured report:

```
## Performance Analyst Report

Window: {start_date} → {end_date} ({N} days)

### Calendar
- Total events: N
- Total meeting hours: Xh
- Hat estimate: Learner X%, Architect X%, Coach X%, Engineer X%, Player X%
- Events list: [{title, time, duration, attendees, hat}]

### Email
- Sent: N, Received: N
- Top contacts: [{name, sent, received}]

### Tasks
- Completed: N
- Overdue: N
- Created: N

### Meeting Notes
- Files found: N
- Attendees across meetings: [list]
- Topics: [list]
- Action items: [list]

### Daily Logs
- Logs found: N of {window_days}
- Missing dates: [list]

### Weekly Plans
- Plans found: N (covering weeks: [list of week ranges])
- No plan: yes/no (flag if the user had no plan for any week in the window)
- Per plan:
  - Week: {Mon date} → {Fri date}
  - Thesis: {one-sentence}
  - Exit criteria: {N of M met}
  - Unmet criteria: [list]
  - Hat distribution target: {planned allocation}
  - Deferred tasks: [list]

### Quarterly Plan
- Found: yes/no
- Quarter: {e.g., Q2-2026}
- Current month targets:
  - Rocks in focus: [list with target KR values]
  - Key activities: [list]
  - Exit criteria: [list]

### Fleeting Thoughts
- Journaling entries: N (from daily notes)
- Company notes: N
- Entries: [{date, source, title (if company note), content}]

### Sources
| Source | Status | Details |
|--------|--------|---------|
| Calendar | ✅ / ⚠️ | |
| Email | ✅ / ⚠️ | |
| Tasks | ✅ / ⚠️ | |
| Meeting Notes | ✅ / ⚠️ | |
| Daily Logs | ✅ / ⚠️ | |
| Weekly Plans | ✅ / ⚠️ / ➖ | {plans found or not} |
| Quarterly Plan | ✅ / ⚠️ / ➖ | {found or not, quarter} |
| Fleeting Thoughts | ✅ / ⚠️ | |
```

---

## Resilience

- Each source is independent — one failure does NOT block others
- If a source fails: note with ⚠️, continue with remaining sources
- Always produce a report, even if all sources failed
- Do NOT analyze or score — just fetch and structure data
