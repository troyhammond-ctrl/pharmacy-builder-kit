#!/usr/bin/env bash
# tests/19-content-variation.sh
# Locks the Content variation policy: edited vs unedited detection,
# AI variation rules, uniqueness registry, provenance audit trail,
# and operator disclosure. Applies only to new builds; rebuilds use
# the scrape verbatim.
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Section present
assert_contains_regex '^## Content variation policy$' "19-variation:section"

# Scope: new builds only, rebuilds skip
assert_contains "applies only to **new builds**" "19-variation:new-builds-only"
assert_contains "Rebuilds" "19-variation:rebuilds-named"
assert_contains "skip this policy entirely" "19-variation:rebuilds-skip"

# Detection rules
assert_contains "Detecting edited vs unedited content" "19-variation:detect-subsection"
assert_contains "tools/default-templates.json" "19-variation:default-templates-file"
assert_contains "When in doubt, default to edited" "19-variation:default-to-edited"

# Behavior: edited verbatim, unedited AI-vary
assert_contains "use verbatim" "19-variation:edited-verbatim"
assert_contains "Do not paraphrase" "19-variation:no-paraphrase"
assert_contains 'do not "improve" the prose' "19-variation:no-improve"
assert_contains "AI variation step" "19-variation:ai-variation-step"

# AI variation rules
assert_contains "AI variation rules" "19-variation:rules-subsection"
assert_contains "Facts come from source only" "19-variation:facts-from-source"
assert_contains "Same factual content as the source" "19-variation:same-facts"
assert_contains "within ±20% of the default source length" "19-variation:length-bound"
assert_contains "Uniqueness across pharmacies" "19-variation:uniqueness"
assert_contains ".history/variation-hashes.json" "19-variation:hash-registry"
assert_contains "SHA-256 hashes" "19-variation:sha256"

# Variation prompt template present
assert_contains "Variation prompt template" "19-variation:prompt-template"
assert_contains "Pharmacy facts:" "19-variation:prompt-facts"

# Validation: variations are not exempt
assert_contains "Variations are not exempt" "19-variation:not-exempt"
assert_contains "tools/validate-content.mjs" "19-variation:validator"

# Audit trail
assert_contains "build/content-provenance.json" "19-variation:provenance-file"
assert_contains "ai_variation_of_default" "19-variation:provenance-label-ai"
assert_contains "operator_edited" "19-variation:provenance-label-edited"
assert_contains "scrape_for_rebuild" "19-variation:provenance-label-scrape"

# Operator disclosure
assert_contains "Never publish AI variations silently" "19-variation:no-silent-ai"
assert_contains "Operator-visible disclosure" "19-variation:disclosure"

# QA-SKILL.md mirrors the policy (the auditor verifies the build's provenance)
QA="$(pwd)/QA-SKILL.md"
grep -F -q "Content provenance" "$QA" || _fail "19-variation:qa-content-provenance" "QA-SKILL.md must reference Content provenance audit"
grep -F -q "content.provenance-mismatch" "$QA" || _fail "19-variation:qa-provenance-mismatch" "QA-SKILL.md must define content.provenance-mismatch finding"
grep -F -q "content.default-template-unvaried" "$QA" || _fail "19-variation:qa-default-unvaried" "QA-SKILL.md must define content.default-template-unvaried finding"
grep -F -q "content.variation-not-unique" "$QA" || _fail "19-variation:qa-variation-not-unique" "QA-SKILL.md must define content.variation-not-unique finding"
grep -F -q "content.no-ai-disclosure" "$QA" || _fail "19-variation:qa-no-ai-disclosure" "QA-SKILL.md must define content.no-ai-disclosure finding"

pass "19-content-variation"
