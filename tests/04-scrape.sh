#!/usr/bin/env bash
# tests/04-scrape.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Goal language
assert_contains "fact source" "04-scrape:fact-source"
assert_contains "not a" "04-scrape:not-design-source"

# Script name
assert_contains "tools/scrape.mjs" "04-scrape:script-name"

# Crawl rules
assert_contains "same-origin" "04-scrape:same-origin"
assert_contains "depth" "04-scrape:depth"
assert_contains "100 pages" "04-scrape:max-pages"
assert_contains "1 req/sec" "04-scrape:rate-limit"
assert_contains "robots.txt" "04-scrape:robots"

# Assets
for ext in ".pdf" ".docx" ".mp4" ".webm"; do
  assert_contains "$ext" "04-scrape:asset-$ext"
done

# Outputs
assert_contains "/scraped/manifest.json" "04-scrape:manifest"
assert_contains "/scraped/raw/" "04-scrape:raw-html"
assert_contains "/scraped/text/" "04-scrape:text-md"
assert_contains "/scraped/assets/" "04-scrape:assets-dir"

# Failure handling
assert_contains "unreachable" "04-scrape:unreachable"
assert_contains "no silent fallback" "04-scrape:no-silent-fallback"

# Conflict policy
assert_contains "Build sheet wins" "04-scrape:build-sheet-wins"

# PHI / hyperbole filtering rules apply to scraped content too
assert_contains "PHI" "04-scrape:phi-redact"

pass "04-scrape"
