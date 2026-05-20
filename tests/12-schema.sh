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

# Medical schema types for procedure/clinical services
assert_contains "MedicalProcedure" "12-schema:medical-procedure"
assert_contains "MedicalTherapy" "12-schema:medical-therapy"
assert_contains "MedicalTest" "12-schema:medical-test"
assert_contains "Vaccine" "12-schema:vaccine"
assert_contains "procedureType" "12-schema:procedure-type-property"
assert_contains "availableService" "12-schema:available-service"

# No on-site search functionality
assert_contains "No on-site search" "12-schema:no-search-directive"
assert_contains "Do not emit" "12-schema:no-search-emit"

# Geo: no external geocoding
assert_contains "no external geocoding" "12-schema:no-geocoding"

# Validation
assert_contains "tools/validate-schema.mjs" "12-schema:validator"
assert_contains "offline by default" "12-schema:offline-default"
assert_contains "Rich Results" "12-schema:rich-results-optional"

# FAQ source rule
assert_contains "never invented" "12-schema:faq-never-invented"

pass "12-schema"
