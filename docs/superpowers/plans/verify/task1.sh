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
# Target prescriptive CONSTRUCTIONS, not the word "recommend" -- the agent
# legitimately uses it to forbid recommending and to name its consumer.
if grep -qiE "you should|you ought|you must (post|write|publish)|(we|i) recommend" "$F"; then
  echo "FAIL agent contains prescriptive language"; fail=1
else echo "ok   no prescriptive language"; fi
exit $fail
