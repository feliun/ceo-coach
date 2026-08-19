# Design — Twitter/X performance in `/review`

**Date:** 2026-08-18
**Status:** Approved, pending implementation plan
**Target version:** ceo-coach 1.5.0

---

## 1. Goal

Extend `/review` with reporting on the user's X/Twitter activity for the review
window, and with content recommendations aimed at growing followers among a
technical audience while the user represents an AI-native software consultancy
(Orbitant).

Two new sections:

| Section | Nature | Placement |
|---------|--------|-----------|
| `## 5. Twitter performance` | Descriptive — same neutral tone as §1–4 | After §4 |
| `## 6. Content recommendations` | Prescriptive | After §5, before the Overview |

The split exists because `CLAUDE.md` mandates *"Describe before interpreting"* —
sections are neutral and factual, interpretation is confined to the Overview.
Recommendations are neither descriptive nor a synthesis over the other sections,
so they get their own clearly prescriptive section rather than contaminating §5
or being buried in the Overview.

---

## 2. Feasibility — verified against the live X API

All probes below were run on 2026-08-18 with the installed `xurl` CLI
(`/usr/local/bin/xurl`, app `prod-app`, OAuth2 user context as
`@felipepoloruiz`, user id `27666664`).

### 2.1 What works

**Per-post metrics.** This exact query returned 34 posts for a 7-day window with
every requested field populated:

```
xurl "/2/users/{id}/tweets?max_results=100\
&start_time={ISO8601}&end_time={ISO8601}\
&tweet.fields=created_at,public_metrics,organic_metrics,non_public_metrics,\
referenced_tweets,conversation_id,in_reply_to_user_id,note_tweet,lang"
```

Available per post:

| Field group | Metrics |
|---|---|
| `public_metrics` | `impression_count`, `like_count`, `reply_count`, `retweet_count`, `quote_count`, `bookmark_count` |
| `organic_metrics` | `impression_count`, `like_count`, `reply_count`, `retweet_count`, `url_link_clicks`, `user_profile_clicks` |
| `non_public_metrics` | `impression_count`, `engagements`, `url_link_clicks`, `user_profile_clicks` |
| Classification | `referenced_tweets[].type` (`replied_to` / `quoted` / absent = original), `conversation_id`, `in_reply_to_user_id`, `lang`, `note_tweet`, `article.title` |

`conversation_id` and `in_reply_to_user_id` were probed separately and both
populate correctly — together they make self-reply threads distinguishable from
replies to other people inside the same conversation, which `referenced_tweets`
alone cannot do.

**Account metrics.**

```
xurl "/2/users/me?user.fields=public_metrics,description"
```

Returns `followers_count`, `following_count`, `tweet_count`, `media_count`,
`listed_count`, and `description` (the bio).

**Rate limits.** `X-Rate-Limit-Limit: 1000000` on the observed endpoints.
Pagination is not a practical constraint.

### 2.2 What does not work

| Want | Status |
|---|---|
| Profile visits | **Unavailable.** X API v2 exposes no profile-visits metric. `/2/users/{id}/analytics` errors on this app tier. True profile visits exist only in the X Analytics dashboard. |
| Follower/unfollower deltas | **No delta endpoint.** `/2/users/{id}/followers` and `/following` paginate fine, but computing a delta requires storing a prior snapshot. |
| `organic_metrics` / `non_public_metrics` beyond ~30 days | **Not returned by X.** A documented platform limitation, not an auth issue. |

### 2.3 Resolutions adopted

- **Profile visits → profile-clicks proxy.** Report the summed
  `user_profile_clicks` across the window's posts, explicitly labelled as an API
  proxy with a ⚠️ pointing at the dashboard as the only true source. Fully
  automated; no manual input path.
- **Follows/unfollows → net counts only.** Report net follower change with no
  names, using the previous review file as the prior value. No snapshot file,
  no follower-list pagination.
- **>30-day windows.** Degrade to `public_metrics` only and mark the section ⚠️.

---

## 3. Architecture

### 3.1 Where the fetching lives

A new dedicated agent, `agents/twitter-analyst.md`, dispatched **in parallel**
with the existing `performance-analyst` (both in a single message, two tool
calls).

Rejected alternatives:

- **A new §9 slice inside `performance-analyst`.** That agent is also consumed by
  the ad-hoc `performance-scorecard`, `calendar-audit` and `refocus-directive`
  skills, none of which have any use for X data. Bolting the slice on would make
  every consumer pay for output it discards.
- **Inline `xurl` calls in `commands/review.md`.** Dumps raw tweet JSON into the
  main context and breaks the established pattern that data gathering happens in
  an agent.

The dedicated agent also isolates a failure mode the other sources do not share:
`xurl` missing from `PATH`, or present but unauthenticated.

### 3.2 State: the review files are the state

The net follower delta needs a prior figure. Rather than introduce a snapshot
file, §5 emits a machine-parseable HTML comment as its last line:

```
<!-- x-snapshot: followers=1555 following=1166 at=2026-08-18 -->
```

On each run the command scans `records/logs/weekly/` for review files (basename
does **not** start with `plan-`), takes the most recent one dated before the
current window's end date, and greps that anchor for `followers=(\d+)`.

- Anchor found → report the net delta and wikilink the source review.
- No prior review, or no anchor in it → report *baseline — no prior figure
  recorded* and emit the anchor for next time.

Rationale: zero new files, zero new manifest keys, and the value is visible in
the same document a human reads. The HTML comment (rather than parsing prose)
keeps the parse target stable against later prose edits.

### 3.3 Configuration: one optional manifest key

Identity, follower counts, and positioning all come from `xurl /2/users/me`. The
bio is the positioning source — the user's reads *"CEO en Orbitant. Padre de 2.
Emprendimiento y tecnología. Construyendo una consultora de software AI Native."*
— which keeps the plugin portable without a config file to fill in.

One key is added, because §5 and §6 link posts to their vault notes where those
exist (§3.4):

```yaml
  tweets:
    description: "Directory of pulled X/Twitter post notes, one per post, named {tweet_id}.md"
    paths:
      - $WORKSPACE/records/tweets/
    required: false
    format: directory
    note: "Populated by wiki-manager's /pull-tweets. When absent, §5 and §6 link posts to x.com instead."
```

Optional by design: the plugin must work for a user who has no such vault
folder, and the fallback is lossless — an x.com URL instead of a wikilink.

### 3.4 Post references: vault note first, x.com as fallback

Every reference to a post — in the §5 table and in §6's prose alike — resolves in
this order:

1. **`records/tweets/{tweet_id}.md` exists** → wikilink it, aliased to the
   snippet: `[[2088289040139173943|Uno de los tips profesionales…]]`. Posts are
   vault objects like meetings and daily notes, so they should behave like them:
   clickable inside Obsidian, backlinked from the post note, and traversable
   without leaving the vault.
2. **No such file** → the markdown link to `https://x.com/{username}/status/{id}`.

The vault folder is flat and named by immutable tweet id, so the lookup is a
single `os.path.exists` per post with no scanning or fuzzy matching.

Mixed output is normal and expected: `/pull-tweets` defaults to a 7-day window,
so a `--window 30d` review will link recent posts to notes and older ones to
x.com. Both forms may appear in the same table; neither is an error and neither
is marked ⚠️.

---

## 4. Component: `agents/twitter-analyst.md`

Follows the structure of `agents/performance-analyst.md`: frontmatter with
`name` / `description` / `subagent_type: general-purpose`, then Role, Input,
Data to Fetch, Output, Resilience.

### 4.1 Input

| Variable | Description |
|---|---|
| `window_days` | Number of days to look back |
| `target_date_iso` | End date, `YYYY-MM-DD` |
| `tweets_folder` | Absolute path to the resolved `tweets` directory, or null when the manifest key resolves nowhere |

No `username` input — resolved from `/2/users/me`.

Resolving the note per post belongs here rather than in the command, mirroring
`performance-analyst`, which already returns meeting-note basenames and a
`note: null` for meetings that have none.

### 4.2 Preflight

1. `command -v xurl` — if absent, return the unavailable report (§4.6) with
   reason `xurl not installed`.
2. `xurl /2/users/me` — if it errors or returns no `data.id`, return the
   unavailable report with reason `xurl not authenticated`.

Never prompt for credentials, never attempt an auth flow.

### 4.3 Fetch 1 — account

```
xurl "/2/users/me?user.fields=public_metrics,description"
```

Extract `id`, `username`, `description`, `followers_count`, `following_count`,
`tweet_count`.

### 4.4 Fetch 2 — posts in the window

```
xurl "/2/users/{id}/tweets?max_results=100\
&start_time={target_date - window_days}T00:00:00Z\
&end_time={target_date}T23:59:59Z\
&tweet.fields=created_at,public_metrics,organic_metrics,non_public_metrics,\
referenced_tweets,conversation_id,in_reply_to_user_id,note_tweet,lang"
```

Paginate while `meta.next_token` is present, appending
`&pagination_token={next_token}`. Cap at 10 pages as a runaway guard; if the cap
is hit, note how many posts were not fetched.

### 4.5 Derivations

**Per post:**

| Derived field | Rule |
|---|---|
| `url` | `https://x.com/{username}/status/{id}` |
| `vault_note` | `{tweet_id}` when `{tweets_folder}/{tweet_id}.md` exists, else `null`. Null is a normal result, not a warning — the consumer falls back to `url` per §3.4. Always `null` when `tweets_folder` is null. |
| `type` | Exactly one value, assigned by this precedence, first match wins: `article` if the post carries an `article` object → `reply` if `referenced_tweets` contains `replied_to` → `quote` if it contains `quoted` → `original` otherwise. Mutually exclusive by construction, so the type counts always sum to the post total. |
| `self_reply` | `true` when `type == reply` and `in_reply_to_user_id` equals the account's own id. Distinguishes a self-authored thread continuation from a reply to someone else. |
| `thread_id` | `conversation_id`, used only for grouping. A **thread** is a set of two or more of the account's own posts sharing one `conversation_id` where every post after the first is a `self_reply`. Threads are reported as a grouping in the breakdowns, not as a `type`. |
| `impressions` | `organic_metrics.impression_count`, falling back to `public_metrics.impression_count` |
| `engagements` | `non_public_metrics.engagements`, falling back to the sum of likes + replies + retweets + quotes + bookmarks. **X counts detail expands and clicks here, not just visible interactions** — a dry-run post showed 3,474 engagements against 348 visible ones. §5 must carry a note saying so, or readers will misread the engagement rate. |
| `engagement_rate` | `engagements / impressions`, as a percentage to one decimal; `n/a` when impressions is 0 |
| `profile_clicks` | `non_public_metrics.user_profile_clicks` |
| `link_clicks` | `non_public_metrics.url_link_clicks`. **The field is frequently absent even for posts that do carry links** (confirmed in the 2026-08-18 dry run: 0 of 21 posts returned it, including two with `t.co` links). Absent is not zero — render the row as ⚠️ *not returned* rather than `0`, which would falsely assert nobody clicked. |

**Aggregate:**

- Totals across the window: posts, impressions, engagements, likes, replies,
  retweets, quotes, bookmarks, link clicks, profile clicks.
- Window engagement rate: total engagements / total impressions.
- Median impressions and median engagement rate (medians, not means — the
  distribution is heavily skewed; a single 22k-impression post distorts a mean).
- Top 3 by impressions; top 3 by engagement rate among posts with ≥100
  impressions (the floor prevents a 12-impression reply with one like from
  ranking first); bottom 3 by impressions among originals.
- Split by `type`: count, impressions, engagements, median engagement rate. Since
  types are mutually exclusive, the counts must sum to the post total — a
  mismatch is a bug, not a rounding artefact.
- Threads: count of threads, posts per thread, combined impressions. Also report
  replies split into self-replies (thread continuations) and replies to others,
  since the two are different activities that the raw reply count conflates.
- Split by `lang`: count and impressions.
- Cadence: posts per calendar day; list days in the window with zero posts.

### 4.6 Output

A structured report mirroring `performance-analyst`'s style:

```
## Twitter Analyst Report

Window: {start} → {end} ({N} days)
Account: @{username} · {followers} followers · {following} following
Bio: {description}
Metrics tier: organic + non-public / public-only ⚠️ (window exceeds 30 days)

### Totals
- Posts: N (originals: N, replies: N [self: N, to others: N], quotes: N, articles: N)
- Threads: N (spanning N posts)
- Impressions: N · Engagements: N · Engagement rate: X%
- Likes: N · Replies: N · Retweets: N · Quotes: N · Bookmarks: N
- Link clicks: N · Profile clicks: N
- Median impressions: N · Median engagement rate: X%

### Posts
[{id, url, vault_note, created_at, type, self_reply, thread_id, lang, impressions,
  engagements, engagement_rate, likes, replies, retweets, quotes, bookmarks,
  link_clicks, profile_clicks, text (first 120 chars), article_title (if any)}]

### Breakdowns
- By type: [{type, count, impressions, engagements, median_engagement_rate}]
- Threads: [{thread_id, posts, combined_impressions}]
- Replies: self N / to others N
- By language: [{lang, count, impressions}]
- Cadence: [{date, posts}] · Silent days: [list]
- Top by impressions: [3]
- Top by engagement rate (≥100 impressions): [3]
- Bottom originals by impressions: [3]

### Sources
| Source | Status | Details |
|--------|--------|---------|
| X account | ✅ / ⚠️ | |
| X posts   | ✅ / ⚠️ | {pages fetched, metrics tier} |
```

**Unavailable report** — when preflight fails or both fetches error:

```
## Twitter Analyst Report

Status: UNAVAILABLE ⚠️
Reason: {xurl not installed | xurl not authenticated | API error: <detail>}
```

### 4.7 Resilience

- Account fetch and posts fetch are independent; one failing does not block the
  other. A successful account fetch with a failed posts fetch still yields the
  follower count for §5.
- Retry a failed fetch once, then give up and mark ⚠️.
- On HTTP 429, report the rate-limit reset time rather than retrying in a loop.
- Never analyse, score, or recommend — that belongs to the command.

**Vault traversal note (applies to the command, not the agent).** In this vault
`records/meetings/` is a **symlink** to Google Drive. Any directory walk that
resolves §6's citations must follow symlinks (`os.walk(..., followlinks=True)`,
or shell `ls`/`find -L`); a default `os.walk` silently reports every meeting
wikilink as broken. This bit the dry run's own verification script.

---

## 5. Changes to `commands/review.md`

### 5.1 Step 1 — Manifest resolution

Unchanged. Still resolves `rocks` (required) and `weekly-plans` (optional). Add
a note that `weekly-plans` now also serves as the follower-snapshot source for
§5, so its absence downgrades the delta to *baseline* rather than blocking.

### 5.2 Step 2 — Gather behavioral data

Dispatch **two agents in parallel, in a single message**:

- `performance-analyst` — as today, four consumed slices.
- `twitter-analyst` — with `window_days` and `target_date_iso`.

State explicitly that a `twitter-analyst` failure must not block §1–4.

### 5.3 Step 3 — Assemble the descriptive sections

Retitle from "the four descriptive sections" to "the five descriptive sections".
Sections 1–4 unchanged. Wikilink rules gain one entry:

- **Posts** → wikilink to their vault note by tweet id when
  `records/tweets/{tweet_id}.md` exists, aliased to the snippet; otherwise the
  markdown link to the `x.com` URL. See §3.4.

Add the §5 subsection specified in §6 of this document.

### 5.4 Step 3b — Section 6 (new step, prescriptive)

Add the §6 subsection specified in §7 of this document, explicitly flagged as
the one place in the review that prescribes rather than describes, and generated
**before** the Overview.

### 5.5 Step 4 — Overview

Now synthesises over five descriptive sections rather than four. The Overview
may reference §5 where content activity converges with the calendar, the rocks,
or the journaling — but it must not restate §6's recommendations. §6 is not an
input to the Overview.

### 5.6 Step 5 — Template

```markdown
## 5. Twitter performance
{Section 5}

## 6. Content recommendations
{Section 6}

## Overview — how the week went
{Interpretive synthesis + main highlights, generated last}
```

### 5.7 Step 6 — Report block

Add one line:

```
X / Twitter:   {N} posts · {M} impressions · {X}% eng · {F} followers ({±D})
```

When the analyst was unavailable: `X / Twitter:   ⚠️ unavailable ({reason})`.

### 5.8 Fallbacks & resilience

Add to the existing list:

- **`xurl` missing or unauthenticated:** omit §5 and §6 entirely, replacing each
  with a single ⚠️ line naming the reason and the fix
  (`brew install xurl` / `xurl auth`). Sections 1–4 and the Overview proceed
  unaffected.
- **X API errors or rate-limits:** render §5 with whatever slices returned,
  marking the missing ones ⚠️. If only the account fetch succeeded, §5 carries
  the follower line and the snapshot anchor alone — the anchor is emitted
  whenever the account fetch succeeds, so a bad posts fetch never breaks the next
  run's delta — and §6 is skipped with a ⚠️ (recommendations without performance
  data would be ungrounded).
- **Window > 30 days:** §5 renders with `public_metrics` only; the engagements,
  profile-clicks and link-clicks rows are marked ⚠️ *not available beyond 30
  days*.
- **No prior review file with an `x-snapshot` anchor:** the follower line reads
  *baseline — no prior figure recorded*. Not an error.

---

## 6. Specification — `## 5. Twitter performance`

Descriptive. Same register as §1–4: report, do not grade. No "you should", no
drift-shaming, no praise.

**Source line:**

```
*Source: X API v2 via the `xurl` CLI (OAuth2 user context, @{username}) —
organic and non-public metrics.*
```

**Contents, in order:**

1. **Headline paragraph** — `**{N} posts · {M} impressions · {E} engagements ·
   {X}% engagement rate.**` followed by the originals/replies/quotes split.

2. **Totals table** — one row per metric: impressions, engagements, engagement
   rate, likes, replies, retweets, quotes, bookmarks, link clicks. Include
   median impressions and median engagement rate as separate rows, since the
   distribution is skewed.

3. **Followers line:**

   ```
   **Followers: {N}** — net {±D} vs {prior} recorded in [[DD-MM-YYYY]]. Following: {N}.
   ```

   First run: `**Followers: {N}** — baseline, no prior figure recorded.`

   **As-of caveat.** X exposes no historical follower series, so the count is
   always point-in-time at *run* time, not at window close. When the run date is
   later than the window end — any backfilled or late review — append a ⚠️
   naming both dates. Silently presenting a run-time count as the window-close
   figure would misattribute growth to the wrong week.

4. **Profile clicks line:**

   ```
   **Profile clicks from posts: {N}** — ⚠️ API proxy. X does not expose total
   profile visits; the X Analytics dashboard is the only source for that.
   ```

5. **Per-post table**, sorted by impressions descending, every row linking its
   post:

   | Date | Type | Impressions | Eng. | Eng. rate | Post |
   |---|---|---|---|---|---|

   The `Post` cell holds the first ~60 characters as the link text, resolved per
   §3.4 — `[[{tweet_id}|snippet]]` when the vault note exists, the `x.com`
   markdown link otherwise. Article posts show the article title instead.

   **Inclusion rule.** Replies are the bulk of the volume and most of them are
   conversational one-liners, so an unfiltered table would bury the signal. The
   table lists **every** original, quote, article, and self-reply, plus any reply
   to others with ≥100 impressions. Everything excluded is accounted for in a
   single trailing line, so nothing is silently dropped:

   ```
   *Plus {N} replies below 100 impressions ({M} impressions, {E} engagements combined).*
   ```

6. **Observations** — a handful of plain factual bullets, chosen from what the
   data actually supports:
   - the original-vs-reply split in volume against the same split in impressions
   - threads posted, and how their combined reach compared to single originals
   - the spread between the top post and the median
   - days in the window with no posts
   - language mix, when more than one language appears
   - the best and worst performing originals, by number

   No causal claims. "Originals were 35% of volume and 78% of impressions" is in
   register; "you should post more originals" is not — that belongs to §6.

7. **Snapshot anchor**, as the section's final line:

   ```
   <!-- x-snapshot: followers={N} following={N} at={YYYY-MM-DD} -->
   ```

---

## 7. Specification — `## 6. Content recommendations`

The one prescriptive section in the review. Grounded in §5's performance data
crossed with the week's raw material from §1–4, the X bio, and `rocks.yaml`.

**Source line:**

```
*Source: §5 performance data crossed with this window's calendar, completed
work, journaling, and meeting themes. Positioning from the X bio and
`rocks.yaml`.*
```

**Contents, in order:**

1. **What worked** — 2–3 bullets, each naming a specific post with its real
   numbers and the attribute that plausibly drove it (format, hook, topic,
   language, specificity). Attribute cautiously: with a handful of posts these
   are hypotheses, and the section should say so once rather than assert
   causation per bullet.

2. **What didn't** — 2–3 bullets, same discipline. Include the cost of any
   pattern the data shows to be low-yield.

3. **Post ideas — 5 to 7**, each rendered as:

   ```
   **{Working title}**
   - *Angle:* {the specific claim or story}
   - *From:* {evidence, wikilinked — [[DD-MM-YYYY]] or [[YYYY-MM-DD slug]]}
   - *Format:* text / thread / article / quote-with-take / poll
   - *Mechanism:* bookmarkable insight / contrarian take / build-in-public
     number / teardown / question that invites replies
   ```

   Framing constraints, applied to every idea:
   - **Audience:** technical — engineers, CTOs, founders. Concrete over
     abstract; a real number or a real decision beats a general observation.
   - **Positioning:** the user runs an AI-native software consultancy. Ideas
     should demonstrate competence through specifics of the work, not advertise
     services. What Orbitant *learned* is content; what Orbitant *sells* is not.
   - **Goal:** follower growth. Prefer angles that give a stranger a reason to
     follow — a repeatable point of view, an ongoing build, a source of numbers
     nobody else publishes.

4. **What not to post** — at most one or two bullets, and only when §5's data
   supports it. Omit the subsection rather than pad it.

Posts named anywhere in §6's prose — in *What worked*, *What didn't*, *What not
to post*, or inside an idea's *From:* line — are linked by the same §3.4 rule as
§5's table. A post mentioned by description alone, with no link, is a defect: the
reader cannot check the claim against the post.

**Hard rules:**

- Every idea traces to cited evidence from the window, or is explicitly labelled
  *(evergreen — not from this window)*. Never invent an event, a meeting, a
  number, or a customer.
- Never propose a post that would disclose client-confidential material. Meeting
  notes are a source of *themes*, not of quotable client detail.
- Cap at 7 ideas. If the window's raw material only supports 3, produce 3 and
  say the window was thin. Padding to a quota fabricates.

---

## 8. Documentation and version changes

**`CLAUDE.md`**

- *Core Responsibilities* — extend item 1 to name six sections, and add Twitter
  performance and content recommendations to the descriptive-review description.
- *Components* — add the `twitter-analyst` agent row.
- *Operational Rules* — extend **Cite the source** to cover post links, and add
  a rule that profile visits are unavailable from the API and must always be
  reported as the labelled proxy, never as "profile visits".
- Note under `/review`'s reference-file line that it resolves no additional
  config for X data.

**`README.md`**

- `/review` row — mention the two new sections.
- *Agents* table — add `twitter-analyst`.
- *Setup* — note that §5/§6 require the `xurl` CLI authenticated with OAuth2
  user context, and that the plugin degrades gracefully without it.

**Version** — `1.5.0` (new user-facing capability, backward compatible) in both
`.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`, which are
kept in sync per commit `bea90fd`.

---

## 9. Verification

This is a prompt-only plugin with no test framework, so verification is a live
run:

1. Run `/review --window 7d` against the live vault.
2. Reconcile §5's totals against a direct `xurl` call for the same window — post
   count, total impressions, and follower count must match exactly.
3. Confirm §5's observations contain no prescriptive language and §6's ideas each
   carry a `From:` citation that resolves to a real vault note.
4. Confirm the `x-snapshot` anchor is present and correctly formatted.
5. Simulate failure by running the agent with `xurl` shadowed off `PATH`; confirm
   §1–4 and the Overview render unaffected and §5/§6 collapse to ⚠️ lines.
6. Run `/review --window 45d` and confirm the >30-day degradation path marks the
   affected rows ⚠️ instead of reporting zeros.

Step 2's reconciliation is the one that matters most: a section that silently
under-counts posts would be worse than no section.

---

## 10. Explicitly out of scope

- Snapshot files, follower-list pagination, and named gained/lost followers.
- Any coupling to the `content-editor` plugin's voice or pillar references.
- New config files. (One optional manifest key, `tweets`, is added — see §3.3.)
- Posting, scheduling, or drafting actual tweet copy. §6 produces angles and
  briefs, not finished posts.
- Bookmarks, mentions, DMs, and the home timeline.
- Backfilling §5 into existing review files.
