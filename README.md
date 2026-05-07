# CEO Coach

> A direct, evidence-based advisor that holds you accountable by analyzing actual behavior against stated priorities.

## What it does

CEO Coach is a performance mirror for founders and executives. It gathers data from your calendar, email, tasks, and meeting notes, then scores your behavior against your own stated objectives. It audits calendar compliance, tracks delegation patterns, and produces a refocus directive — all with zero flattery. Think trusted board advisor, not cheerful assistant.

## Commands

| Command | Description |
|---------|-------------|
| `/review` | Performance review for a configurable time window. Scores CEO effectiveness, audits calendar, tracks delegation, produces a refocus directive. |
| `/reflect` | Guided reflection on a specific decision, event, or meeting. Reads context and asks hard questions. |
| `/goals` | Review and update quarterly objectives (rocks). Check alignment between stated priorities and actual time allocation. |
| `/plan` | Generate a weekly execution plan. Cross-references quarterly objectives, calendar availability, Asana tasks, and calendar rules to produce a day-by-day schedule with task assignments mapped to protected blocks and hat targets. |

## Skills

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
| `performance-analyst` | Gathers behavioral data (calendar, email, tasks, meetings) for a review window. |
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
   | `/review` | Google Calendar + Gmail (communication patterns) |
   | `/reflect`, `/goals` | None required (operate on local files) |

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

   - `rocks.yaml` — your quarterly objectives, key results, and weights
   - `calendar-rules.yaml` — protected blocks, day themes, meeting limits
   - `delegation-log.yaml` — starts empty, populated by the delegation tracker

   Then fill in the reference files used for scoring and reflection:

   - `references/values.md` — core philosophy and decision-making priorities
   - `references/thinking-style.md` — how you reason, your biases, depth calibration
   - `references/leadership-framework.md` — your CEO model: role hats, time targets, delegation philosophy

   Finally, point `commands/manifest.yaml` at the locations you chose if they differ from the defaults.

5. **First run.**

   ```
   /goals    # set or review your quarterly objectives
   /plan     # generate a weekly schedule grounded in those objectives
   ```

   Run `/review` at the end of any window (week, month, quarter) to score behavior against the goals you set.