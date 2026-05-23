#!/usr/bin/env bash
# tests/17-conversion.sh
# Locks the high-converting local-pharmacy patterns: action priority,
# above-the-fold rule, sticky mobile CTA bar, click-to-call wiring,
# CTA copy rules, and banned anti-patterns.
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Section exists
assert_contains_regex '^## Conversion$' "17-conversion:section"

# Action priority
assert_contains "Primary actions" "17-conversion:primary-actions"
assert_contains "Call" "17-conversion:call-action"
assert_contains "Refill" "17-conversion:refill-action"
assert_contains "Transfer" "17-conversion:transfer-action"

# Above-the-fold rule
assert_contains "without scrolling" "17-conversion:no-scroll"
assert_contains "Open now" "17-conversion:open-now"

# Sticky bottom mobile CTA bar
assert_contains "Sticky bottom CTA bar" "17-conversion:sticky-bottom-bar"
assert_contains "IntersectionObserver" "17-conversion:intersection-observer"
assert_contains "safe-area-inset-bottom" "17-conversion:safe-area-bottom"

# Trust signals
assert_contains "Trust signals" "17-conversion:trust-signals"
assert_contains "Get directions" "17-conversion:directions-link"

# Click-to-call wiring
assert_contains '<a href="tel:+1' "17-conversion:tel-with-country-code"
assert_contains "Click-to-call" "17-conversion:click-to-call-section"

# CTA copy rules
assert_contains "verb + object" "17-conversion:cta-pattern"
assert_contains '"Click here"' "17-conversion:click-here-banned"
assert_contains '"Learn more"' "17-conversion:learn-more-banned"

# Anti-patterns banned
assert_contains "Anti-patterns" "17-conversion:anti-patterns"
assert_contains "exit-intent" "17-conversion:no-exit-intent"
assert_contains "Auto-play" "17-conversion:no-autoplay"
assert_contains "Carousel hero" "17-conversion:no-carousel-hero"

pass "17-conversion"
