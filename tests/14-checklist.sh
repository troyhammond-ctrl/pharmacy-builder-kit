#!/usr/bin/env bash
# tests/14-checklist.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Group headers
for group in \
  "INPUTS" \
  "SCRAPE" \
  "PAGES" \
  "HEADER / SITE-WIDE SECTIONS" \
  "A11Y (WCAG 2.2 AA)" \
  "SEO + SCHEMA" \
  "CONTENT GUARDRAILS" \
  "WIRING" \
  "RESULT"
do
  assert_contains "$group" "14-checklist:group-$group"
done

# Spot-check critical line items
assert_contains "[ ] Build sheet parsed" "14-checklist:input-line"
assert_contains "[ ] Source site mirrored" "14-checklist:scrape-line"
assert_contains "[ ] Home, About, Contact" "14-checklist:pages-line"
assert_contains "[ ] Sticky header" "14-checklist:header-line"
assert_contains "[ ] Single H1 per page" "14-checklist:a11y-line"
assert_contains "[ ] robots.txt, sitemap.xml, llms.txt generated" "14-checklist:seo-line"
assert_contains "[ ] Banned phrasing scan: zero hits" "14-checklist:guardrails-line"
assert_contains "[ ] Refill CTA -> build sheet refill portal URL" "14-checklist:wiring-line"
assert_contains "[ ] All three validators PASS" "14-checklist:result-line"

# Reproduction directive
assert_contains "must reproduce" "14-checklist:must-reproduce"
assert_contains "build/log.md" "14-checklist:build-log"
assert_contains "Any unchecked box" "14-checklist:any-unchecked"

pass "14-checklist"
