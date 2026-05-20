#!/usr/bin/env bash
# tests/15-genericity.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Banned literal references to the example build
for needle in \
  "amcare" \
  "amcarerxpharmacy" \
  "amcarerxpharmacy.com" \
  "AMCare" \
  "AmCare" \
  "Corona, CA" \
  "0014v00002ZifNlAAJ" \
  "951-268-6486" \
  "G-JGCM348B13"
do
  assert_not_contains "$needle" "15-genericity:no-$needle"
done

pass "15-genericity"
