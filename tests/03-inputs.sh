#!/usr/bin/env bash
# tests/03-inputs.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Invocation contract
assert_contains "path to a build folder" "03-inputs:invocation"

# Required vs optional discovery rules
assert_contains "Build Sheet" "03-inputs:build-sheet-rule"
assert_contains "Required" "03-inputs:required-marker"
assert_contains "Optional" "03-inputs:optional-marker"
assert_contains "Website content" "03-inputs:content-doc-rule"
assert_contains "QA " "03-inputs:qa-doc-rule"
assert_contains "SEO_META" "03-inputs:seo-meta-doc-rule"

# Ignored
assert_contains_regex '~\$' "03-inputs:lockfile-ignored"

# Build sheet fields to extract (spot checks)
for field in "address" "hours" "phone" "fax" "email" "Website URL" "Google Map URL" "refill portal" "GA ID" "head JS" "brand color" "services topics" "services list" "immunization options" "year opened" "tagline" "about" "pickup methods"; do
  assert_contains "$field" "03-inputs:field-$field"
done

# Conditional flags
assert_contains "Requires Mobile App Page" "03-inputs:flag-app"
assert_contains "Requires transfer form page" "03-inputs:flag-transfer"
assert_contains "Additional locations" "03-inputs:flag-locations"

# Template label policy
assert_contains "Longhorn" "03-inputs:template-label"
assert_contains "label" "03-inputs:template-is-label"

# Output of step
assert_contains "build/context.json" "03-inputs:context-json"
assert_contains "provenance" "03-inputs:provenance"

# Build origin + Content-edited flags (drives Content variation policy)
assert_contains "Build origin" "03-inputs:build-origin-field"
assert_contains "new\` when the operator submitted a jotform" "03-inputs:build-origin-new"
assert_contains "rebuild\` when the input is a scrape" "03-inputs:build-origin-rebuild"
assert_contains "Content-edited flags" "03-inputs:content-edited-flags"
assert_contains "About content edited" "03-inputs:flag-about-edited"
assert_contains "Hero tagline edited" "03-inputs:flag-hero-edited"
assert_contains "Services content edited" "03-inputs:flag-services-edited"
assert_contains "FAQ content edited" "03-inputs:flag-faq-edited"

pass "03-inputs"
