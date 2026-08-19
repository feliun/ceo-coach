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
