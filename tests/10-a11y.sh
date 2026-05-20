#!/usr/bin/env bash
# tests/10-a11y.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Structure
assert_contains "Exactly one <h1>" "10-a11y:single-h1"
assert_contains "never skip" "10-a11y:no-skip-headings"
assert_contains "Skip-link" "10-a11y:skip-link"
assert_contains "landmarks" "10-a11y:landmarks"
assert_contains "<button>" "10-a11y:real-button"
assert_contains "<div onclick>" "10-a11y:no-div-onclick"

# Focus
assert_contains "Visible focus" "10-a11y:visible-focus"
assert_contains "2px outline" "10-a11y:focus-outline-px"

# Content
assert_contains 'alt=""' "10-a11y:empty-alt"
assert_contains "Logo alt" "10-a11y:logo-alt"
assert_contains "<Pharmacy Name> logo" "10-a11y:logo-alt-pattern"
assert_contains 'lang="en"' "10-a11y:lang-en"

# Icons
assert_contains 'aria-hidden="true"' "10-a11y:icons-aria-hidden"

# Contrast
assert_contains "4.5:1" "10-a11y:contrast-body"
assert_contains "3:1" "10-a11y:contrast-large-or-focus"
assert_contains "#111111" "10-a11y:body-text-fallback"
assert_contains "auto-darkens" "10-a11y:brand-auto-darken"

# Open-now a11y
assert_contains 'aria-live="polite"' "10-a11y:open-now-aria-live"
assert_contains "color-only" "10-a11y:not-color-only"

# Validation
assert_contains "tools/validate-a11y.mjs" "10-a11y:validator"

pass "10-a11y"
