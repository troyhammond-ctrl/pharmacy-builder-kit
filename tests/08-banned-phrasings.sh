#!/usr/bin/env bash
# tests/08-banned-phrasings.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Marketing hyperbole
for phrase in \
  "revolutionary" \
  "world-class" \
  "best-in-class" \
  "cutting-edge" \
  "state-of-the-art" \
  "industry-leading" \
  "premier" \
  "award-winning" \
  "voted #1" \
  "top-rated"
do
  assert_contains "$phrase" "08-banned:hyperbole-$phrase"
done

# Clinical / comparative claims
for phrase in \
  "proven to" \
  "cures" \
  "guarantees" \
  "safest" \
  "fastest"
do
  assert_contains "$phrase" "08-banned:clinical-$phrase"
done

# Operational overreach
for phrase in \
  "all insurance" \
  "any insurance" \
  "every insurance" \
  "24-hour" \
  "24/7" \
  "same-day delivery" \
  "free delivery"
do
  assert_contains "$phrase" "08-banned:operational-$phrase"
done

# Credentials
for phrase in \
  "board-certified" \
  "PharmD" \
  "RPh"
do
  assert_contains "$phrase" "08-banned:credentials-$phrase"
done

# Comparative + clinical-advice patterns
assert_contains "unlike CVS" "08-banned:comparative-cvs"
assert_contains "you should take" "08-banned:clinical-advice-pattern"

# Verification mechanism
assert_contains "tools/validate-content.mjs" "08-banned:validator"
assert_contains "fail build" "08-banned:fail-build"

pass "08-banned-phrasings"
