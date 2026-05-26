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

# Cookie consent banner contract
assert_contains "Cookie consent banner" "06-sections:cookie-banner-section"
assert_contains "Accept all" "06-sections:cookie-accept-all"
assert_contains "Reject non-essential" "06-sections:cookie-reject"
assert_contains "Privacy Policy" "06-sections:cookie-privacy-link"
assert_contains "consent gate" "06-sections:cookie-consent-gate"
assert_contains "must not be set" "06-sections:cookie-suppress-until-accept"

# Hero must depict pharmacist serving a patient
assert_contains "pharmacist serving a patient" "06-sections:hero-pharmacist-patient"
assert_contains "Never use a generic" "06-sections:hero-no-generic"

# App vs Patient Portal exclusivity
assert_contains "App vs Patient Portal" "06-sections:app-vs-portal"
assert_contains "pick exactly one" "06-sections:app-or-portal-only-one"
assert_contains "never both" "06-sections:never-both-app-portal"

# Logo specification
assert_contains "Logo specification" "06-sections:logo-spec-section"
assert_contains "minimum 32px tall" "06-sections:logo-header-min"
assert_contains "Footer logo:" "06-sections:logo-footer"
assert_contains "ALWAYS renders" "06-sections:logo-footer-always"
assert_contains "falls back to the pharmacy name" "06-sections:logo-fallback"

# No Home in nav
assert_contains 'never includes a separate "Home" item' "06-sections:no-home-in-nav"
assert_contains 'never "Home"' "06-sections:never-home-link"

# Hours format
assert_contains "9:00 AM – 5:00 PM" "06-sections:hours-format-canonical"
assert_contains "Never abbreviate" "06-sections:hours-no-abbrev"
assert_contains "never use \`a.m.\`" "06-sections:hours-no-periods"
assert_contains "never use 24-hour format" "06-sections:hours-no-24h"

# Reviews + Leave a Review CTA
assert_contains "Leave a Review" "06-sections:leave-a-review-cta"
assert_contains "Reviews URL" "06-sections:reviews-url-field"
assert_contains "never fabricate reviews" "06-sections:no-fake-reviews"

# Image policy
assert_contains_regex '^### Image policy$' "06-sections:image-policy-section"
assert_contains "Sourcing priority" "06-sections:image-priority"
assert_contains "Download every Unsplash image locally" "06-sections:no-hotlink"
assert_contains "do not hotlink" "06-sections:no-hotlink-rule"
assert_contains "never AI-generated" "06-sections:no-ai-exterior"
assert_contains "Exterior shots must be real" "06-sections:exterior-must-be-real"
assert_contains "image-manifest.json" "06-sections:image-manifest"

# Service page header image
assert_contains "A header image is required on every service page" "06-sections:service-image-required"

# Contact form remains opt-in
assert_contains "No contact form by default" "06-sections:no-contact-form-default"

pass "06-sections"
