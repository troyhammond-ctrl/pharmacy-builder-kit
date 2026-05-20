#!/usr/bin/env bash
# tests/02-section-headings.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Contract half
assert_contains_regex '^## Inputs$' "02-headings:inputs"
assert_contains_regex '^## Scrape$' "02-headings:scrape"
assert_contains_regex '^## Required pages$' "02-headings:pages"
assert_contains_regex '^## Required sections$' "02-headings:sections"
assert_contains_regex '^## Voice$' "02-headings:voice"
assert_contains_regex '^## Banned phrasings$' "02-headings:banned"
assert_contains_regex '^## Factual guardrails$' "02-headings:facts"
assert_contains_regex '^## PHI rules$' "02-headings:phi"
assert_contains_regex '^## Accessibility \(WCAG 2.2 AA\)$' "02-headings:a11y"
assert_contains_regex '^## SEO$' "02-headings:seo"
assert_contains_regex '^## Schema \(JSON-LD\)$' "02-headings:schema"

# Process half
assert_contains_regex '^## Process$' "02-headings:process"
assert_contains_regex '^## QA self-validation checklist$' "02-headings:qa"

pass "02-section-headings"
