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

### Prerequisites

- Calendar access (for time allocation analysis)
- Task manager access (for completion tracking)
- Optional: email access (for communication pattern analysis)
- Optional: meeting notes folder (for context extraction)

### Configuration

1. Copy config examples from `config/` and customize:
   - `rocks.yaml` — Your quarterly objectives with KRs and weights
   - `calendar-rules.yaml` — Your scheduling rules and compliance targets
   - `delegation-log.yaml` — Starts empty, populated by the delegation tracker
2. Fill in reference files:
   - `references/values.md` — Your core philosophy and decision-making priorities
   - `references/thinking-style.md` — How you reason, your biases, depth calibration
   - `references/leadership-framework.md` — Your CEO model: role hats, time targets, delegation philosophy
1. Edit `commands/manifest.yaml` to point to your file locations