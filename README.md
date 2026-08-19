# CEO Coach

> A direct, evidence-based advisor that holds you accountable by analyzing actual behavior against stated priorities.

## What it does

CEO Coach is a performance mirror for founders and executives. `/review` aggregates five lenses over any window — where the time went (calendar), how you progressed (completed tasks + rocks), your fleeting thoughts (daily-note journaling), other relevant information (meeting transcripts), and how your X/Twitter posting performed — then closes with an interpretive Overview that names where those sources converge. It reports and synthesizes; it deliberately does not grade.

The one exception is a prescriptive Section 6, which turns the week's own raw material into concrete content ideas. It is fenced off from the five descriptive lenses on purpose, and it is not an input to the Overview.

Scoring, calendar compliance, delegation tracking, and refocus directives are standalone skills you invoke when you want them — `/review` no longer orchestrates them. Either way: zero flattery. Think trusted board advisor, not cheerful assistant.

## Commands

| Command | Description |
|---------|-------------|
| `/review` | Descriptive review for a configurable time window (`--window`, default `7d`). Five neutral sections — time allocation, progress against rocks, fleeting thoughts, meeting themes, Twitter performance — then one prescriptive section of content recommendations, followed by an interpretive Overview generated last. Saved to `records/logs/weekly/DD-MM-YYYY.md`. |
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
| `twitter-analyst` | Fetches X/Twitter account metrics and windowed post metrics via the `xurl` CLI. Two API calls per run. |

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
   | `/review` | Google Calendar (time allocation) + Granola (meeting transcripts) + Asana (completed tasks, optional). Sections 5–6 additionally need the `xurl` CLI — not an MCP server, see step 4 |
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

4. **Install `xurl` (required only for Sections 5 and 6).**

   The `twitter-analyst` agent reads the X API through the [`xurl`](https://github.com/xdevplatform/xurl) CLI, authenticated with **OAuth 2.0 user context** — organic and non-public metrics are only available to the account that owns the posts.

   ```
   xurl auth oauth2          # one-time browser flow
   xurl /2/users/me          # confirm it returns your account
   ```

   Without it, Sections 5 and 6 are each replaced by a single ⚠️ line and the rest of the review is unaffected. Two API calls per run, well inside the free rate limits.

   Three limits worth knowing, all measured rather than taken from the docs:

   - **Profile visits are not exposed by the API at all.** `/review` reports `user_profile_clicks` (clicks to your profile *from your posts*) as an explicitly labelled proxy. The X Analytics dashboard is the only source for true visit counts.
   - **Detailed metrics expire at roughly 90 days.** Beyond that only `public_metrics` comes back, and the affected rows are marked ⚠️ rather than rendered as `0`. Retweets never carry detailed metrics at any age.
   - **`engagements` is broader than it looks** — it counts detail expands and clicks, not just likes, replies and retweets, so it runs well above the visible interaction total.

5. **Configure your goals and rules.**

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

   Finally, point `commands/manifest.yaml` at the locations you chose if they differ from the defaults. Every path the plugin touches is resolved through that manifest — nothing is hardcoded — so a differently-shaped vault only needs the manifest edited, not the commands.

   | Manifest key | Required | Used by |
   |---|---|---|
   | `rocks` | **yes** | `/review`, `/plan`, `/goals`, scorecard |
   | `calendar-rules` | no | `/plan`, `calendar-audit` |
   | `delegation-log` | no | `delegation-tracker` |
   | `values` | no | `/goals`, scorecard |
   | `thinking-style` | no | `/reflect` |
   | `leadership-framework` | no | `/plan`, scorecard, `calendar-audit` |
   | `weekly-plans` | no | `/review` (save location, follower baseline), `/plan` |
   | `quarterly-plan` | no | `/plan` |
   | `tweets` | no | `/review` §5–§6 post wikilinks |

6. **Check the vault layout `/review` reads from.**

   `/review` and `/plan` read and write these workspace paths, so they have to match:

   | Path | Used for |
   |------|----------|
   | `records/logs/daily/DD-MM-YYYY.md` | Section 3 — the `# Journaling` and `# Free Thinking` sections; also the fallback source for calendar and completed tasks |
   | `records/meetings/YYYY-MM-DD slug.md` | Section 4 — meeting transcript synthesis |
   | `records/tweets/{tweet_id}.md` | Sections 5 and 6 — wikilink targets for your posts (`tweets` in the manifest, **optional**). Populated by wiki-manager's `/pull-tweets`; when absent, posts link to `x.com` instead |
   | `records/logs/weekly/` | Where the finished review is saved (`weekly-plans` in the manifest), alongside `/plan` output (`plan-DD-MM-YYYY.md`). Also holds the previous run's follower count, so the net follower delta needs no separate state file |
   | `records/logs/quarterly/qN-YYYY.md` | `/plan` only — the quarterly execution plan for the quarter named in `rocks.yaml` (`quarterly-plan` in the manifest, **optional**). Absent means `/plan` falls back to rock weights without monthly targets |

   Reviews wikilink out to those notes (`[[05-08-2026]]`, `[[2026-08-06 pilares-de-contenido]]`, `[[2088289040139173943|post snippet]]`), so they read as a navigable index in Obsidian. A meeting on the calendar with no note yet is cited by raw title and marked *(meeting note not yet pulled)* rather than linked. A post with no note yet falls back to its `x.com` URL — mixed link styles in one table are expected, not an error.

7. **First run.**

   ```
   /goals    # set or review your quarterly objectives
   /plan     # generate a weekly schedule grounded in those objectives
   ```

   Run `/review` at the end of any window (week, month, quarter) to see what actually happened: where the hours went, which rocks moved, what you were thinking about, how your posting landed, and what the five lenses together say when read as one story.

