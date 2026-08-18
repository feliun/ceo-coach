# Twitter Performance in `/review` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a descriptive `## 5. Twitter performance` section and a prescriptive `## 6. Content recommendations` section to `/review`, fed by a new `twitter-analyst` agent that reads the X API through the `xurl` CLI.

**Architecture:** A dedicated `agents/twitter-analyst.md` is dispatched in parallel with the existing `performance-analyst` (two tool calls in one message). It makes exactly two X API calls — `/2/users/me` for account metrics and positioning, and a windowed `/2/users/:id/tweets` for post metrics — and returns structured data. `commands/review.md` renders that data into §5 (neutral) and §6 (prescriptive). Net follower deltas use an HTML-comment anchor in the previous review file as state; no snapshot file exists.

**Tech Stack:** Markdown prompt files. `xurl` CLI (OAuth2 user context) for the X API v2. YAML manifest for config resolution. No application code, no test framework.

**Spec:** `docs/superpowers/specs/2026-08-18-twitter-performance-review-design.md` — read it alongside this plan; every task argues from it.

## Global Constraints

Copied verbatim from the spec. Every task's requirements implicitly include these.

- **Auth:** all X access goes through the `xurl` CLI under OAuth 2.0 user context. Never prompt for credentials, never attempt an auth flow, never read or print a token.
- **30-day metrics ceiling:** X returns `organic_metrics` / `non_public_metrics` only for posts under ~30 days old. Longer windows degrade to `public_metrics` and mark ⚠️.
- **Profile visits do not exist in the API.** Only `user_profile_clicks` (clicks from posts). It must always be labelled a proxy, never presented as "profile visits".
- **Follower tracking is net counts only.** No follower-list pagination, no named gained/lost followers, no snapshot file.
- **Follower counts are point-in-time at run time.** When run date ≠ window end, both dates must be shown.
- **`url_link_clicks` absent ≠ zero.** Render ⚠️ *not returned*, never `0`.
- **`engagements` includes detail expands and clicks**, not just visible interactions. §5 must say so.
- **§5 is descriptive; §6 is prescriptive.** No "you should" in §5. §6 is the only prescriptive section in the review.
- **Post links:** wikilink `[[{tweet_id}|snippet]]` when `records/tweets/{tweet_id}.md` exists, else the markdown `x.com` link. Mixed output is expected, never ⚠️.
- **Vault traversal must follow symlinks** — `records/meetings/` is a symlink to Google Drive.
- **Never invent.** Every §6 idea traces to cited evidence in the window or is labelled *(evergreen — not from this window)*. Client detail from meeting notes must be flagged for anonymisation.
- **Version 1.5.0**, kept identical in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
- **Failure is never fatal.** A `twitter-analyst` failure must not block §1–4 or the Overview.

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `agents/twitter-analyst.md` | Create | Fetch and structure X data. No analysis, no scoring, no recommendations. |
| `commands/manifest.yaml` | Modify | Add the optional `tweets` directory key. |
| `commands/review.md` | Modify | Parallel dispatch, §5 render spec, §6 render spec, template, report block, fallbacks. |
| `CLAUDE.md` | Modify | Responsibilities, components table, operational rules. |
| `README.md` | Modify | `/review` row, agents table, `xurl` setup note. |
| `.claude-plugin/plugin.json` | Modify | Version → 1.5.0. |
| `.claude-plugin/marketplace.json` | Modify | Version → 1.5.0. |

**Reference fixture.** The dry run of 2026-08-18 produced verified output for the 2026-08-08 → 2026-08-14 window, currently living in `records/logs/weekly/14-08-2026.md` §5–§6 of the vault. Its numbers were reconciled against an independent API call: **21 posts, 53,316 impressions, 4,354 engagements, 344 profile clicks, 6 originals / 15 replies, 0 threads.** Use it as the shape to match.

---

### Task 1: The `twitter-analyst` agent

**Files:**
- Create: `agents/twitter-analyst.md`
- Test: `docs/superpowers/plans/verify/task1.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: an agent named `twitter-analyst` accepting inputs `window_days`, `target_date_iso`, `tweets_folder`; returning a report whose headings are exactly `### Totals`, `### Posts`, `### Breakdowns`, `### Sources`, or a report whose second line is `Status: UNAVAILABLE ⚠️`. Task 3 and Task 4 parse these headings.

- [ ] **Step 1: Write the failing verification script**

```bash
mkdir -p docs/superpowers/plans/verify
cat > docs/superpowers/plans/verify/task1.sh <<'EOF'
#!/bin/bash
# Structural contract for agents/twitter-analyst.md
set -u
F=agents/twitter-analyst.md
fail=0
chk() { if grep -qF "$2" "$F"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
[ -f "$F" ] || { echo "FAIL file missing: $F"; exit 1; }
chk "frontmatter name"      "name: twitter-analyst"
chk "subagent type"         "subagent_type: general-purpose"
chk "input window_days"     "window_days"
chk "input target_date_iso" "target_date_iso"
chk "input tweets_folder"   "tweets_folder"
chk "preflight command -v"  "command -v xurl"
chk "account endpoint"      "/2/users/me?user.fields=public_metrics,description"
chk "posts endpoint"        "/2/users/{id}/tweets"
chk "field organic"         "organic_metrics"
chk "field non_public"      "non_public_metrics"
chk "field conversation_id" "conversation_id"
chk "field in_reply_to"     "in_reply_to_user_id"
chk "derived vault_note"    "vault_note"
chk "derived self_reply"    "self_reply"
chk "pagination guard"      "10 pages"
chk "link clicks not zero"  "absent is not zero"
chk "engagements caveat"    "detail expands"
chk "unavailable report"    "Status: UNAVAILABLE"
chk "no analysis rule"      "does not analyse"
chk "totals heading"        "### Totals"
chk "posts heading"         "### Posts"
chk "breakdowns heading"    "### Breakdowns"
chk "sources heading"       "### Sources"
# Must NOT prescribe
if grep -qiE "you should|recommend" "$F"; then echo "FAIL agent contains prescriptive language"; fail=1; else echo "ok   no prescriptive language"; fi
exit $fail
EOF
chmod +x docs/superpowers/plans/verify/task1.sh
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./docs/superpowers/plans/verify/task1.sh`
Expected: `FAIL file missing: agents/twitter-analyst.md`, exit 1.

- [ ] **Step 3: Write the agent**

Create `agents/twitter-analyst.md`. Match the register and section order of `agents/performance-analyst.md`.

````markdown
---
name: twitter-analyst
description: >
  Gather X/Twitter activity data for a review window. Fetches account metrics and
  every post the user published in the window, with organic and non-public
  engagement metrics, via the `xurl` CLI. Returns structured data for consumption
  by the `review` command. Fetches and structures only — never analyses, scores,
  or recommends.
subagent_type: general-purpose
---

# Agent: Twitter Analyst

**Role:** Fetch and structure the user's X/Twitter activity for a given time window. This agent gathers raw data — it does not analyse or score. Interpretation belongs to whatever consumes its output.

**Dispatched by:** `/review` command, in parallel with `performance-analyst`.

**Consumption note:** `/review` renders §5 (descriptive metrics) from the totals, posts and breakdowns, and §6 (content recommendations) from the same data crossed with the rest of the review. Return everything below regardless — a failure in one fetch must never block the other.

---

## Input

| Variable | Description |
|----------|-------------|
| `window_days` | Number of days to look back |
| `target_date_iso` | End date in YYYY-MM-DD format |
| `tweets_folder` | Absolute path to the resolved `tweets` directory, or null when the manifest key resolves nowhere |

No `username` input — identity is resolved from `/2/users/me`.

---

## Preflight

1. `command -v xurl` — if absent, return the **unavailable report** with reason `xurl not installed`.
2. `xurl /2/users/me` — if it errors or returns no `data.id`, return the **unavailable report** with reason `xurl not authenticated`.

Never prompt for credentials, never attempt an auth flow, never print a token.

---

## Data to Fetch

Both fetches are independent. One failing does NOT block the other.

### 1. Account

```
xurl "/2/users/me?user.fields=public_metrics,description"
```

Extract `id`, `username`, `description` (the bio — this is the positioning source consumed by §6), `followers_count`, `following_count`, `tweet_count`.

### 2. Posts in the window

```
xurl "/2/users/{id}/tweets?max_results=100&start_time={start}T00:00:00Z&end_time={end}T23:59:59Z&tweet.fields=created_at,public_metrics,organic_metrics,non_public_metrics,referenced_tweets,conversation_id,in_reply_to_user_id,note_tweet,lang"
```

where `{start}` is `target_date_iso` minus `window_days` and `{end}` is `target_date_iso`.

Paginate while `meta.next_token` is present, appending `&pagination_token={next_token}`. **Cap at 10 pages** as a runaway guard; if the cap is hit, report how many posts went unfetched.

**Metrics tier.** `organic_metrics` and `non_public_metrics` are returned by X only for posts under ~30 days old. If `window_days` > 30, expect them to be absent on older posts: fall back to `public_metrics`, and set the metrics tier to `public-only ⚠️`.

---

## Derivations

### Per post

| Field | Rule |
|-------|------|
| `url` | `https://x.com/{username}/status/{id}` |
| `vault_note` | `{tweet_id}` when `{tweets_folder}/{tweet_id}.md` exists, else `null`. Null is a normal result, not a warning — the consumer falls back to `url`. Always `null` when `tweets_folder` is null. |
| `type` | Exactly one value, by this precedence, first match wins: `article` if the post carries an `article` object → `reply` if `referenced_tweets` contains `replied_to` → `quote` if it contains `quoted` → `original` otherwise. Mutually exclusive by construction, so the type counts always sum to the post total. |
| `self_reply` | `true` when `type == reply` and `in_reply_to_user_id` equals the account's own id. Distinguishes a self-authored thread continuation from a reply to someone else. |
| `thread_id` | `conversation_id`, used only for grouping. |
| `impressions` | `organic_metrics.impression_count`, falling back to `public_metrics.impression_count` |
| `engagements` | `non_public_metrics.engagements`, falling back to the sum of likes + replies + retweets + quotes + bookmarks |
| `engagement_rate` | `engagements / impressions` as a percentage to one decimal; `n/a` when impressions is 0 |
| `profile_clicks` | `non_public_metrics.user_profile_clicks` |
| `link_clicks` | `non_public_metrics.url_link_clicks`. **This field is frequently absent even for posts carrying links** — absent is not zero. Report it as `null`, never as `0`. |

### Aggregate

- Totals: posts, impressions, engagements, likes, replies, retweets, quotes, bookmarks, profile clicks. Link clicks only if any post returned the field.
- Window engagement rate: total engagements / total impressions.
- **Median** impressions and median engagement rate. Medians, not means — the distribution is heavily skewed and a single high-reach post distorts a mean.
- Top 3 by impressions. Top 3 by engagement rate **among posts with ≥100 impressions** (the floor stops a 12-impression reply with one like ranking first). Bottom 3 originals by impressions.
- Split by `type`: count, impressions, engagements, median engagement rate. The counts must sum to the post total — a mismatch is a bug, not rounding.
- Replies split into self-replies (thread continuations) and replies to others. The raw reply count conflates two different activities.
- **Threads:** a thread is two or more of the account's own posts sharing one `conversation_id` where every post after the first is a `self_reply`. Report count, posts per thread, combined impressions.
- Split by `lang`: count and impressions.
- Cadence: posts per calendar day, and the list of days in the window with zero posts.

---

## Output

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
- Link clicks: N or "not returned"
- Profile clicks: N
- Median impressions: N · Median engagement rate: X%

### Posts
[{id, url, vault_note, created_at, type, self_reply, thread_id, lang,
  impressions, engagements, engagement_rate, likes, replies, retweets, quotes,
  bookmarks, link_clicks, profile_clicks, text (first 120 chars),
  article_title (if any)}]

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

---

## Resilience

- The account fetch and the posts fetch are independent. A successful account fetch with a failed posts fetch still yields the follower count for §5 — return it.
- Retry a failed fetch once, then give up and mark ⚠️.
- On HTTP 429, report the rate-limit reset time rather than retrying in a loop.
- Always produce a report, even if everything failed.
- This agent **does not analyse**, score, interpret, or recommend. No "you should", no assessment of whether the numbers are good. That belongs to the command.
````

- [ ] **Step 4: Run the verification script to confirm it passes**

Run: `./docs/superpowers/plans/verify/task1.sh`
Expected: every line `ok`, exit 0.

- [ ] **Step 5: Smoke-test the agent against the live API**

Dispatch `twitter-analyst` with `window_days: 7`, `target_date_iso: 2026-08-18`, `tweets_folder: /Users/felipepolo/Documents/vaults/Digital Garden/records/tweets`.

Expected: a report with a non-zero post count, `Metrics tier: organic + non-public`, type counts summing to the post total, and every `vault_note` either a 19-digit id or null. If `xurl` is unavailable in the execution environment, expect the unavailable report instead — that is also a pass for this step.

- [ ] **Step 6: Commit**

```bash
git add agents/twitter-analyst.md docs/superpowers/plans/verify/task1.sh
git commit -m "Add twitter-analyst agent for X activity data

Fetches account metrics and windowed post metrics through the xurl CLI in
two API calls. Structures only -- no analysis, scoring, or recommendations.

Post types are mutually exclusive by precedence so counts always sum, and
threads are detected via conversation_id plus in_reply_to_user_id rather
than by timing heuristics.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Manifest key and command wiring

**Files:**
- Modify: `commands/manifest.yaml` (append a `tweets` key under `ceo-coach:`)
- Modify: `commands/review.md` (Step 1 note, Step 2 dispatch, Step 6 report block, Fallbacks section)
- Test: `docs/superpowers/plans/verify/task2.sh`

**Interfaces:**
- Consumes: the `twitter-analyst` agent from Task 1, by name.
- Produces: a resolved `tweets` manifest key whose value is passed to the agent as `tweets_folder`; a `Twitter Analyst Report` available to Tasks 3 and 4 for rendering.

- [ ] **Step 1: Write the failing verification script**

```bash
cat > docs/superpowers/plans/verify/task2.sh <<'EOF'
#!/bin/bash
set -u
fail=0
chk() { if grep -qF "$3" "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
chk "manifest tweets key"    commands/manifest.yaml "  tweets:"
chk "manifest tweets path"   commands/manifest.yaml "records/tweets/"
chk "manifest tweets opt"    commands/manifest.yaml "required: false"
chk "review resolves tweets" commands/review.md "\`tweets\` (optional)"
chk "parallel dispatch"      commands/review.md "in parallel"
chk "dispatches agent"       commands/review.md "twitter-analyst"
chk "passes tweets_folder"   commands/review.md "tweets_folder"
chk "report block line"      commands/review.md "X / Twitter:"
chk "fallback xurl missing"  commands/review.md "xurl not installed"
chk "fallback unauth"        commands/review.md "xurl not authenticated"
chk "fallback 30d"           commands/review.md "beyond 30 days"
chk "fallback baseline"      commands/review.md "baseline — no prior figure recorded"
chk "non-blocking rule"      commands/review.md "must not block"
# YAML must still parse
python3 -c "import yaml,sys; d=yaml.safe_load(open('commands/manifest.yaml'));
k=d['ceo-coach']['tweets']; assert k['required'] is False; assert k['format']=='directory';
assert any('records/tweets' in p for p in k['paths']); print('ok   manifest parses and tweets key is well-formed')" || fail=1
exit $fail
EOF
chmod +x docs/superpowers/plans/verify/task2.sh
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./docs/superpowers/plans/verify/task2.sh`
Expected: `FAIL manifest tweets key` and several others, exit 1.

- [ ] **Step 3: Add the manifest key**

Append to `commands/manifest.yaml`, after the `weekly-plans` key, matching the file's existing comment style:

```yaml
  tweets:
    description: "Directory of pulled X/Twitter post notes, one per post, named {tweet_id}.md"
    paths:
      - $WORKSPACE/records/tweets/
    required: false
    format: directory
    note: "Populated by wiki-manager's /pull-tweets. When absent, sections 5 and 6 link posts to x.com instead of wikilinking their vault notes."
```

- [ ] **Step 4: Wire the command's Step 1**

In `commands/review.md` §"#### 1. Manifest resolution", replace the resolve list with:

```markdown
Invoke `manifest-resolver` for domain `ceo-coach`. Resolve:
- `rocks` (**required**) — quarterly objectives, KRs, weights, status.
- `weekly-plans` (optional) — the `records/logs/weekly/` directory; this is where the
  review is saved, and it is also the source of the previous run's follower figure
  for Section 5. Its absence downgrades the follower delta to *baseline*; it never
  blocks the run.
- `tweets` (optional) — the `records/tweets/` directory, used to wikilink posts to
  their vault notes in Sections 5 and 6. When it resolves nowhere, posts link to
  `x.com` instead.

The other manifest keys (`calendar-rules`, `delegation-log`, `leadership-framework`,
`values`, `quarterly-plan`, `thinking-style`) are **not needed** by this command.
```

- [ ] **Step 5: Wire the command's Step 2 dispatch**

In `commands/review.md` §"#### 2. Gather behavioral data", after the existing `performance-analyst` paragraph and its four bullets, append:

```markdown
Dispatch **both agents in parallel — two tool calls in a single message**:

- `performance-analyst` (`agents/performance-analyst.md`) with the resolved `rocks`
  path, as above.
- `twitter-analyst` (`agents/twitter-analyst.md`) with `window_days`,
  `target_date_iso`, and `tweets_folder` set to the resolved `tweets` path (or null).

The two agents share no state and neither blocks the other. A `twitter-analyst`
failure **must not block** Sections 1–4 or the Overview: on failure, render the ⚠️
lines described under *Fallbacks & resilience* and continue.
```

- [ ] **Step 6: Add the report block line**

In `commands/review.md` §"#### 6. Report", add one line to the code fence after `Meetings:`:

```
X / Twitter:   {N} posts · {M} impressions · {X}% eng · {F} followers ({±D})
```

and directly beneath the fence add:

```markdown
When the analyst was unavailable, that line reads
`X / Twitter:   ⚠️ unavailable ({reason})` instead.
```

- [ ] **Step 7: Add the fallback entries**

In `commands/review.md` §"### Fallbacks & resilience", append these bullets:

```markdown
- **`xurl` missing or unauthenticated:** omit Sections 5 and 6 entirely, replacing
  each with a single ⚠️ line naming the reason (`xurl not installed` /
  `xurl not authenticated`) and the fix (install `xurl`, or run `xurl auth`).
  Sections 1–4 and the Overview proceed unaffected.
- **X API errors or rate limits:** render Section 5 with whatever slices returned,
  marking the missing ones ⚠️. If only the account fetch succeeded, Section 5 carries
  the follower line and the snapshot anchor alone — the anchor is emitted whenever
  the account fetch succeeds, so a failed posts fetch never breaks the *next* run's
  delta — and Section 6 is skipped with a ⚠️, because recommendations without
  performance data would be ungrounded.
- **Window longer than 30 days:** Section 5 renders from `public_metrics` only. The
  engagements, engagement-rate, profile-clicks and link-clicks rows are marked ⚠️
  *not available beyond 30 days*. This is an X platform limit, not an auth problem.
- **No prior review carrying an `x-snapshot` anchor:** the follower line reads
  *baseline — no prior figure recorded*. This is not an error and is not marked ⚠️.
```

- [ ] **Step 8: Run the verification script to confirm it passes**

Run: `./docs/superpowers/plans/verify/task2.sh`
Expected: every line `ok`, including the YAML parse, exit 0.

- [ ] **Step 9: Commit**

```bash
git add commands/manifest.yaml commands/review.md docs/superpowers/plans/verify/task2.sh
git commit -m "Wire twitter-analyst into /review with an optional tweets key

Dispatches twitter-analyst in parallel with performance-analyst and adds
the optional tweets manifest key used to wikilink posts to vault notes.

The tweets key is optional so the plugin still works for a user with no
such folder; the fallback to x.com links loses nothing. A twitter-analyst
failure is explicitly non-blocking for sections 1-4.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Section 5 render specification

**Files:**
- Modify: `commands/review.md` (wikilink rules, new `##### Section 5` block under Step 3, template in Step 5)
- Test: `docs/superpowers/plans/verify/task3.sh`

**Interfaces:**
- Consumes: the `### Totals`, `### Posts` and `### Breakdowns` blocks from Task 1's agent; the dispatch wiring from Task 2.
- Produces: a rendered `## 5. Twitter performance` section ending in the anchor `<!-- x-snapshot: followers={N} following={N} at={YYYY-MM-DD} -->`, which Task 3's own next-run lookup and Task 6's verification both depend on.

- [ ] **Step 1: Write the failing verification script**

```bash
cat > docs/superpowers/plans/verify/task3.sh <<'EOF'
#!/bin/bash
set -u
F=commands/review.md
fail=0
chk() { if grep -qF "$2" "$F"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
chk "section 5 heading spec"  "##### Section 5 — Twitter performance"
chk "template section 5"      "## 5. Twitter performance"
chk "five descriptive"        "five descriptive sections"
chk "post wikilink rule"      "records/tweets/{tweet_id}.md"
chk "x.com fallback"          "otherwise the markdown link"
chk "snapshot anchor"         "<!-- x-snapshot: followers="
chk "anchor lookup"           "followers=(\\d+)"
chk "proxy label"             "API proxy"
chk "no total visits claim"   "does not expose total profile visits"
chk "asof caveat"             "point-in-time at *run* time"
chk "link clicks caveat"      "not returned"
chk "engagements caveat"      "detail expands"
chk "median rationale"        "skewed"
chk "reply inclusion floor"   "100 impressions"
chk "excluded replies line"   "Plus {N} replies below 100 impressions"
chk "neutral tone rule"       "belongs to Section 6"
exit $fail
EOF
chmod +x docs/superpowers/plans/verify/task3.sh
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./docs/superpowers/plans/verify/task3.sh`
Expected: all `FAIL`, exit 1.

- [ ] **Step 3: Extend the wikilink rules**

In `commands/review.md` §"#### 3. Assemble the four descriptive sections", change the heading to `#### 3. Assemble the five descriptive sections`, change the sentence `Build the sections **in this order** (1 → 4).` to `(1 → 5)`, and add this bullet to the **Wikilink rules** list:

```markdown
- **Posts** → wikilink to their vault note by tweet id when
  `records/tweets/{tweet_id}.md` exists, aliased to the snippet
  (`[[2088289040139173943|Uno de los tips profesionales…]]`); otherwise the markdown
  link to the `x.com` URL. Mixed output within one table is expected — `/pull-tweets`
  defaults to a 7-day window — and is never marked ⚠️.
```

- [ ] **Step 4: Add the Section 5 render block**

In `commands/review.md`, after the `##### Section 4 — Other relevant information` block and before `#### 4. Synthesize the Overview`, insert:

````markdown
##### Section 5 — Twitter performance
Source: the `twitter-analyst` report. **Descriptive only** — same register as
Sections 1–4. Report, do not grade: no "you should", no praise, no drift-shaming.
Anything prescriptive **belongs to Section 6**.

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
   "You should post more originals" is not — that **belongs to Section 6**.

8. **Snapshot anchor**, as the section's final line:

   ```
   <!-- x-snapshot: followers={N} following={N} at={YYYY-MM-DD} -->
   ```
````

- [ ] **Step 5: Update the template**

In `commands/review.md` §"#### 5. Assemble and save", insert into the markdown template between Section 4 and the Overview:

```markdown
## 5. Twitter performance
{Section 5}
```

- [ ] **Step 6: Run the verification script to confirm it passes**

Run: `./docs/superpowers/plans/verify/task3.sh`
Expected: every line `ok`, exit 0.

- [ ] **Step 7: Commit**

```bash
git add commands/review.md docs/superpowers/plans/verify/task3.sh
git commit -m "Add Section 5 render spec for Twitter performance

Descriptive section in the same register as 1-4, with the prescriptive
half explicitly deferred to Section 6.

Carries three caveats the dry run proved necessary: engagements includes
detail expands, absent link clicks are not zero, and follower counts are
point-in-time at run time rather than window close.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Section 6 render specification

**Files:**
- Modify: `commands/review.md` (new Step 3b, template in Step 5, Overview note in Step 4)
- Test: `docs/superpowers/plans/verify/task4.sh`

**Interfaces:**
- Consumes: the same `twitter-analyst` report as Task 3, plus Sections 1–4 as rendered text and the resolved `rocks` path.
- Produces: a rendered `## 6. Content recommendations` section, positioned after §5 and before the Overview.

- [ ] **Step 1: Write the failing verification script**

```bash
cat > docs/superpowers/plans/verify/task4.sh <<'EOF'
#!/bin/bash
set -u
F=commands/review.md
fail=0
chk() { if grep -qF "$2" "$F"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
chk "step 3b exists"        "#### 3b. Assemble Section 6"
chk "template section 6"    "## 6. Content recommendations"
chk "only prescriptive"     "the one prescriptive section"
chk "generated before ovw"  "before the Overview"
chk "not an overview input" "Section 6 is not an input to the Overview"
chk "what worked"           "What worked"
chk "what didnt"            "What didn't"
chk "idea cap"              "Cap at 7"
chk "angle field"           "*Angle:*"
chk "from field"            "*From:*"
chk "format field"          "*Format:*"
chk "mechanism field"       "*Mechanism:*"
chk "evergreen label"       "(evergreen — not from this window)"
chk "never invent"          "Never invent"
chk "confidentiality"       "anonymise"
chk "themes not detail"     "source of *themes*"
chk "audience"              "technical"
chk "positioning from bio"  "X bio"
chk "hypotheses caveat"     "hypotheses"
chk "posts linked in prose" "A post mentioned by description alone"
exit $fail
EOF
chmod +x docs/superpowers/plans/verify/task4.sh
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./docs/superpowers/plans/verify/task4.sh`
Expected: all `FAIL`, exit 1.

- [ ] **Step 3: Add the Step 3b block**

In `commands/review.md`, insert a new step between `#### 3. Assemble the five descriptive sections` and `#### 4. Synthesize the Overview`:

````markdown
#### 3b. Assemble Section 6 — Content recommendations

This is **the one prescriptive section** in the review, and the single exception to
the describe-before-interpret rule. Generate it after Sections 1–5 exist and
**before the Overview**. It is a sibling of the Overview, not an input to it:
**Section 6 is not an input to the Overview**, and the Overview must not restate
its recommendations.

Grounded in Section 5's performance data crossed with the window's raw material
from Sections 1–4, the account bio, and `rocks.yaml`. Open with:

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
   - **Goal:** follower growth. Prefer angles that give a stranger a reason to
     follow: a repeatable point of view, an ongoing build, numbers nobody else
     publishes.

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
````

- [ ] **Step 4: Note the Overview's boundary**

In `commands/review.md` §"#### 4. Synthesize the Overview", change the opening sentence `After sections 1–4 exist` to `After Sections 1–5 exist`, and append this bullet to the list of what the Overview must do:

```markdown
- Draw only on Sections 1–5. The Overview may note where content activity converges
  with the calendar, the rocks or the journaling, but **Section 6 is not an input to
  the Overview** and its recommendations must not be restated there.
```

- [ ] **Step 5: Update the template**

In `commands/review.md` §"#### 5. Assemble and save", insert into the markdown template between Section 5 and the Overview:

```markdown
## 6. Content recommendations
{Section 6}
```

- [ ] **Step 6: Run the verification script to confirm it passes**

Run: `./docs/superpowers/plans/verify/task4.sh`
Expected: every line `ok`, exit 0.

- [ ] **Step 7: Commit**

```bash
git add commands/review.md docs/superpowers/plans/verify/task4.sh
git commit -m "Add Section 6 render spec for content recommendations

The review's only prescriptive section, kept separate from the four
descriptive lenses and explicitly excluded as an Overview input.

Hard rules carry the anti-fabrication constraints: cite or label
evergreen, cap at 7 rather than pad, treat meeting notes as a source of
themes and never of quotable client detail.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Documentation and version bump

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json`
- Test: `docs/superpowers/plans/verify/task5.sh`

**Interfaces:**
- Consumes: the component names established in Tasks 1–4 (`twitter-analyst`, sections 5 and 6).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the failing verification script**

```bash
cat > docs/superpowers/plans/verify/task5.sh <<'EOF'
#!/bin/bash
set -u
fail=0
chk() { if grep -qF "$3" "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
chk "claude components"   CLAUDE.md "twitter-analyst"
chk "claude proxy rule"   CLAUDE.md "profile visits"
chk "claude sections"     CLAUDE.md "Twitter performance"
chk "readme agent row"    README.md "twitter-analyst"
chk "readme review row"   README.md "Twitter performance"
chk "readme xurl setup"   README.md "xurl"
python3 -c "
import json
a=json.load(open('.claude-plugin/plugin.json'))['version']
b=json.load(open('.claude-plugin/marketplace.json'))['plugins'][0]['version']
assert a=='1.5.0', f'plugin.json is {a}'
assert b=='1.5.0', f'marketplace.json is {b}'
print('ok   versions are 1.5.0 and in sync')" || fail=1
exit $fail
EOF
chmod +x docs/superpowers/plans/verify/task5.sh
```

- [ ] **Step 2: Run it to verify it fails**

Run: `./docs/superpowers/plans/verify/task5.sh`
Expected: `FAIL claude components` and others, plus `plugin.json is 1.4.0`, exit 1.

- [ ] **Step 3: Update `CLAUDE.md`**

Change Core Responsibility 1 to:

```markdown
1. **Descriptive reviews** (`/review`) — Report what happened across five lenses (time,
   progress, thoughts, meeting themes, X/Twitter performance), then synthesize one
   interpretive Overview, plus one prescriptive section of content recommendations.
   Reports and connects; does not grade.
```

Add to the Components table, in the Agent block:

```markdown
| Agent | `twitter-analyst` | Fetch X/Twitter account and post metrics for the review window |
```

Add to Operational Rules:

```markdown
- **Profile visits are not available.** The X API exposes no profile-visits metric.
  Report `user_profile_clicks` as an explicitly labelled proxy — never as "profile
  visits", and never silently.
- **Post links follow the vault first.** Wikilink a post to `records/tweets/{tweet_id}.md`
  when it exists; fall back to the `x.com` URL otherwise.
```

Extend the **Cite the source** rule so it also names post links.

- [ ] **Step 4: Update `README.md`**

Extend the `/review` row to mention the two new sections. Add to the Agents table:

```markdown
| `twitter-analyst` | Fetches X/Twitter account metrics and windowed post metrics via the `xurl` CLI. Two API calls per run. |
```

Add to Setup:

```markdown
Sections 5 and 6 of `/review` need the [`xurl`](https://github.com/xdevplatform/xurl)
CLI authenticated with OAuth 2.0 user context. Without it the two sections are
replaced by a single ⚠️ line each and the rest of the review is unaffected. Post
links resolve to vault notes when a `records/tweets/` directory exists (populated by
wiki-manager's `/pull-tweets`), and to `x.com` otherwise.
```

- [ ] **Step 5: Bump both version files to `1.5.0`**

```bash
python3 - <<'PY'
import json
for p,f in [('.claude-plugin/plugin.json', lambda d: d.__setitem__('version','1.5.0')),
            ('.claude-plugin/marketplace.json', lambda d: d['plugins'][0].__setitem__('version','1.5.0'))]:
    d=json.load(open(p)); f(d)
    open(p,'w').write(json.dumps(d, indent=2)+'\n')
print('bumped')
PY
```

- [ ] **Step 6: Run the verification script to confirm it passes**

Run: `./docs/superpowers/plans/verify/task5.sh`
Expected: every line `ok`, exit 0.

- [ ] **Step 7: Commit**

```bash
git add CLAUDE.md README.md .claude-plugin/plugin.json .claude-plugin/marketplace.json docs/superpowers/plans/verify/task5.sh
git commit -m "Document Twitter sections and bump to 1.5.0

Adds the twitter-analyst agent to both component tables, documents the
xurl requirement and its graceful degradation, and records the rule that
profile visits must always be reported as a labelled proxy.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: End-to-end verification

**Files:**
- Create: `docs/superpowers/plans/verify/e2e.py`
- Modify: none

**Interfaces:**
- Consumes: everything from Tasks 1–5.
- Produces: nothing. This task is the functional gate.

- [ ] **Step 1: Write the end-to-end checker**

```bash
cat > docs/superpowers/plans/verify/e2e.py <<'EOF'
#!/usr/bin/env python3
"""Reconcile a rendered review's Section 5 against an independent X API call.

Usage: e2e.py <review.md> <vault_root> <start YYYY-MM-DD> <end YYYY-MM-DD>
Exits non-zero on any mismatch. Run after /review has written the file.
"""
import json, os, re, subprocess, sys

review, vault, start, end = sys.argv[1:5]
doc = open(review).read()

def section(name, nxt):
    assert f'## {name}' in doc, f'missing section: {name}'
    return doc.split(f'## {name}')[1].split(f'## {nxt}')[0]

s5 = section('5. Twitter performance', '6. Content recommendations')
s6 = section('6. Content recommendations', 'Overview')

# --- independent fetch, deliberately a different query shape than the agent's ---
uid = json.loads(subprocess.check_output(['xurl', '/2/users/me']))['data']['id']
url = (f'/2/users/{uid}/tweets?max_results=50&start_time={start}T00:00:00Z'
       f'&end_time={end}T23:59:59Z&tweet.fields=organic_metrics,non_public_metrics')
posts = json.loads(subprocess.check_output(['xurl', url])).get('data', [])
imp = sum(t['organic_metrics']['impression_count'] for t in posts)
eng = sum(t['non_public_metrics']['engagements'] for t in posts)
pc  = sum(t['non_public_metrics'].get('user_profile_clicks', 0) for t in posts)

fails = []
def check(label, ok):
    print(('ok   ' if ok else 'FAIL ') + label)
    if not ok: fails.append(label)

check(f'post count {len(posts)} appears in S5',   f'{len(posts)} posts' in s5)
check(f'impressions {imp:,} appears in S5',       f'{imp:,}' in s5)
check(f'engagements {eng:,} appears in S5',       f'{eng:,}' in s5)
check(f'profile clicks {pc} appears in S5',       str(pc) in s5)
check('snapshot anchor well-formed',
      bool(re.search(r'<!-- x-snapshot: followers=\d+ following=\d+ at=\d{4}-\d{2}-\d{2} -->', s5)))
check('profile-clicks labelled a proxy',          'API proxy' in s5)
check('S5 free of prescriptive language',
      not re.search(r'you should|we recommend', s5, re.I))

# every idea carries a citation
angles, froms = s6.count('*Angle:*'), s6.count('*From:*')
check(f'all {angles} ideas carry a From: ({froms})', angles == froms and angles > 0)
check('idea count within cap',                    0 < angles <= 7)

# links resolve: tweet wikilinks -> records/tweets, meeting wikilinks -> anywhere in vault
tweets_dir = os.path.join(vault, 'records', 'tweets')
tw = set(re.findall(r'\[\[(\d{15,25})[|\]]', s5 + s6))
missing_tw = [t for t in tw if not os.path.exists(os.path.join(tweets_dir, t + '.md'))]
check(f'{len(tw)} tweet wikilinks resolve',       not missing_tw)

# followlinks=True is required: records/meetings is a symlink to Google Drive
have = {os.path.splitext(f)[0]
        for _, _, fs in os.walk(vault, followlinks=True) for f in fs if f.endswith('.md')}
meet = set(re.findall(r'\[\[(\d{4}-\d{2}-\d{2} [^\]|]+)', s6))
check(f'{len(meet)} meeting wikilinks resolve',   all(m in have for m in meet))

print('\nFAILED: ' + ', '.join(fails) if fails else '\nAll checks passed.')
sys.exit(1 if fails else 0)
EOF
chmod +x docs/superpowers/plans/verify/e2e.py
```

- [ ] **Step 2: Run `/review` for a live 7-day window**

Run `/review --window 7d`. It writes `records/logs/weekly/DD-MM-YYYY.md` for today's date — a **new** file, so no existing review is overwritten.

Expected: the report block shows a non-zero `X / Twitter:` line; the saved file contains sections 1–6 followed by the Overview, in that order.

- [ ] **Step 3: Reconcile against the API**

Run: `./docs/superpowers/plans/verify/e2e.py "<vault>/records/logs/weekly/<today>.md" "<vault>" <start> <end>`
Expected: every line `ok`, `All checks passed.`, exit 0.

A post-count or impressions mismatch is the failure that matters most — a section that silently under-counts posts is worse than no section. Do not proceed past a mismatch.

- [ ] **Step 4: Verify graceful degradation with `xurl` unavailable**

```bash
mkdir -p /tmp/noxurl && PATH=/tmp/noxurl:/usr/bin:/bin command -v xurl || echo "xurl correctly hidden"
```

Then run `/review --window 7d` with `PATH` shadowed so `xurl` cannot be found.

Expected: Sections 1–4 and the Overview render normally; Sections 5 and 6 are each replaced by a single ⚠️ line naming `xurl not installed`; the report block reads `X / Twitter:   ⚠️ unavailable (xurl not installed)`. The command must **not** error out.

- [ ] **Step 5: Verify the >30-day degradation path**

Run `/review --window 45d`.

Expected: Section 5 renders; the engagements, engagement-rate, profile-clicks and link-clicks rows are marked ⚠️ *not available beyond 30 days* rather than showing `0`; posts older than 30 days still appear with their `public_metrics` impressions.

- [ ] **Step 6: Verify the follower delta on a second run**

Confirm the file written in Step 2 contains an `x-snapshot` anchor, then run `/review --window 7d` again for a later end date.

Expected: the second review's follower line reads `net {±D} vs {prior} recorded in [[DD-MM-YYYY]]` and wikilinks the first file, rather than `baseline`.

- [ ] **Step 7: Commit**

```bash
git add docs/superpowers/plans/verify/e2e.py
git commit -m "Add end-to-end verification for the Twitter sections

Reconciles a rendered Section 5 against an independent API call using a
different query shape than the agent's, so a shared bug cannot make both
sides agree.

Walks the vault with followlinks=True because records/meetings is a
symlink to Google Drive; a default walk reports every meeting wikilink
as broken.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage.** Spec §3.1 architecture → Task 1 + Task 2 Step 5. §3.2 snapshot state → Task 3 Step 4 item 3, verified Task 6 Step 6. §3.3 manifest key → Task 2 Step 3. §3.4 post links → Task 3 Step 3, Task 4 hard rules, verified Task 6. §4 agent → Task 1. §5.1–5.2 wiring → Task 2 Steps 4–5. §5.5 Overview boundary → Task 4 Step 4. §5.6 template → Tasks 3 and 4 Step 5. §5.7 report block → Task 2 Step 6. §5.8 fallbacks → Task 2 Step 7, verified Task 6 Steps 4–5. §6 Section 5 → Task 3. §7 Section 6 → Task 4. §8 docs and version → Task 5. §9 verification → Task 6. No gaps.

**Placeholder scan.** No TBDs. Every step carries the literal content to write or the exact command to run.

**Type consistency.** `twitter-analyst`, `window_days`, `target_date_iso`, `tweets_folder`, `vault_note`, `self_reply`, `thread_id`, and the anchor format `<!-- x-snapshot: followers={N} following={N} at={YYYY-MM-DD} -->` are spelled identically in Tasks 1, 2, 3 and 6. The agent's output headings (`### Totals`, `### Posts`, `### Breakdowns`, `### Sources`) are asserted in Task 1 and consumed by Tasks 3 and 4.

**Known weakness, stated rather than hidden.** Tasks 1–5 are verified by structural greps, which prove that a rule was *written down*, not that a model *follows* it. The only genuine functional test is Task 6. Treat Task 6 as the real gate — a green Task 1–5 with a red Task 6 means the feature does not work.
