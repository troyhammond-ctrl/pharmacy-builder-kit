#!/usr/bin/env bash
# tests/12-schema.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Every page
assert_contains "Pharmacy" "12-schema:pharmacy"
assert_contains "LocalBusiness" "12-schema:localbusiness"
assert_contains "PostalAddress" "12-schema:postal-address"
assert_contains "openingHoursSpecification" "12-schema:opening-hours"
assert_contains "sameAs" "12-schema:same-as"
assert_contains "WebPage" "12-schema:webpage"
assert_contains "BreadcrumbList" "12-schema:breadcrumb"
assert_contains "FAQPage" "12-schema:faqpage"

# Page-specific
assert_contains "Service" "12-schema:service-type"
assert_contains "ContactPoint" "12-schema:contact-point"
assert_contains "MobileApplication" "12-schema:mobile-application"

# Geo: no external geocoding
assert_contains "no external geocoding" "12-schema:no-geocoding"

# Validation
assert_contains "tools/validate-schema.mjs" "12-schema:validator"
assert_contains "offline by default" "12-schema:offline-default"
assert_contains "Rich Results" "12-schema:rich-results-optional"

# FAQ source rule
assert_contains "never invented" "12-schema:faq-never-invented"

pass "12-schema"
