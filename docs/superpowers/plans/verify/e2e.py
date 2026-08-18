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

def rendered(metric):
    """Pull a metric's total out of Section 5's totals table."""
    m = re.search(rf'\|\s*{metric}\s*\|\s*([\d,]+)\s*\|', s5, re.I)
    return int(m.group(1).replace(',', '')) if m else None

def reconcile(label, live, got, tol=0.02):
    """Engagement metrics keep accruing on recent posts, so the rendered figure is a
    snapshot taken earlier than this check. Exact equality would be flaky by design.
    Require instead that the review never OVER-reports (rendered <= live, since these
    counters only rise) and that drift stays within tolerance."""
    if got is None:
        check(f'{label}: not found in S5', False); return
    drift = abs(live - got) / max(live, 1)
    ok = got <= live and drift <= tol
    check(f'{label}: rendered {got:,} vs live {live:,} (drift {drift:.2%}, '
          f'{"within" if ok else "OUTSIDE"} {tol:.0%})', ok)

# Post count must match exactly — posts do not appear retroactively.
check(f'post count {len(posts)} appears in S5',   f'{len(posts)} posts' in s5)
reconcile('impressions', imp, rendered('Impressions'))
reconcile('engagements', eng, rendered('Engagements'))
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
