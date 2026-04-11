---
name: ceo-coach:goals
description: >
  Review and update quarterly objectives (rocks). Check alignment between
  stated priorities and actual time allocation.
---

## Command: ceo-coach:goals

Review the current quarterly objectives, update their status, and check whether actual time allocation matches stated priorities.

---

### Input

| Parameter | Description |
|-----------|-------------|
| (none) | Show current rocks dashboard |
| `update` | Interactive rock status update |
| `align` | Run alignment analysis against recent activity |

---

### Execution Steps

#### 1. Manifest resolution

Invoke `manifest-resolver` for domain `ceo-coach`.
Resolve: `rocks` (required).

#### 2. Load rocks

Read the resolved `rocks.yaml` file. Parse each rock with its KRs, weights, and current status.

#### 3. Route by sub-command

**Dashboard (default):**

Present the current state:

```
## Quarterly Rocks

| # | Rock | Weight | Status | Progress |
|---|------|--------|--------|----------|
| 1 | {name} | {weight}% | {status} | [■■■■░░░░░░] 40% |
| 2 | {name} | {weight}% | {status} | [■■■■■■░░░░] 60% |

### Key Results
**Rock 1: {name}**
- [ ] KR1: {description} — {status}
- [x] KR2: {description} — done
```

**Update (interactive):**

Walk through each rock:
1. Show current status and KRs
2. Ask: "What's the current status? Any KRs to mark as done or update?"
3. Apply changes to rocks.yaml
4. Report what was updated

**Align:**

Fetch recent activity (last 14 days) from calendar, tasks, and meeting notes. For each rock:
1. Calculate approximate time spent (from calendar events and tasks tagged to that rock)
2. Compare time % against the rock's weight %
3. Flag misalignment: "Rock X has 40% weight but only 10% of your time"

Present as an alignment scorecard:

```
## Rock Alignment (last 14 days)

| Rock | Weight | Time Spent | Δ | Signal |
|------|--------|-----------|---|--------|
| {name} | 40% | 35% | -5% | ✅ Aligned |
| {name} | 30% | 10% | -20% | ⚠️ Under-invested |
| {name} | 30% | 55% | +25% | ⚠️ Over-indexed |
```

---

### Resilience

- If rocks.yaml is missing: prompt to create it with a guided flow
- If activity data is unavailable for `align`: note with ⚠️, show rocks dashboard only
- Never modify rocks.yaml without explicit confirmation
