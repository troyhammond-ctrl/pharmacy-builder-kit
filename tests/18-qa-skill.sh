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
qa_assert_contains_regex '^### 13. HIPAA compliance$' "18-qa:dim-13"

# Scoring rubric — grader weights and grade letters
qa_assert_contains_regex '^## Scoring rubric$' "18-qa:scoring-section"
qa_assert_contains "HIPAA Compliance | 25%" "18-qa:weight-hipaa"
qa_assert_contains "Accessibility | 20%" "18-qa:weight-a11y"
qa_assert_contains "Performance | 20%" "18-qa:weight-perf"
qa_assert_contains "SEO | 20%" "18-qa:weight-seo"
qa_assert_contains "Usability | 10%" "18-qa:weight-usability"
qa_assert_contains "Security | 5%" "18-qa:weight-security"
qa_assert_contains "Letter grade" "18-qa:letter-grade"
qa_assert_contains "weighted total below 80" "18-qa:deployment-blocker-threshold"

# Grader-style per-category check labels (verbatim with grader)
qa_assert_contains "HIPAA disclaimer on forms" "18-qa:label-hipaa-disclaimer"
qa_assert_contains "Privacy policy link" "18-qa:label-privacy-link"
qa_assert_contains "Cookie consent banner" "18-qa:label-cookie-banner"
qa_assert_contains "HTTPS encryption" "18-qa:label-https"
qa_assert_contains "No exposed patient data" "18-qa:label-no-phi"
qa_assert_contains "Image alt text" "18-qa:label-alt-text"
qa_assert_contains "Skip-to-content link" "18-qa:label-skip-link"
qa_assert_contains "ARIA landmarks" "18-qa:label-aria-landmarks"
qa_assert_contains "Form input labels" "18-qa:label-form-labels"
qa_assert_contains "Focus indicators" "18-qa:label-focus"
qa_assert_contains "Reduced motion support" "18-qa:label-reduced-motion"
qa_assert_contains "HTML lang attribute" "18-qa:label-html-lang"
qa_assert_contains "Lighthouse performance score" "18-qa:label-lighthouse"
qa_assert_contains "Largest Contentful Paint (LCP)" "18-qa:label-lcp"
qa_assert_contains "Cumulative Layout Shift (CLS)" "18-qa:label-cls"
qa_assert_contains "First Contentful Paint (FCP)" "18-qa:label-fcp"
qa_assert_contains "Speed Index" "18-qa:label-speed-index"
qa_assert_contains "Title tag" "18-qa:label-title"
qa_assert_contains "Meta description" "18-qa:label-meta-desc"
qa_assert_contains "H1 heading" "18-qa:label-h1"
qa_assert_contains "Schema.org structured data" "18-qa:label-schema"
qa_assert_contains "Open Graph tags" "18-qa:label-og"
qa_assert_contains "Canonical URL" "18-qa:label-canonical"
qa_assert_contains "Mobile viewport" "18-qa:label-viewport"
qa_assert_contains "Responsive design (media queries)" "18-qa:label-media-queries"
qa_assert_contains "Touch-friendly tap targets" "18-qa:label-tap-targets"
qa_assert_contains "Readable font size" "18-qa:label-font-size"
qa_assert_contains "No horizontal scroll" "18-qa:label-no-h-scroll"
qa_assert_contains "HSTS header" "18-qa:label-hsts"
qa_assert_contains "Clickjacking protection" "18-qa:label-clickjacking"
qa_assert_contains "Bot protection on forms" "18-qa:label-bot-protection"
qa_assert_contains "Content Security Policy" "18-qa:label-csp"

# Performance thresholds explicit
qa_assert_contains "≤ 2.5s" "18-qa:threshold-lcp"
qa_assert_contains "≤ 0.1" "18-qa:threshold-cls"
qa_assert_contains "≤ 1.8s" "18-qa:threshold-fcp"
qa_assert_contains "≥ 90" "18-qa:threshold-lighthouse"

# Tighter usability checks
qa_assert_contains "box-sizing: border-box" "18-qa:usability-box-sizing"
qa_assert_contains "font-size ≥ 16px" "18-qa:usability-font-min"
qa_assert_contains "320px viewport" "18-qa:usability-320px"

# Tighter security checks
qa_assert_contains "X-Frame-Options: SAMEORIGIN" "18-qa:sec-xfo"
qa_assert_contains "frame-ancestors" "18-qa:sec-frame-ancestors"
qa_assert_contains "Subresource integrity" "18-qa:sec-sri"
qa_assert_contains "Permissions-Policy" "18-qa:sec-permissions-policy"

# HIPAA dimension specifics
qa_assert_contains "/privacy/" "18-qa:hipaa-privacy-page"
qa_assert_contains "Notice of Privacy Practices" "18-qa:hipaa-nopp"
qa_assert_contains "HHS" "18-qa:hipaa-hhs"
qa_assert_contains "Privacy Officer" "18-qa:hipaa-privacy-officer"
qa_assert_contains "Do not submit Protected Health Information" "18-qa:hipaa-disclaimer-pattern"
qa_assert_contains "Reject Non-Essential" "18-qa:hipaa-cookie-reject"

# Verdict rule includes score backstop
qa_assert_contains "weighted total ≥ 90" "18-qa:verdict-pass-score"
qa_assert_contains "weighted total ≥ 80" "18-qa:verdict-warn-score"
qa_assert_contains "weighted total < 80" "18-qa:verdict-fail-score"

# Report format includes score breakdown
qa_assert_contains "## Score breakdown (grader rubric)" "18-qa:report-score-breakdown"
qa_assert_contains "**Weighted score:**" "18-qa:report-weighted-score"

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
qa_assert_contains "[ ] 13. HIPAA compliance" "18-qa:closing-hipaa"
qa_assert_contains "[ ] Six grader-category scores computed" "18-qa:closing-scores"
qa_assert_contains "[ ] Weighted total and letter grade computed" "18-qa:closing-weighted"
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
