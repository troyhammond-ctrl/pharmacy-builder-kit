#!/usr/bin/env bash
# tests/07-voice.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

assert_contains "8th-grade" "07-voice:reading-level"
assert_contains "Flesch-Kincaid" "07-voice:flesch-kincaid"
assert_contains "Active voice" "07-voice:active-voice"
assert_contains "Second person" "07-voice:second-person"
assert_contains "Warm" "07-voice:warm"
assert_contains "not casual" "07-voice:not-casual"
assert_contains "Practical" "07-voice:practical"
assert_contains "local-color" "07-voice:local-color"
assert_contains "only if backed by" "07-voice:local-claim-rule"

pass "07-voice"
