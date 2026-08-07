# CEO Coach

> A direct, evidence-based advisor that holds you accountable by analyzing actual behavior against stated priorities.

## What it does

CEO Coach is a performance mirror for founders and executives. `/review` aggregates four lenses over any window — where the time went (calendar), how you progressed (completed tasks + rocks), your fleeting thoughts (daily-note journaling), and other relevant information (meeting transcripts) — then closes with an interpretive Overview that names where those sources converge. It reports and synthesizes; it deliberately does not grade.

Scoring, calendar compliance, delegation tracking, and refocus directives are standalone skills you invoke when you want them — `/review` no longer orchestrates them. Either way: zero flattery. Think trusted board advisor, not cheerful assistant.

## Commands

| Command | Description |
|---------|-------------|
| `/review` | Descriptive review for a configurable time window (`--window`, default `7d`). Four neutral sections — time allocation, progress against rocks, fleeting thoughts, meeting themes — followed by an interpretive Overview generated last. Saved to `records/logs/weekly/DD-MM-YYYY.md`. |
| `/reflect` | Guided reflection on a specific decision, event, or meeting. Reads context and asks hard questions. |
| `/goals` | Review and update quarterly objectives (rocks). Check alignment between stated priorities and actual time allocation. |
| `/plan` | Generate a weekly execution plan. Cross-references quarterly objectives, calendar availability, Asana tasks, and calendar rules to produce a day-by-day schedule with task assignments mapped to protected blocks and hat targets. |

## Skills

`manifest-resolver` runs at the start of every command. The four analytical skills below are **ad-hoc**: `/review` used to orchestrate them and no longer does, so invoke them directly when you want a score, a compliance audit, a delegation pass, or a directive.

| Skill | Description |
|-------|-------------|
| `manifest-resolver` | Resolves config file paths from a YAML manifest before command execution. |
| `performance-scorecard` | Scores CEO performance across 6 dimensions: constraint focus, CEO-level work, delegation, strategic thinking, talent development. |
| `calendar-audit` | Audits calendar compliance against configured scheduling rules. |
| `refocus-directive` | Synthesizes next-period focus from scorecard + audit: constraint, hat to wear, stop/start actions, calendar fix. |
| `delegation-tracker` | Tracks delegation patterns over time. Escalates recurring items at configurable streak thresholds. |

## Agents

| Agent | Description |
|-------|-------------|
| `performance-analyst` | Gathers behavioral data (calendar, email, tasks, meetings, daily logs, plans) for a review window. `/review` consumes four of its slices — calendar, completed tasks, daily-note journaling, meeting notes — and ignores the rest. |
| `week-planner` | Gathers calendar events, Asana tasks, and prior week's review/plan for weekly planning. |

## Setup

1. **Install the plugin.**

   Via the plugin marketplace:

   ```
   /plugin install ceo-coach
   ```

   Or via clone:

   ```
   git clone https://github.com/feliun/ceo-coach.git ~/path/to/ceo-coach
   ln -s ~/path/to/ceo-coach ~/.claude/plugins/ceo-coach
   ```

2. **Configure MCP servers.**

   CEO Coach reads behavioral data from external sources via Claude Code's MCP integration. You configure these yourself — the plugin does not bundle MCP servers.

   | Command | Required MCP servers |
   |---------|---------------------|
   | `/plan` | Asana (task fetch) + Google Calendar (availability) |
   | `/review` | Google Calendar (time allocation) + Granola (meeting transcripts) + Asana (completed tasks, optional) |
   | `/reflect`, `/goals` | None required (operate on local files) |

   `/review` degrades rather than fails: Asana's search endpoint is premium-gated, so when the completed-tasks query returns `payment_required` the command derives completed tasks from the daily notes' `✅ Cleared` markers and flags that section ⚠️. A calendar or Granola outage falls back to the daily notes' `### Calendar` and `# Meetings` sections the same way. Only a missing `rocks.yaml` stops it.

   See the [Claude Code MCP setup guide](https://docs.anthropic.com/en/docs/claude-code/mcp) for instructions on installing and authenticating each server. Any MCP server that exposes the equivalent tools will work — the agents call tools by name (e.g., `mcp__asana__asana_search_tasks`).

3. **Install `gws` (Google Calendar CLI fallback).**

   When the Google Calendar MCP server is unavailable, the `week-planner` agent falls back to the [`gws` CLI](https://github.com/googleworkspace/gws) (Google Workspace CLI). The agent is instructed **not** to call the Google Calendar REST API directly (no `curl` against the API, no Python `googleapiclient`) — `gws` handles OAuth itself and produces JSON the agent can parse.

   Install once:

   ```
   npm install -g @googleworkspace/cli        # installs the `gws` binary
   gws calendar +agenda --today               # triggers first-time auth
   ```

   If you only use the Google Calendar MCP server, the fallback is never invoked and `gws` is optional. If neither is available, the calendar section of `/plan` reports ⚠️ and the rest of the plan still runs.

4. **Configure your goals and rules.**

   The `config/` directory ships `.example` templates. Copy each one, drop the `.example` suffix, then edit:

   ```
   cp config/rocks.yaml.example          config/rocks.yaml
   cp config/calendar-rules.yaml.example config/calendar-rules.yaml
   cp config/delegation-log.yaml.example config/delegation-log.yaml
   ```

   - `rocks.yaml` — your quarterly objectives, key results, and weights. The only file `/review` requires.
   - `calendar-rules.yaml` — protected blocks, day themes, meeting limits. Used by `/plan` and the `calendar-audit` skill.
   - `delegation-log.yaml` — starts empty, populated by the `delegation-tracker` skill.

   Then fill in the reference files used by `/reflect`, `/goals`, and the ad-hoc scoring skills:

   - `references/values.md` — core philosophy and decision-making priorities
   - `references/thinking-style.md` — how you reason, your biases, depth calibration
   - `references/leadership-framework.md` — your CEO model: role hats, time targets, delegation philosophy

   Finally, point `commands/manifest.yaml` at the locations you chose if they differ from the defaults.

5. **Check the vault layout `/review` reads from.**

   `/review` sources three of its four sections from files in your workspace, so the paths have to match:

   | Path | Used for |
   |------|----------|
   | `records/logs/daily/DD-MM-YYYY.md` | Section 3 — the `# Journaling` and `# Free Thinking` sections; also the fallback source for calendar and completed tasks |
   | `records/meetings/YYYY-MM-DD slug.md` | Section 4 — meeting transcript synthesis |
   | `records/logs/weekly/` | Where the finished review is saved (`weekly-plans` in the manifest), alongside `/plan` output |

   Reviews wikilink out to those notes (`[[05-08-2026]]`, `[[2026-08-06 pilares-de-contenido]]`), so they read as a navigable index in Obsidian. A meeting on the calendar with no note yet is cited by raw title and marked *(meeting note not yet pulled)* rather than linked.

6. **First run.**

   ```
   /goals    # set or review your quarterly objectives
   /plan     # generate a weekly schedule grounded in those objectives
   ```

   Run `/review` at the end of any window (week, month, quarter) to see what actually happened: where the hours went, which rocks moved, what you were thinking about, and what the four lenses together say when read as one story.