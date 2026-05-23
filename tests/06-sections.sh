#!/usr/bin/env bash
# tests/06-sections.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Sticky header + CTAs
assert_contains "Sticky header" "06-sections:sticky-header"
assert_contains "services dropdown" "06-sections:services-dropdown"
assert_contains "Refill" "06-sections:cta-refill"
assert_contains "Transfer" "06-sections:cta-transfer"
assert_contains "Patient Portal" "06-sections:cta-portal"

# Top bar with open-now indicator
assert_contains "top bar" "06-sections:top-bar"
assert_contains "open-now" "06-sections:open-now"
assert_contains "browser" "06-sections:browser-tz"
assert_contains "Open/Closed unavailable" "06-sections:open-now-fallback"
assert_contains "never invents" "06-sections:open-now-no-invent"

# Footer
assert_contains "accessibility statement" "06-sections:footer-a11y-statement"
assert_contains "sitemap link" "06-sections:footer-sitemap-link"

# Home sections
assert_contains "Hero" "06-sections:hero"
assert_contains "Services grid" "06-sections:services-grid"
assert_contains "Hours of operation" "06-sections:hours-block"
assert_contains "Trust" "06-sections:trust"
assert_contains "Testimonials" "06-sections:testimonials"

# Contact
assert_contains "Google Map URL" "06-sections:contact-map"
assert_contains "Get directions" "06-sections:get-directions"

# Per-service
assert_contains "H1 = service name" "06-sections:service-h1"
assert_contains "Immunization Options" "06-sections:immunization-options"
assert_contains "never extend" "06-sections:never-extend"

# Iconography rule
assert_contains "one coherent icon set" "06-sections:one-icon-set"
assert_contains "currentColor" "06-sections:current-color"

# Section omission rule
assert_contains "omitted, not stubbed" "06-sections:omit-not-stub"
assert_contains "Lorem ipsum" "06-sections:no-lorem"
assert_contains "Coming soon" "06-sections:no-coming-soon"

# Mobile navigation contract
assert_contains "Mobile navigation" "06-sections:mobile-nav-section"
assert_contains "1024px" "06-sections:mobile-breakpoint"
assert_contains "hamburger" "06-sections:hamburger"
assert_contains '44×44' "06-sections:tap-target-size"
assert_contains 'role="dialog"' "06-sections:dialog-role"
assert_contains 'aria-modal="true"' "06-sections:aria-modal"
assert_contains "aria-expanded" "06-sections:aria-expanded"
assert_contains "focus trap" "06-sections:focus-trap"
assert_contains "prefers-reduced-motion" "06-sections:reduced-motion"
assert_contains "safe-area-inset" "06-sections:safe-area"

pass "06-sections"
