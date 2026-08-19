#!/bin/bash
set -u
F=commands/review.md
fail=0
chk() { if grep -qF "$2" "$F"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
chk "section 5 heading spec"  "##### Section 5 — Twitter performance"
chk "template section 5"      "## 5. Twitter performance"
chk "five descriptive"        "five descriptive sections"
chk "post wikilink rule"      "records/tweets/{tweet_id}.md"
chk "x.com fallback"          "otherwise the markdown"
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
