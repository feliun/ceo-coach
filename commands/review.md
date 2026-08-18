---
name: ceo-coach:review
description: >
  Descriptive weekly review for a configurable time window. Aggregates four lenses —
  time allocation (calendar), progress (completed tasks + rocks), fleeting thoughts
  (daily-note journaling), and relevant info (meeting transcripts) — then synthesizes
  an interpretive Overview. Period-agnostic — the user decides when to run it.
---

## Command: ceo-coach:review

Produces a **descriptive** weekly review: four neutral "here's what happened" lenses,
followed by a single interpretive Overview. This command deliberately does NOT score,
audit the calendar against rules, or issue a refocus directive — it reports and
synthesizes, it does not grade. (The scoring/audit/delegation/refocus skills still
exist for ad-hoc use but are no longer orchestrated here — see `### Retired orchestration`.)

---

### Input

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--window` | `7d` | Time window to review (e.g., `7d`, `14d`, `30d`) |

---

### Execution Steps

#### 1. Manifest resolution

Invoke `manifest-resolver` for domain `ceo-coach`. Resolve:
- `rocks` (**required**) — quarterly objectives, KRs, weights, status.
- `weekly-plans` (optional) — the `records/logs/weekly/` directory; this is where the
  review is saved, and it is also the source of the previous run's follower figure for
  Section 5. Its absence downgrades the follower delta to *baseline*; it never blocks
  the run.
- `tweets` (optional) — the `records/tweets/` directory, used to wikilink posts to
  their vault notes in Sections 5 and 6. When it resolves nowhere, posts link to
  `x.com` instead.

The other manifest keys (`calendar-rules`, `delegation-log`, `leadership-framework`,
`values`, `quarterly-plan`, `thinking-style`) are **not needed** by this command.

#### 2. Gather behavioral data

Dispatch the `performance-analyst` agent (`agents/performance-analyst.md`) with the
resolved `rocks` path for the window. This command only consumes four of its slices:

- **Calendar events** for the window → Section 1
- **Tasks completed** in the window → Section 2
- **Daily logs** (the `# Journaling` and `# Free Thinking` sections) → Section 3
- **Meeting notes** from the window → Section 4

Emails, overdue tasks, weekly/quarterly plans, and fleeting-thought hubs the agent may
also return are ignored here.

Dispatch **both agents in parallel — two tool calls in a single message**:

- `performance-analyst` (`agents/performance-analyst.md`) with the resolved `rocks`
  path, as above.
- `twitter-analyst` (`agents/twitter-analyst.md`) with `window_days`,
  `target_date_iso`, and `tweets_folder` set to the resolved `tweets` path (or null).
  Its account and post slices feed Section 5, and Section 6 reads the same data plus
  the account bio it returns.

The two agents share no state and neither blocks the other. A `twitter-analyst`
failure **must not block** Sections 1–4 or the Overview: on failure, render the ⚠️
lines described under *Fallbacks & resilience* and continue.

#### 3. Assemble the five descriptive sections

Build the sections **in this order** (1 → 5). Keep the tone neutral and factual — no
scoring, no drift-shaming. Each section states its own data source.

**Wikilink rules (apply everywhere):**
- **Daily notes** → link by `DD-MM-YYYY` basename, e.g. `[[05-08-2026]]` (Obsidian
  resolves regardless of the `records/logs/daily/` path).
- **Meeting notes** → link by `YYYY-MM-DD slug` basename, e.g.
  `[[2026-08-06 pilares-de-contenido|Pilares de contenido]]`.
- **Completed tasks** → link to their raw Asana URL (from the daily-note task lines).
- **Rocks** → plain text; pull rock names **verbatim** from `rocks.yaml`, never
  abbreviated.
- **Posts** → wikilink to their vault note by tweet id when
  `records/tweets/{tweet_id}.md` exists, aliased to the snippet
  (`[[2088289040139173943|Uno de los tips profesionales…]]`); otherwise the markdown
  link to the `x.com` URL. Mixed output within one table is expected — `/pull-tweets`
  defaults to a 7-day window — and is never marked ⚠️.

##### Section 1 — Where I spent my time
Source: calendar allocation. Group events into activity buckets (e.g. team weeklies &
governance, 1:1s, deep work, sales & external BD, content, community & learning), with
hours and % of scheduled time. Add a few plain observations (heaviest day, open days,
skipped events). Wikilink each named meeting to its meeting note.

##### Section 2 — How I progressed
Source: completed tasks + `rocks.yaml`.
- List tasks completed in the window, each linked to its Asana URL, each tagged with the
  rock(s) it feeds (verbatim rock name, or "no rock").
- Render **all** rocks from `rocks.yaml` (do not drop any), each with a progress bar, %,
  and KR breakdown. Include "Q3 weighted progress vs. quarter elapsed".
- Add one neutral "where the week's work landed" line: note when effort was high on a
  rock but its KRs (deliverable-gated) didn't move. State it factually, don't grade it.

##### Section 3 — Fleeting thoughts
Source: daily-note `# Journaling` / `# Free Thinking` sections.
- Quote each substantive entry, attributed to its source daily note via wikilink
  (`— from [[DD-MM-YYYY]]`).
- Name the days with no entry ("Mon/Tue blank"). If the whole window is blank, say so
  plainly — do not editorialize it as a failure.

##### Section 4 — Other relevant information
Source: meeting transcripts (Granola notes in `records/meetings/`).
- Synthesize across all meetings into a handful of themed buckets (e.g. Financials &
  compensation, People & org, Product, Content & conferences, Sales & BD, Afianza, Team
  development) — not a meeting-by-meeting dump.
- Head each bucket with wikilinks to the meeting notes it draws from.
- **No-note fallback:** if a meeting exists (calendar/Granola) but has no vault note yet,
  cite its raw title and mark *(meeting note not yet pulled)* instead of a broken
  wikilink.

##### Section 5 — Twitter performance
Source: the `twitter-analyst` report. **Descriptive only** — same register as
Sections 1–4. Report, do not grade: no praise, no drift-shaming, no telling the reader
what to do. Anything prescriptive **belongs to Section 6**.

Open with the source line:

```
*Source: X API v2 via the `xurl` CLI (OAuth2 user context, @{username}) — organic and non-public metrics.*
```

Then, in order:

1. **Headline.** `**{N} posts · {M} impressions · {E} engagements · {X}% engagement
   rate.**` followed by the type split, naming self-replies and threads when present.

2. **Totals table** — one row per metric (impressions, engagements, engagement rate,
   likes, bookmarks, replies received, retweets, quotes, link clicks), with a
   *Median per post* column. Medians matter because the distribution is heavily
   **skewed** — one high-reach post distorts a mean. Render link clicks as
   `⚠️ not returned` when the API omitted the field; never `0`, which would falsely
   assert nobody clicked.

3. **Followers line.**

   ```
   **Followers: {N}** — net {±D} vs {prior} recorded in [[DD-MM-YYYY]]. Following: {N}.
   ```

   With no prior figure: `**Followers: {N}** — baseline, no prior figure recorded.`

   The prior figure comes from the most recent review file in `records/logs/weekly/`
   whose basename does not start with `plan-` and whose date precedes this window's
   end, matched on `followers=(\d+)` inside its `x-snapshot` anchor.

   Follower counts are **point-in-time at *run* time** — X exposes no historical
   series. When the run date is later than the window end (any backfilled or late
   review), append a ⚠️ naming both dates, or growth gets attributed to the wrong week.

4. **Profile clicks line.**

   ```
   **Profile clicks from posts: {N}** — ⚠️ API proxy. X does not expose total profile visits; the X Analytics dashboard is the only source for that.
   ```

5. **Split-by-type table** — posts, impressions, engagements and median engagement
   rate per type, with each figure's share of the window total.

6. **Per-post table**, sorted by impressions descending:

   | Date | Type | Impressions | Eng. | Eng. rate | Bookmarks | Profile clicks | Post |

   The `Post` cell holds the first ~60 characters as link text, resolved by the
   wikilink rule above. Article posts show the article title instead.

   **Inclusion rule.** List every original, quote, article and self-reply, plus any
   reply to others with ≥**100 impressions**. Account for everything excluded in one
   trailing line so nothing is silently dropped:

   ```
   *Plus {N} replies below 100 impressions ({M} impressions, {E} engagements combined).*
   ```

7. **Observations** — plain factual bullets, only what the data supports: the
   original-vs-reply split in volume against the same split in impressions; threads
   posted and their combined reach; the spread between the top post and the median;
   days with no posts; language mix when more than one appears. Two caveats are
   mandatory whenever the relevant data is present:
   - ⚠️ **`engagements` is broader than it looks** — it counts **detail expands** and
     clicks, not just likes, replies and retweets. Give the visible-interaction total
     alongside it for the largest post so the engagement rate is not misread.
   - ⚠️ **Link clicks not returned** when `url_link_clicks` was absent, noting that
     absent is not zero.

   "Originals were 29% of volume and 87% of impressions" is in register.
   "Post more originals" is not — that **belongs to Section 6**.

8. **Snapshot anchor**, as the section's final line:

   ```
   <!-- x-snapshot: followers={N} following={N} at={YYYY-MM-DD} -->
   ```

#### 4. Synthesize the Overview (generated LAST, placed LAST)

After sections 1–4 exist, write a short **Overview** as the final section. This is the
one interpretive part of the review — a synthesis *over* the four data sections, not an
independent fetch. It must:
- Characterize the week in a sentence or two (e.g. "a strategy-and-alignment week, not a
  shipping week").
- Name **cross-section convergence** — where the calendar, the rocks, and the journaling
  point at the same story. This is the Overview's main job; no single section shows it
  alone.
- List the **main highlights** (3–6 bullets), each wikilinked to its supporting
  meeting/daily note.

Keep it honest and direct (board-advisor tone) but grounded strictly in the gathered
data — never invent.

#### 5. Assemble and save

Save to `records/logs/weekly/DD-MM-YYYY.md` (end date of the window) — same directory as
weekly plans; reviews and plans form the weekly accountability loop.

```markdown
---
type: reflection
created: {DD-MM-YYYY}
tags: [review, performance, log]
status: active
---

# Weekly Review — {DD-MM-YYYY}
*Window: {start} → {end}*

## 1. Where I spent my time
{Section 1}

## 2. How I progressed
{Section 2}

## 3. Fleeting thoughts
{Section 3}

## 4. Other relevant information
{Section 4}

## 5. Twitter performance
{Section 5}

## Overview — how the week went
{Interpretive synthesis + main highlights, generated last}
```

#### 6. Report

```
REVIEW COMPLETE — {DD-MM-YYYY}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Window:        {window}
Time tracked:  {N}h scheduled across {M} sessions
Tasks done:    {N} completed
Rocks:         {N} at 0% · Q3 {X}% vs {Y}% elapsed
Meetings:      {N} synthesized
X / Twitter:   {N} posts · {M} impressions · {X}% eng · {F} followers ({±D})
File:          {path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

When the analyst was unavailable, that line reads
`X / Twitter:   ⚠️ unavailable ({reason})` instead.

---

### Fallbacks & resilience

- **Asana search is premium-gated** (`payment_required` on both `asana` and
  `claude_ai_Asana` MCP servers). When the live completed-tasks query fails, derive
  completed tasks from the daily notes' `✅ Cleared` / `dropped off` markers, and mark the
  Section 2 source line with ⚠️ noting it may be incomplete.
- **Calendar / Granola MCP down:** retry once; if still failing, fall back to the daily
  notes' `### Calendar` briefings and `# Meetings` links, and mark ⚠️. Never leave a
  section blank — mark it ⚠️ and continue.
- **Rocks config missing:** this command cannot run without it (Section 2 depends on it) —
  stop and report.
- **performance-analyst fails:** attempt inline gathering of the four sources (calendar
  via Google Calendar MCP, completed tasks via daily-note markers, journaling via
  `records/logs/daily/`, meetings via `records/meetings/`), note with ⚠️.
- **`xurl` missing or unauthenticated:** omit Sections 5 and 6 entirely, replacing each
  with a single ⚠️ line naming the reason (`xurl not installed` /
  `xurl not authenticated`) and the fix (install `xurl`, or run `xurl auth`).
  Sections 1–4 and the Overview proceed unaffected.
- **X API errors or rate limits:** render Section 5 with whatever slices returned,
  marking the missing ones ⚠️. If only the account fetch succeeded, Section 5 carries
  the follower line and the snapshot anchor alone — the anchor is emitted whenever the
  account fetch succeeds, so a failed posts fetch never breaks the *next* run's delta —
  and Section 6 is skipped with a ⚠️, because recommendations without performance data
  would be ungrounded.
- **Window longer than 30 days:** Section 5 renders from `public_metrics` only. The
  engagements, engagement-rate, profile-clicks and link-clicks rows are marked ⚠️ *not
  available beyond 30 days*. This is an X platform limit, not an auth problem.
- **No prior review carrying an `x-snapshot` anchor:** the follower line reads
  *baseline — no prior figure recorded*. This is not an error and is not marked ⚠️.

### Retired orchestration

The previous version of this command orchestrated four skills that are **no longer
called** by `/review`: `performance-scorecard`, `calendar-audit`, `delegation-tracker`,
`refocus-directive`. They remain in `skills/` for ad-hoc invocation. Before deleting any
of them, confirm no other command (`goals`, `reflect`, `plan`) or the `cob` schedule
depends on them.
