---
name: ceo-coach:review
description: >
  Descriptive weekly review for a configurable time window. Aggregates five lenses —
  time allocation (calendar), progress (completed tasks + rocks), fleeting thoughts
  (daily-note journaling), relevant info (meeting transcripts), and X/Twitter
  performance — then adds content recommendations, a Referencias appendix aggregating
  every file the vault gained in the window, and synthesizes an interpretive Overview.
  Period-agnostic — the user decides when to run it.
---

## Command: ceo-coach:review

Produces a **descriptive** weekly review: five neutral "here's what happened" lenses,
one prescriptive section of content recommendations, a Referencias appendix listing
everything the vault gained, and a single interpretive Overview. This command deliberately does NOT score, audit the calendar against rules,
or issue a refocus directive — it reports and synthesizes, it does not grade. Section 6
is the sole exception: it prescribes, and it is fenced off from the descriptive
sections and from the Overview for exactly that reason. (The scoring/audit/delegation/refocus skills still
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
resolved `rocks` path for the window. This command only consumes five of its slices:

- **Calendar events** for the window → Section 1
- **Tasks completed** in the window → Section 2
- **Daily logs** (the `# Journaling` and `# Free Thinking` sections) → Section 3
- **Meeting notes** from the window → Section 4
- **Daily logs** (the `# Files Created` blocks, verbatim) → Section 7

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
failure **must not block** Sections 1–4, Section 7 or the Overview: on failure, render
the ⚠️ lines described under *Fallbacks & resilience* and continue.

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

#### 3b. Assemble Section 6 — Content recommendations

This is **the one prescriptive section** in the review, and the single exception to
the describe-before-interpret rule. Generate it after Sections 1–5 exist and
**before the Overview**. It is a sibling of the Overview, not an input to it:
**Section 6 is not an input to the Overview**, and the Overview must not restate its
recommendations.

Grounded in Section 5's performance data crossed with the window's raw material from
Sections 1–4, the account bio returned by `twitter-analyst`, and `rocks.yaml`. Open
with:

```
*Source: §5 performance data crossed with this window's calendar, completed work, journaling, and meeting themes. Positioning from the X bio and `rocks.yaml`.*
```

Then state once, not per bullet, that with a handful of posts the attributions are
**hypotheses** rather than conclusions.

Contents, in order:

1. **What worked** — 2–3 bullets, each naming a specific post with its real numbers
   and the attribute that plausibly drove it (format, hook, topic, language,
   specificity).

2. **What didn't** — 2–3 bullets, same discipline, including the cost of any pattern
   the data shows to be low-yield.

3. **Post ideas — 5 to 7**, each rendered as:

   ```
   **{Working title}**
   - *Angle:* {the specific claim or story}
   - *From:* {evidence, wikilinked — [[DD-MM-YYYY]] or [[YYYY-MM-DD slug]]}
   - *Format:* text / thread / article / quote-with-take / poll
   - *Mechanism:* bookmarkable insight / contrarian take / build-in-public number / teardown / question that invites replies
   ```

   Framing constraints, applied to every idea:
   - **Audience:** **technical** — engineers, CTOs, founders. Concrete over abstract;
     a real number or a real decision beats a general observation.
   - **Positioning:** taken from the **X bio** returned by the analyst, plus
     `rocks.yaml`. Demonstrate competence through specifics of the work rather than
     advertising services — what the company *learned* is content, what it *sells*
     is not.
   - **Goal:** follower growth. Prefer angles that give a stranger a reason to follow:
     a repeatable point of view, an ongoing build, numbers nobody else publishes.

4. **What not to post** — at most one or two bullets, and only when Section 5's data
   supports it. Omit the subsection rather than pad it.

**Hard rules:**

- Every idea traces to cited evidence from the window, or is explicitly labelled
  *(evergreen — not from this window)*. **Never invent** an event, a meeting, a
  number, or a customer.
- Meeting notes are a source of *themes*, not of quotable client detail. Any idea
  drawn from a client conversation carries an explicit ⚠️ **anonymise** note stating
  what must be stripped — client name, identifying technical detail, named people.
- Posts named anywhere in this section's prose are linked by the same rule as
  Section 5's table. **A post mentioned by description alone**, with no link, is a
  defect — the reader cannot check the claim against the post.
- **Cap at 7** ideas. If the window's raw material supports only 3, produce 3 and say
  the window was thin. Padding to a quota fabricates.

#### 3c. Assemble Section 7 — Referencias

The window's bibliography: every file the vault gained, aggregated from the
`# Files Created` sections that `/cob` Phase B1 writes into each daily note.
**Descriptive**, like Sections 1–5 — it lists what was created, it does not interpret
it, and it never editorializes about volume ("a productive week", "output dropped" are
both out of register; that reading, if any, belongs to the Overview).

Render it in the same language as the rest of the review.

**Source, and only source.** The `# Files Created` blocks returned verbatim by
`performance-analyst` §5, one per daily note in the window. Do **not** re-run Phase B1's
filesystem birth-time sweep here. Phase B1 already reconciled that sweep against the
agents' own created-file lists on the day itself; re-running it at review time would
sweep *the filesystem as it stands now*, pulling in every file created between the
window end and the run date — the same backfill error that forces the ⚠️ on the follower
line in Section 5. If a day's creations never made it into its daily note, they are
absent from this section; report the gap rather than going around it.

Open with the source line:

```
*Source: the `# Files Created` sections of the window's daily notes ({N} of {M} window days have one), written by `/cob`. Meeting notes and the daily notes themselves are excluded at capture time — meetings are Section 4's subject.*
```

Then, in order:

1. **Headline.** `**{N} files created across {D} days.**` Count enumerated entries only
   — see the collapsed-line rule below.

2. **The list, grouped by folder.** Folder groups sorted alphabetically, entries within
   a group sorted by date then title, each followed by the day it was logged:

   ```markdown
   **wiki/company/** (12)
   - [[2026-11-18 Runbook de demo de Mercuria]] — [[18-11-2026]]
   ```

   Each entry keeps the wikilink **exactly as the daily note wrote it**, alias included.
   `raw/telegram/` files are named `DD-MM-YYYY-NNN` and `raw/twitter/bookmarks/` files
   by tweet ID; Phase B1 aliases those at capture time precisely because a bare ID tells
   the reader nothing, and dropping the alias here would undo that. Never re-alias,
   repair or "resolve" a link: one that is broken in the daily note stays broken here,
   because silently fixing it hides a real defect in the capture pipeline.

3. **Dedupe by link target.** The same note can be logged on two days — a file created
   near midnight, or re-indexed by a later `/cob` run. List it **once**, under its
   earliest day, and append the others: `— [[18-11-2026]], [[19-11-2026]]`. Count it
   once in the headline.

4. **Collapsed count lines pass through.** Phase B1 collapses any folder that
   contributed more than 10 files in a single day into one count line
   (`- 21 posts propios de X (semana 10–16 oct)`). Carry the line through verbatim with
   its day attribution, under its folder group, and **keep it out of the headline
   total**: those files are enumerated nowhere, so counting the line as 1 understates
   the window and counting it as 21 asserts links that do not exist. Account for them in
   one trailing line instead:

   ```
   *Plus {N} collapsed count lines covering roughly {M} files not listed individually.*
   ```

5. **Account for every day in the window.** Three states, three different facts, each
   reported separately — never merged:

   ```
   *No files created on: [[26-10-2026]], [[27-10-2026]], [[02-11-2026]].*
   *No daily note for: 24-10-2026, 25-10-2026.*
   *⚠️ Daily note present but no `# Files Created` section: [[DD-MM-YYYY]] — `/cob` did not run that day, so creations from it are missing from this list.*
   ```

   An empty section means `/cob` ran and found nothing. An absent section means nothing
   ran and the day is **unknown**, not empty. Only the third line carries ⚠️, and it is
   the only ⚠️ this section can raise.

   **Dates on the no-daily-note line are plain text, never wikilinks** — the note does
   not exist, so a `[[DD-MM-YYYY]]` there would plant an unresolved link in the graph
   for every uncovered day. Same rule Section 4 applies to meetings without a note. The
   other two lines link normally; their notes exist.

6. **Whole window empty.** When no day produced a file, the section is the source line
   plus `*No files created in this window.*` — then stop. Keep the day-accounting lines
   above it; they are what distinguish a quiet window from an unrun pipeline.

**Section 7 is not an input to the Overview.** Like Section 6, it sits beside the
synthesis, not inside it. The Overview draws on Sections 1–5 only — it must not count
files, name folders, or read productivity into this list.

#### 4. Synthesize the Overview (generated LAST, placed LAST)

After Sections 1–5 exist, write a short **Overview** as the final section (it is
written last and placed last, after Sections 6 and 7). This is the
one interpretive part of the review — a synthesis *over* the four data sections, not an
independent fetch. It must:
- Characterize the week in a sentence or two (e.g. "a strategy-and-alignment week, not a
  shipping week").
- Name **cross-section convergence** — where the calendar, the rocks, and the journaling
  point at the same story. This is the Overview's main job; no single section shows it
  alone.
- List the **main highlights** (3–6 bullets), each wikilinked to its supporting
  meeting/daily note.
- Draw only on Sections 1–5. The Overview may note where content activity converges
  with the calendar, the rocks or the journaling, but **neither Section 6 nor Section 7
  is an input to the Overview** — its recommendations must not be restated there, and
  the file list must not be turned into a productivity verdict.

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

## 6. Content recommendations
{Section 6}

## 7. Referencias
{Section 7}

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
Referencias:   {N} files across {D} days · {M} days with no daily note
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
- **Detailed metrics missing on some or all posts:** Section 5 renders from
  `public_metrics` for those posts, and the engagements, engagement-rate,
  profile-clicks and link-clicks figures are marked ⚠️ *not available for {N} posts*.
  This is an X platform limit, not an auth problem. Two causes, and the section should
  name whichever applies: posts older than roughly **90 days** (measured, not the ~30
  the docs imply), and **retweets**, which never carry organic metrics at any age.
  Never render a missing metric as `0`.
- **Daily notes missing or without a `# Files Created` section:** Section 7 renders
  from whatever days do have one and names the rest on its day-accounting lines. Never
  fill the gap with a live filesystem sweep (see Section 7's source rule) and never
  infer creations from `created:` frontmatter — that field is the **capture** date, not
  the write date, so a note written today from a three-day-old bookmark carries the old
  date. An absent section is reported as unknown, not as zero.
- **The whole window predates `/cob` Phase B1** (no daily note in the window has a
  `# Files Created` section): render Section 7 as a single ⚠️ line naming the reason,
  and continue. It never blocks the other sections or the Overview.
- **No prior review carrying an `x-snapshot` anchor:** the follower line reads
  *baseline — no prior figure recorded*. This is not an error and is not marked ⚠️.

### Retired orchestration

The previous version of this command orchestrated four skills that are **no longer
called** by `/review`: `performance-scorecard`, `calendar-audit`, `delegation-tracker`,
`refocus-directive`. They remain in `skills/` for ad-hoc invocation. Before deleting any
of them, confirm no other command (`goals`, `reflect`, `plan`) or the `cob` schedule
depends on them.
