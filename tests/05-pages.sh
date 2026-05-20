#!/usr/bin/env bash
# tests/05-pages.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Always-built pages with URLs
for entry in "Home" "/about/" "/contact/" "/services/" "/services/<slug>/" "/refill/" "/transfer/" "/faq/"; do
  assert_contains "$entry" "05-pages:always-$entry"
done

# Conditional pages
assert_contains "/app/" "05-pages:app-page"
assert_contains "Apple App Store" "05-pages:apple-badge"
assert_contains "Google Play" "05-pages:google-badge"
assert_contains "/locations/" "05-pages:locations-page"
assert_contains "150 substantive words" "05-pages:scrape-discovery-threshold"

# Transfer page is CTA-only
assert_contains "no PHI form" "05-pages:transfer-no-phi"
assert_contains "CTA" "05-pages:transfer-cta"

pass "05-pages"
