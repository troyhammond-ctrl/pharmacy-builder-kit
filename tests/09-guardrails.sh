#!/usr/bin/env bash
# tests/09-guardrails.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Factual non-fabricatable list
for field in \
  "Hours" \
  "address" \
  "phone" \
  "fax" \
  "email" \
  "Staff names" \
  "credentials" \
  "residencies" \
  "awards" \
  "licenses" \
  "NPI" \
  "NCPDP" \
  "DEA" \
  "Services offered" \
  "Insurance plans" \
  "Years in business"
do
  assert_contains "$field" "09-guardrails:field-$field"
done

assert_contains "omitted" "09-guardrails:omitted"

# PHI rules
assert_contains "never collect" "09-guardrails:phi-never-collect"
for forbidden_input in \
  'name="dob"' \
  'name="rx_number"' \
  'name="member_id"' \
  'name="medication"'
do
  assert_contains "$forbidden_input" "09-guardrails:phi-input-$forbidden_input"
done

assert_contains "PHI scanner" "09-guardrails:phi-scanner"

# Transfer page restated as CTA-only
assert_contains "Transfer page" "09-guardrails:transfer-page"

# Clinical advice
assert_contains "Never tell a patient" "09-guardrails:no-clinical-advice"

# Mandated emergency phrase (exact)
assert_contains "Call 911 or go to the nearest emergency room." "09-guardrails:emergency-phrase"
assert_contains "only allowed" "09-guardrails:only-allowed-emergency"

pass "09-guardrails"
