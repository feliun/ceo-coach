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
python3 -c "import yaml,sys; d=yaml.safe_load(open('commands/manifest.yaml'));
k=d['ceo-coach']['tweets']; assert k['required'] is False; assert k['format']=='directory';
assert any('records/tweets' in p for p in k['paths']); print('ok   manifest parses and tweets key is well-formed')" || fail=1
exit $fail
