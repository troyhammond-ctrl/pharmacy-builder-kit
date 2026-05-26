#!/usr/bin/env bash
# tests/18-qa-skill.sh
# Structural regression guard for QA-SKILL.md — the sibling audit
# skill. Locks the twelve audit dimensions, the audit process, the
# report format, and the closing checklist.
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"
source "$(dirname "$0")/lib/qa-check.sh"

# Resolve QA file path relative to repo root (run.sh has already cd'd there)
export QA_FILE="$(pwd)/QA-SKILL.md"

qa_assert_file_exists "18-qa:file-exists"

# Frontmatter
qa_assert_contains_regex '^---$' "18-qa:frontmatter-delimiter"
qa_assert_contains_regex '^name: pharmacy-qa$' "18-qa:frontmatter-name"
qa_assert_contains_regex '^description:.*audit a pharmacy site' "18-qa:trigger-audit"
qa_assert_contains_regex '^description:.*QA a pharmacy site' "18-qa:trigger-qa"
qa_assert_contains_regex '^description:.*find UI/UX defects' "18-qa:trigger-defects"

# Top-level headings — Contract half (audit dimensions and best practices)
qa_assert_contains_regex '^## Inputs$' "18-qa:section-inputs"
qa_assert_contains_regex '^## Audit dimensions$' "18-qa:section-dimensions"
qa_assert_contains_regex '^## Best practices$' "18-qa:section-best-practices"
qa_assert_contains_regex '^## Audit process$' "18-qa:section-process"
qa_assert_contains_regex '^## Report format$' "18-qa:section-report"
qa_assert_contains_regex '^## Closing audit checklist$' "18-qa:section-checklist"

# All twelve audit dimensions present and numbered
qa_assert_contains_regex '^### 1. Pages & structure$' "18-qa:dim-1"
qa_assert_contains_regex '^### 2. Accessibility \(WCAG 2.2 AA\)$' "18-qa:dim-2"
qa_assert_contains_regex '^### 3. SEO metadata$' "18-qa:dim-3"
qa_assert_contains_regex '^### 4. Schema \(JSON-LD\)$' "18-qa:dim-4"
qa_assert_contains_regex '^### 5. Site-wide files$' "18-qa:dim-5"
qa_assert_contains_regex '^### 6. Mobile UX$' "18-qa:dim-6"
qa_assert_contains_regex '^### 7. Conversion patterns$' "18-qa:dim-7"
qa_assert_contains_regex '^### 8. Content guardrails$' "18-qa:dim-8"
qa_assert_contains_regex '^### 9. Voice & readability$' "18-qa:dim-9"
qa_assert_contains_regex '^### 10. Visual quality$' "18-qa:dim-10"
qa_assert_contains_regex '^### 11. Performance & best practices$' "18-qa:dim-11"
qa_assert_contains_regex '^### 12. Security & privacy$' "18-qa:dim-12"

# Site-wide files validation directives
qa_assert_contains "robots.txt" "18-qa:robots"
qa_assert_contains "sitemap.xml" "18-qa:sitemap"
qa_assert_contains "llms.txt" "18-qa:llms"
qa_assert_contains 'xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"' "18-qa:sitemap-namespace"
qa_assert_contains "well-formed XML" "18-qa:well-formed"
qa_assert_contains "llmstxt.org" "18-qa:llms-spec"
qa_assert_contains "## Optional" "18-qa:llms-optional-section"

# Schema correctness
qa_assert_contains "MedicalProcedure" "18-qa:medical-procedure"
qa_assert_contains "MedicalTherapy" "18-qa:medical-therapy"
qa_assert_contains "MedicalTest" "18-qa:medical-test"
qa_assert_contains "Vaccine" "18-qa:vaccine"
qa_assert_contains "FAQPage" "18-qa:faqpage"
qa_assert_contains "BreadcrumbList" "18-qa:breadcrumb"
qa_assert_contains "availableService" "18-qa:available-service"
qa_assert_contains "no on-site search" "18-qa:no-search-check"

# UI/UX defect coverage
qa_assert_contains "focus trap" "18-qa:focus-trap"
qa_assert_contains "tap target" "18-qa:tap-target"
qa_assert_contains "safe-area-inset-bottom" "18-qa:safe-area"
qa_assert_contains "prefers-reduced-motion" "18-qa:reduced-motion"
qa_assert_contains 'aria-modal="true"' "18-qa:aria-modal"
qa_assert_contains "carousel hero" "18-qa:no-carousel"

# Content guardrails
qa_assert_contains "PHI scan" "18-qa:phi-scan"
qa_assert_contains "banned phrasings" "18-qa:banned-phrasings"
qa_assert_contains "Call 911 or go to the nearest emergency room." "18-qa:emergency-phrase"

# Performance / a11y / security tooling hints
qa_assert_contains "axe-core" "18-qa:axe-core"
qa_assert_contains "Strict-Transport-Security" "18-qa:hsts"
qa_assert_contains "Content-Security-Policy" "18-qa:csp"
qa_assert_contains "Flesch-Kincaid" "18-qa:readability"

# Best practices block
qa_assert_contains "Local SEO completeness" "18-qa:best-local-seo"
qa_assert_contains "Google Business Profile" "18-qa:best-gbp-nap"
qa_assert_contains "404 page" "18-qa:best-404"
qa_assert_contains "FAQ depth" "18-qa:best-faq-depth"
qa_assert_contains "Schema linking" "18-qa:best-schema-linking"

# Audit process — five steps
qa_assert_contains "Step 1 — Resolve" "18-qa:step-resolve"
qa_assert_contains "Step 2 — Fetch" "18-qa:step-fetch"
qa_assert_contains "Step 3 — Check" "18-qa:step-check"
qa_assert_contains "Step 4 — Render report" "18-qa:step-report"
qa_assert_contains "Step 5 — Verdict" "18-qa:step-verdict"

# Severity vocabulary
qa_assert_contains "Critical" "18-qa:severity-critical"
qa_assert_contains "Important" "18-qa:severity-important"
qa_assert_contains "Minor" "18-qa:severity-minor"

# Report artifacts
qa_assert_contains "audit/scope.json" "18-qa:scope-json"
qa_assert_contains "audit/findings.jsonl" "18-qa:findings-jsonl"
qa_assert_contains "audit/report.md" "18-qa:report-md"
qa_assert_contains "audit/report.json" "18-qa:report-json"

# Verdict matrix
qa_assert_contains "PASS WITH WARNINGS" "18-qa:verdict-warn"
qa_assert_contains 'no "PASS" with critical findings' "18-qa:verdict-no-pass-with-critical"

# Closing checklist groups
qa_assert_contains "[ ] 1. Pages & structure" "18-qa:closing-pages"
qa_assert_contains "[ ] 12. Security & privacy" "18-qa:closing-security"
qa_assert_contains "Audit complete" "18-qa:closing-complete"

# Genericity — no pharmacy-specific leakage into the QA skill either
qa_assert_not_contains() {
  local needle="$1"
  local test_name="${2:-qa-not-contains}"
  if grep -F -q -- "$needle" "$QA_FILE"; then
    _fail "$test_name" "$QA_FILE unexpectedly contains: $needle"
  fi
}

for needle in \
  "amcare" \
  "amcarerxpharmacy" \
  "AmCare" \
  "AMCare" \
  "Corona, CA"
do
  qa_assert_not_contains "$needle" "18-qa:no-$needle"
done

pass "18-qa-skill"
