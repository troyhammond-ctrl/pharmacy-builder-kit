#!/usr/bin/env bash
# tests/13-process.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Step headers exist with correct labels
for step in \
  "Step 1 — Discover" \
  "Step 2 — Scrape" \
  "Step 3 — Plan" \
  "Step 4 — Generate" \
  "Step 5 — Validate"
do
  assert_contains "$step" "13-process:$step"
done

# Discover specifics
assert_contains "build/context.json" "13-process:context-json"
assert_contains "nullReason" "13-process:null-reason"

# Plan specifics
assert_contains "/build/page-plan.json" "13-process:page-plan"

# Generate specifics
assert_contains "head JS snippet" "13-process:head-js"
assert_contains "GA ID" "13-process:ga"

# Validate specifics
assert_contains "tools/validate-content.mjs" "13-process:val-content"
assert_contains "tools/validate-a11y.mjs" "13-process:val-a11y"
assert_contains "tools/validate-schema.mjs" "13-process:val-schema"

# Failure-mode language
assert_contains "no silent fallback" "13-process:no-silent-fallback"
assert_contains "do not declare done" "13-process:no-declare-done"

pass "13-process"
