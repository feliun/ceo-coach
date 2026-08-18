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
