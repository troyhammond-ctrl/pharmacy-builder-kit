# Pharmacy Builder Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a single `SKILL.md` at the repo root that instructs Replit Agent (or Claude) to build a clean, modern, accessible, factually faithful pharmacy website from a build folder — with a thin shell-based test harness that locks the skill structure against regressions and a README that tells an operator how to use it.

**Architecture:** The deliverable is one stack-agnostic markdown skill organized as two halves — a Contract half (Inputs, Scrape, Pages, Sections, Voice, Guardrails, A11y, SEO, Schema) and a Process half (5-step build + closing self-validation checklist). The repo also ships a `tests/` directory of grep-based shell assertions that verify the SKILL.md satisfies each contract requirement, plus a README explaining the operator workflow. The spec at `docs/superpowers/specs/2026-05-20-pharmacy-builder-skill-design.md` is the authoritative source for every section's content; this plan structures the build of that content section-by-section under TDD.

**Tech Stack:** Markdown (the SKILL.md and README), POSIX shell + grep (test harness — zero npm dependencies), git (version control).

---

## File Structure

| File | Responsibility |
|---|---|
| `SKILL.md` | The deliverable — full pharmacy-builder skill with frontmatter, Contract half, Process half, and closing QA checklist |
| `README.md` | Operator instructions: what the kit produces, how to use SKILL.md with Replit Agent, expected build-folder layout, expected outputs |
| `.gitignore` | Ignore OS junk (`.DS_Store`), editor lockfiles, and any `/build/` or `/scraped/` directories created during real runs |
| `tests/run.sh` | Entry point — runs every `tests/NN-*.sh` in order; exits non-zero on first failure |
| `tests/lib/check.sh` | Assertion helpers (`assert_contains`, `assert_not_contains`, `assert_count_at_least`) sourced by each test |
| `tests/01-frontmatter.sh` | Asserts SKILL.md has YAML frontmatter with required `name` and `description` fields |
| `tests/02-section-headings.sh` | Asserts every required top-level section heading is present |
| `tests/03-inputs.sh` | Asserts §1 Input contract content (folder layout, required vs optional files, conditional flags, `build/context.json` output) |
| `tests/04-scrape.sh` | Asserts §2 Scrape contract content (seed, crawl rules, manifest, failure policy) |
| `tests/05-pages.sh` | Asserts §3 required + conditional pages enumerated |
| `tests/06-sections.sh` | Asserts §3 required sections (sticky header, top bar, open-now indicator, footer, services grid, iconography rule, omission rule) |
| `tests/07-voice.sh` | Asserts §4 Voice section (reading level target, active voice, second person, local-claim rule) |
| `tests/08-banned-phrasings.sh` | Asserts §4 banned-phrasing list is present and complete |
| `tests/09-guardrails.sh` | Asserts §4 factual guardrails, PHI rules, clinical-advice rules, mandated emergency phrase |
| `tests/10-a11y.sh` | Asserts §5 A11y baseline (single H1, landmarks, skip-link, focus, alt rules, contrast ratios, open-now a11y) |
| `tests/11-seo.sh` | Asserts §5 SEO baseline (required head elements, robots/sitemap/llms.txt) |
| `tests/12-schema.sh` | Asserts §5 Schema catalog (Pharmacy/LocalBusiness, FAQPage, BreadcrumbList, Service, MobileApplication; offline-by-default validation) |
| `tests/13-process.sh` | Asserts §6 five-step process (Discover, Scrape, Plan, Generate, Validate) with exit criteria and failure modes |
| `tests/14-checklist.sh` | Asserts the literal closing QA checklist is present with every required line item |
| `tests/15-genericity.sh` | Asserts no pharmacy-specific factual leakage (no `amcare`, no `corona`, no specific Salesforce IDs, no specific URLs from the example build folder) |

---

## Task 1: Repo scaffolding

**Files:**
- Create: `/Users/troy.hammond/Documents/Sites/Replit/pharmacy-builder-kit/.gitignore`
- Create: `/Users/troy.hammond/Documents/Sites/Replit/pharmacy-builder-kit/SKILL.md` (empty)
- Create: `/Users/troy.hammond/Documents/Sites/Replit/pharmacy-builder-kit/README.md` (empty)
- Create: `/Users/troy.hammond/Documents/Sites/Replit/pharmacy-builder-kit/tests/run.sh`
- Create: `/Users/troy.hammond/Documents/Sites/Replit/pharmacy-builder-kit/tests/lib/check.sh`

- [ ] **Step 1: Write `.gitignore`**

```
.DS_Store
~$*
~$*.docx
/build/
/scraped/
node_modules/
*.swp
.idea/
.vscode/
```

- [ ] **Step 2: Create empty `SKILL.md` and `README.md` placeholders**

Write empty files so subsequent tasks have a target.

```bash
: > SKILL.md
: > README.md
```

- [ ] **Step 3: Write `tests/lib/check.sh` assertion helpers**

```bash
#!/usr/bin/env bash
# tests/lib/check.sh
# Shared assertion helpers for SKILL.md structural tests.
# Each function exits the test script with code 1 on failure and
# echoes a clear FAIL line including the test name and offending value.

SKILL_FILE="${SKILL_FILE:-SKILL.md}"

_fail() {
  local test_name="$1"
  local reason="$2"
  echo "  FAIL [$test_name]: $reason"
  exit 1
}

assert_file_exists() {
  local path="$1"
  local test_name="${2:-file-exists}"
  [[ -f "$path" ]] || _fail "$test_name" "expected file at $path"
}

assert_contains() {
  local needle="$1"
  local test_name="${2:-contains}"
  local file="${3:-$SKILL_FILE}"
  grep -F -q -- "$needle" "$file" \
    || _fail "$test_name" "$file is missing literal: $needle"
}

assert_contains_regex() {
  local pattern="$1"
  local test_name="${2:-contains-regex}"
  local file="${3:-$SKILL_FILE}"
  grep -E -q -- "$pattern" "$file" \
    || _fail "$test_name" "$file is missing pattern: $pattern"
}

assert_not_contains() {
  local needle="$1"
  local test_name="${2:-not-contains}"
  local file="${3:-$SKILL_FILE}"
  if grep -F -q -i -- "$needle" "$file"; then
    _fail "$test_name" "$file unexpectedly contains: $needle"
  fi
}

assert_count_at_least() {
  local pattern="$1"
  local min="$2"
  local test_name="${3:-count-at-least}"
  local file="${4:-$SKILL_FILE}"
  local actual
  actual=$(grep -F -c -- "$pattern" "$file" || true)
  if [[ "$actual" -lt "$min" ]]; then
    _fail "$test_name" "expected >= $min occurrences of '$pattern' in $file; found $actual"
  fi
}

pass() {
  echo "  ok  $1"
}
```

- [ ] **Step 4: Write `tests/run.sh` runner**

```bash
#!/usr/bin/env bash
# tests/run.sh
# Run every tests/NN-*.sh in order. Halt on first failure.
set -euo pipefail

cd "$(dirname "$0")/.."

export SKILL_FILE="SKILL.md"
shopt -s nullglob

any=0
fail=0
for t in tests/[0-9]*.sh; do
  any=1
  name="$(basename "$t" .sh)"
  echo "▶ $name"
  if bash "$t"; then
    : # individual tests print their own ok/fail lines
  else
    fail=1
    break
  fi
done

if [[ $any -eq 0 ]]; then
  echo "No tests found in tests/"
  exit 2
fi

if [[ $fail -eq 0 ]]; then
  echo "✓ all tests passed"
else
  echo "✗ test run failed"
  exit 1
fi
```

- [ ] **Step 5: Make scripts executable**

Run: `chmod +x tests/run.sh tests/lib/check.sh`

- [ ] **Step 6: Run the test harness to confirm it works with zero tests**

Run: `bash tests/run.sh`
Expected: prints `No tests found in tests/` and exits with code 2.

- [ ] **Step 7: Commit**

```bash
git add .gitignore SKILL.md README.md tests/run.sh tests/lib/check.sh
git commit -m "chore: scaffold pharmacy-builder-kit with empty SKILL.md and shell test harness"
```

---

## Task 2: Frontmatter test + SKILL.md frontmatter

**Files:**
- Create: `tests/01-frontmatter.sh`
- Modify: `SKILL.md` (add YAML frontmatter)

- [ ] **Step 1: Write the failing test**

Create `tests/01-frontmatter.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

assert_file_exists "$SKILL_FILE" "01-frontmatter:file-exists"

# Frontmatter delimiters
assert_contains_regex '^---$' "01-frontmatter:opening-delimiter"

# Required frontmatter keys
assert_contains_regex '^name: pharmacy-builder$' "01-frontmatter:name"
assert_contains_regex '^description:' "01-frontmatter:description-key"

# Description must include trigger phrases
assert_contains "build pharmacy site" "01-frontmatter:trigger-pharmacy-site"
assert_contains "build pharmacy website" "01-frontmatter:trigger-pharmacy-website"
assert_contains "pharmacy build sheet" "01-frontmatter:trigger-build-sheet"
assert_contains "Lumistry pharmacy build" "01-frontmatter:trigger-lumistry"

pass "01-frontmatter"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/01-frontmatter.sh`
Expected: FAIL on `01-frontmatter:opening-delimiter` (SKILL.md is empty).

- [ ] **Step 3: Add frontmatter to SKILL.md**

Write the top of `SKILL.md`:

```markdown
---
name: pharmacy-builder
description: Build a clean, modern, accessible, factually faithful pharmacy website from a build folder. Use when the user asks to "build a pharmacy site," "build a pharmacy website," generate a site from a "pharmacy build sheet," kick off a "Lumistry pharmacy build," or names a known template label such as "Longhorn." The skill takes a path to a build folder containing a build sheet (.docx) plus optional supporting docs and a logo, scrapes the pharmacy's existing live site for facts and assets, and produces a multi-page site that satisfies a strict output contract (required pages, WCAG 2.2 AA accessibility, SEO + JSON-LD schema, voice and PHI guardrails). Stack-agnostic — the agent picks the framework.
---

# Pharmacy Builder Skill
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/run.sh`
Expected: `▶ 01-frontmatter` then `ok 01-frontmatter` then `✓ all tests passed`.

- [ ] **Step 5: Commit**

```bash
git add tests/01-frontmatter.sh SKILL.md
git commit -m "feat(skill): add frontmatter with trigger phrases"
```

---

## Task 3: Section-headings test + SKILL.md skeleton

**Files:**
- Create: `tests/02-section-headings.sh`
- Modify: `SKILL.md` (add all top-level section headings)

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# tests/02-section-headings.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Contract half
assert_contains_regex '^## Inputs$' "02-headings:inputs"
assert_contains_regex '^## Scrape$' "02-headings:scrape"
assert_contains_regex '^## Required pages$' "02-headings:pages"
assert_contains_regex '^## Required sections$' "02-headings:sections"
assert_contains_regex '^## Voice$' "02-headings:voice"
assert_contains_regex '^## Banned phrasings$' "02-headings:banned"
assert_contains_regex '^## Factual guardrails$' "02-headings:facts"
assert_contains_regex '^## PHI rules$' "02-headings:phi"
assert_contains_regex '^## Accessibility \(WCAG 2.2 AA\)$' "02-headings:a11y"
assert_contains_regex '^## SEO$' "02-headings:seo"
assert_contains_regex '^## Schema \(JSON-LD\)$' "02-headings:schema"

# Process half
assert_contains_regex '^## Process$' "02-headings:process"
assert_contains_regex '^## QA self-validation checklist$' "02-headings:qa"

pass "02-section-headings"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/02-section-headings.sh`
Expected: FAIL on first missing heading (`02-headings:inputs`).

- [ ] **Step 3: Add the skeleton — all headings only, no content**

Append to `SKILL.md` after the H1:

```markdown

> The Contract half (below) defines what the build must satisfy. The Process half at the end defines the order in which steps run. Every step in Process references a Contract section by name. Read the whole document before starting a build.

## Inputs

## Scrape

## Required pages

## Required sections

## Voice

## Banned phrasings

## Factual guardrails

## PHI rules

## Accessibility (WCAG 2.2 AA)

## SEO

## Schema (JSON-LD)

## Process

## QA self-validation checklist
```

- [ ] **Step 4: Run to verify it passes**

Run: `bash tests/run.sh`
Expected: both `01-frontmatter` and `02-section-headings` pass.

- [ ] **Step 5: Commit**

```bash
git add tests/02-section-headings.sh SKILL.md
git commit -m "feat(skill): scaffold all top-level section headings"
```

---

## Task 4: §1 Inputs section

**Files:**
- Create: `tests/03-inputs.sh`
- Modify: `SKILL.md` (fill `## Inputs`)

**Source of truth:** spec section "Section 1 — Skeleton & input contract." Reproduce it as instructions to Replit Agent — present tense, second person, imperative ("Scan the folder. Identify the build sheet by filename containing 'Build Sheet.'").

- [ ] **Step 1: Write the failing test**

```bash
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

pass "03-inputs"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/03-inputs.sh`
Expected: FAIL on `03-inputs:invocation`.

- [ ] **Step 3: Write the `## Inputs` section content**

Replace the empty `## Inputs` heading body in `SKILL.md` with prose covering, in order:

1. Invocation: "You are given a path to a build folder. Scan it and resolve every file before doing anything else."
2. Required vs optional file table (`Build Sheet *.docx` Required by filename match; Logo Required from root or `Logo:` URL in build sheet; `Website content*.docx`, `QA *.docx`, `SEO_META_Tags_*.docx` Optional; extra media optional; `~$*.docx` lockfiles ignored).
3. Enumerated build-sheet fields to extract (full list per spec §1, exhaustive — match every field listed in the test).
4. Conditional flags and what they trigger (Mobile App Page → `/app/`; refill portal URL → wire Refill CTA; transfer form requirement → `/transfer/` CTA-only; pickup methods → `/refill/` copy; additional locations → `/locations/`).
5. "Template" label policy (label/hint only; not binding).
6. Output: write a single `build/context.json` consolidating every parsed field with provenance per field (`build_sheet | content_doc | qa_doc | seo_doc | scrape`) and explicit `null` with `nullReason` for absent fields.

Content must satisfy every assertion in the test. After writing, every required field name must appear at least once in the section.

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: `01-frontmatter`, `02-section-headings`, `03-inputs` all pass.

- [ ] **Step 5: Commit**

```bash
git add tests/03-inputs.sh SKILL.md
git commit -m "feat(skill): add Inputs contract section"
```

---

## Task 5: §2 Scrape section

**Files:**
- Create: `tests/04-scrape.sh`
- Modify: `SKILL.md` (fill `## Scrape`)

**Source of truth:** spec section 2.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# tests/04-scrape.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Goal language
assert_contains "fact source" "04-scrape:fact-source"
assert_contains "not a" "04-scrape:not-design-source"

# Script name
assert_contains "tools/scrape.mjs" "04-scrape:script-name"

# Crawl rules
assert_contains "same-origin" "04-scrape:same-origin"
assert_contains "depth" "04-scrape:depth"
assert_contains "200 pages" "04-scrape:max-pages"
assert_contains "1 req/sec" "04-scrape:rate-limit"
assert_contains "robots.txt" "04-scrape:robots"

# Assets
for ext in ".pdf" ".docx" ".mp4" ".webm"; do
  assert_contains "$ext" "04-scrape:asset-$ext"
done

# Outputs
assert_contains "/scraped/manifest.json" "04-scrape:manifest"
assert_contains "/scraped/raw/" "04-scrape:raw-html"
assert_contains "/scraped/text/" "04-scrape:text-md"
assert_contains "/scraped/assets/" "04-scrape:assets-dir"

# Failure handling
assert_contains "unreachable" "04-scrape:unreachable"
assert_contains "no silent fallback" "04-scrape:no-silent-fallback"

# Conflict policy
assert_contains "Build sheet wins" "04-scrape:build-sheet-wins"

# PHI / hyperbole filtering rules apply to scraped content too
assert_contains "PHI" "04-scrape:phi-redact"

pass "04-scrape"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/04-scrape.sh`
Expected: FAIL on `04-scrape:fact-source`.

- [ ] **Step 3: Write the `## Scrape` section**

Fill `## Scrape` in `SKILL.md` with prose, in order:

1. Goal — mirror the build sheet's `Website URL` field (the pharmacy's existing live site) to `/scraped/` as a fact source, not a design source.
2. Mechanics — write `tools/scrape.mjs` matching the contract: seed = `Website URL`; same-origin only; depth ≤ 3; max 200 pages; 1 req/sec polite; descriptive User-Agent; respect source `robots.txt`; skip `mailto:`/`tel:`/anchors/trackers.
3. Asset capture — every `<img>`, `<source>`, `<video>`, and `<a href>` ending in `.pdf`, `.docx`, `.mp4`, `.webm`, or image extensions; download to `/scraped/assets/` with collision-safe filenames.
4. Content capture — raw HTML at `/scraped/raw/<slug>.html`; reader-mode markdown at `/scraped/text/<slug>.md`.
5. Manifest — `/scraped/manifest.json` with URL, status, final URL, title, h1, word count, asset list, outbound internal links per page.
6. Failure handling — if unreachable, log `scrape_status: "unreachable"` to `/build/log.md` and continue with build-sheet-only content. No silent fallback.
7. Allowed uses — fact source (claimed services, awards, staff names, hours phrasing — all still subject to §Factual guardrails); PDFs that may be linked from the new site; storefront/team/product images with generated alt text.
8. Disallowed uses — overriding the build sheet on conflict (Build sheet wins; log conflicts); carrying over PHI; carrying over marketing hyperbole, comparative claims, clinical claims, or unverified credentials (filtered per §Voice and §Factual guardrails).
9. Handoff — `/scraped/manifest.json` + `/scraped/text/*.md` feed the Plan and Generate steps.

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all four tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/04-scrape.sh SKILL.md
git commit -m "feat(skill): add Scrape contract section"
```

---

## Task 6: §3 Required pages

**Files:**
- Create: `tests/05-pages.sh`
- Modify: `SKILL.md` (fill `## Required pages`)

**Source of truth:** spec section 3, "Required pages" + "Conditionally built."

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# tests/05-pages.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Always-built pages with URLs
for entry in "Home" "/about/" "/contact/" "/services/" "/services/<slug>/" "/refill/" "/transfer/" "/faq/"; do
  assert_contains "$entry" "05-pages:always-$entry"
done

# Conditional pages
assert_contains "/app/" "05-pages:app-page"
assert_contains "Apple App Store" "05-pages:apple-badge"
assert_contains "Google Play" "05-pages:google-badge"
assert_contains "/locations/" "05-pages:locations-page"
assert_contains "150 substantive words" "05-pages:scrape-discovery-threshold"

# Transfer page is CTA-only
assert_contains "no PHI form" "05-pages:transfer-no-phi"
assert_contains "CTA" "05-pages:transfer-cta"

pass "05-pages"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/05-pages.sh`
Expected: FAIL on `05-pages:always-Home`.

- [ ] **Step 3: Write the `## Required pages` section**

Use a Markdown table per spec §3 covering the eight always-built pages with their URLs and one-line purposes, plus a second table or list for the three conditionally-built page rules:

- `Requires Mobile App Page: Yes` → `/app/` with the real Apple App Store badge and Google Play badge (correct artwork per each store's brand guidelines).
- `Additional locations? Yes` → `/locations/` index + `/locations/<slug>/` per location.
- Scrape-discovered pages → `/<slug>/` only when the scraped page has ≥ 150 substantive words AND isn't a contact/hours rehash. Otherwise drop.

Per-service pages: deep treatment for build-sheet "Topics" entries; shallow card-only for "List" entries. Restate "Transfer page is CTA + outbound link only — no PHI form."

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all five tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/05-pages.sh SKILL.md
git commit -m "feat(skill): add Required pages contract section"
```

---

## Task 7: §3 Required sections (header, top bar, footer, home, contact, per-service)

**Files:**
- Create: `tests/06-sections.sh`
- Modify: `SKILL.md` (fill `## Required sections`)

**Source of truth:** spec section 3 from "Required sections — every page" onward, plus the iconography rule and omission rule.

- [ ] **Step 1: Write the failing test**

```bash
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

pass "06-sections"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/06-sections.sh`
Expected: FAIL on `06-sections:sticky-header`.

- [ ] **Step 3: Write the `## Required sections` content**

Cover in order, with subheadings:

1. **Every page** — sticky header (logo, primary nav with services dropdown, three CTAs: Refill / Transfer / Patient Portal); top bar with address, phone, hours, open-now indicator (computed in the browser from build-sheet `Hours:` against `Date.now()` in pharmacy local TZ; falls back to "Open/Closed unavailable" if JS disabled; never invents); FAQs near the bottom; footer (address, phone, hours, social if scraped, NPI/licenses only if found in source, copyright, accessibility statement, sitemap link).
2. **Home only** — hero with build-sheet tagline + primary CTA; services grid with unique iconography (single icon set, line style ~24×24, single-stroke, recolorable via `currentColor`); hours of operation block (semantic table); trust callouts (no comparative claims); testimonials (omitted if absent — never fabricated); app download row (only if Mobile App Page enabled).
3. **Contact only** — clickable address/phone/fax/email; map embed using build sheet `Google Map URL`; "Get directions" link to Google Maps in a new tab; no form; hours; FAQs.
4. **Per-service page** — H1 = service name; verbatim build-sheet description + scraped detail if available; Immunizations specifically lists `Immunization Options` from the build sheet exactly — never extend; CTA appropriate to the service; FAQs scoped to the service.
5. **Iconography rule** — one coherent icon set, same set used in services grid AND header dropdown, brand-colored via `currentColor`.
6. **Section omission rule** — any required section whose content can't be sourced is omitted, not stubbed. No "Lorem ipsum," no "Coming soon," no fake content.

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all six tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/06-sections.sh SKILL.md
git commit -m "feat(skill): add Required sections contract"
```

---

## Task 8: §4 Voice

**Files:**
- Create: `tests/07-voice.sh`
- Modify: `SKILL.md` (fill `## Voice`)

**Source of truth:** spec section 4 — Voice subsection.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# tests/07-voice.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

assert_contains "8th-grade" "07-voice:reading-level"
assert_contains "Flesch-Kincaid" "07-voice:flesch-kincaid"
assert_contains "Active voice" "07-voice:active-voice"
assert_contains "Second person" "07-voice:second-person"
assert_contains "Warm" "07-voice:warm"
assert_contains "not casual" "07-voice:not-casual"
assert_contains "Practical" "07-voice:practical"
assert_contains "local-color" "07-voice:local-color"
assert_contains "only if backed by" "07-voice:local-claim-rule"

pass "07-voice"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/07-voice.sh`
Expected: FAIL on `07-voice:reading-level`.

- [ ] **Step 3: Write the `## Voice` section**

Write per spec §4 Voice:

- Plain language, ~8th-grade reading level (target Flesch-Kincaid ≥ 70).
- Short sentences. Active voice. Second person ("you can get your refill") not third.
- Warm but not casual. Friendly, not flippant.
- Practical: tell the patient what to do, where to go, what to expect.
- Local-color claims (community, neighborhood, family-owned, independent) only if backed by build sheet or scrape. Apply the same test to every local-color claim.

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all seven tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/07-voice.sh SKILL.md
git commit -m "feat(skill): add Voice contract section"
```

---

## Task 9: §4 Banned phrasings

**Files:**
- Create: `tests/08-banned-phrasings.sh`
- Modify: `SKILL.md` (fill `## Banned phrasings`)

**Source of truth:** spec section 4 — Banned phrasings list.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# tests/08-banned-phrasings.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Marketing hyperbole
for phrase in \
  "revolutionary" \
  "world-class" \
  "best-in-class" \
  "cutting-edge" \
  "state-of-the-art" \
  "industry-leading" \
  "premier" \
  "award-winning" \
  "voted #1" \
  "top-rated"
do
  assert_contains "$phrase" "08-banned:hyperbole-$phrase"
done

# Clinical / comparative claims
for phrase in \
  "proven to" \
  "cures" \
  "guarantees" \
  "safest" \
  "fastest"
do
  assert_contains "$phrase" "08-banned:clinical-$phrase"
done

# Operational overreach
for phrase in \
  "all insurance" \
  "any insurance" \
  "every insurance" \
  "24-hour" \
  "24/7" \
  "same-day delivery" \
  "free delivery"
do
  assert_contains "$phrase" "08-banned:operational-$phrase"
done

# Credentials
for phrase in \
  "board-certified" \
  "PharmD" \
  "RPh"
do
  assert_contains "$phrase" "08-banned:credentials-$phrase"
done

# Comparative + clinical-advice patterns
assert_contains "unlike CVS" "08-banned:comparative-cvs"
assert_contains "you should take" "08-banned:clinical-advice-pattern"

# Verification mechanism
assert_contains "tools/validate-content.mjs" "08-banned:validator"
assert_contains "fail build" "08-banned:fail-build"

pass "08-banned-phrasings"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/08-banned-phrasings.sh`
Expected: FAIL on `08-banned:hyperbole-revolutionary`.

- [ ] **Step 3: Write the `## Banned phrasings` section**

Structure as four labeled groups (Hyperbole, Clinical/comparative, Operational, Credentials), each as a bullet list — every literal phrase from the test must appear verbatim. Close with a paragraph naming `tools/validate-content.mjs` as the verification mechanism that scans all generated HTML, fails the build on any hit, and writes line-numbered evidence to `/build/log.md`. Include the conditional unlock note: a banned phrase is allowed only when its exact wording appears verbatim in the build sheet or scrape (e.g., "FREE local delivery" when a build sheet contains that exact phrase).

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all eight tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/08-banned-phrasings.sh SKILL.md
git commit -m "feat(skill): add Banned phrasings list with verification hook"
```

---

## Task 10: §4 Factual guardrails + PHI rules + clinical advice

**Files:**
- Create: `tests/09-guardrails.sh`
- Modify: `SKILL.md` (fill `## Factual guardrails` and `## PHI rules`)

**Source of truth:** spec section 4 — Factual guardrails, PHI rules, Clinical advice.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# tests/09-guardrails.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Factual non-fabricatable list
for field in \
  "Hours" \
  "address" \
  "phone" \
  "fax" \
  "email" \
  "Staff names" \
  "credentials" \
  "residencies" \
  "awards" \
  "licenses" \
  "NPI" \
  "NCPDP" \
  "DEA" \
  "Services offered" \
  "Insurance plans" \
  "Years in business"
do
  assert_contains "$field" "09-guardrails:field-$field"
done

assert_contains "omitted" "09-guardrails:omitted"

# PHI rules
assert_contains "never collect" "09-guardrails:phi-never-collect"
for forbidden_input in \
  'name="dob"' \
  'name="rx_number"' \
  'name="member_id"' \
  'name="medication"'
do
  assert_contains "$forbidden_input" "09-guardrails:phi-input-$forbidden_input"
done

assert_contains "PHI scanner" "09-guardrails:phi-scanner"

# Transfer page restated as CTA-only
assert_contains "Transfer page" "09-guardrails:transfer-page"

# Clinical advice
assert_contains "Never tell a patient" "09-guardrails:no-clinical-advice"

# Mandated emergency phrase (exact)
assert_contains "Call 911 or go to the nearest emergency room." "09-guardrails:emergency-phrase"
assert_contains "only allowed" "09-guardrails:only-allowed-emergency"

pass "09-guardrails"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/09-guardrails.sh`
Expected: FAIL on `09-guardrails:field-Hours`.

- [ ] **Step 3: Write the `## Factual guardrails` section**

Bullet list of every non-fabricatable field (Hours, address, phone, fax, email, Staff names, credentials, residencies, board certifications, awards, licenses, NPI, NCPDP, DEA, Services offered, Insurance plans accepted, Years in business, refill/transfer/portal URLs, any legal claim). End with: "If a field is not in the build sheet or scrape, the corresponding section is omitted, not stubbed."

- [ ] **Step 4: Write the `## PHI rules` section**

Cover in order:

1. The site must never collect, request, store, or output PHI.
2. Specifically prohibited on public forms: full names paired with medications/conditions, DOB, medical record numbers, Rx numbers, diagnosis text, insurance member IDs.
3. Transfer page is CTA + outbound link only — no fields requesting medication name, Rx number, or DOB. If the scraped source has such a form, do not port it; replace with "Call us at `<phone>` to transfer."
4. Contact page has no form.
5. PHI scanner step: run as part of validation; greps every generated HTML for `name="dob"`, `name="rx_number"`, `name="member_id"`, `name="medication"`, `input[type=date]` inside `<form>`, and bare `<form>` elements that don't point to external URLs → fail the build on any hit.
6. Clinical advice: never tell a patient what to take, when to stop, what a symptom means. For emergency mentions, use only the literal phrase: "Call 911 or go to the nearest emergency room." Nothing else. That is the only allowed emergency copy block.

- [ ] **Step 5: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all nine tests pass.

- [ ] **Step 6: Commit**

```bash
git add tests/09-guardrails.sh SKILL.md
git commit -m "feat(skill): add Factual guardrails + PHI rules + emergency phrase"
```

---

## Task 11: §5 Accessibility baseline

**Files:**
- Create: `tests/10-a11y.sh`
- Modify: `SKILL.md` (fill `## Accessibility (WCAG 2.2 AA)`)

**Source of truth:** spec section 5 — Accessibility.

- [ ] **Step 1: Write the failing test**

```bash
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
assert_contains "lang=\"en\"" "10-a11y:lang-en"

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
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/10-a11y.sh`
Expected: FAIL on `10-a11y:single-h1`.

- [ ] **Step 3: Write the `## Accessibility (WCAG 2.2 AA)` section**

Subsections in order: **Structural** (single H1; never skip heading levels; landmarks `<header>`/`<nav>`/`<main>`/`<footer>`; skip-link as first focusable element; real `<button>`/`<a>` — never `<div onclick>`; tab order matches visual order; Esc closes dropdowns; Enter/Space activates buttons; visible focus state with ≥ 2px outline and ≥ 3:1 contrast; never `outline: none` unbalanced; sticky header doesn't trap focus). **Content** (every `<img>` has `alt`; substantive images use object + context pattern, e.g., "Pharmacist counseling a patient at the pharmacy counter"; decorative images `alt=""`; logo alt = `<Pharmacy Name> logo` from build sheet; no image-only text for substantive content; icons `aria-hidden="true"` with adjacent text label; `<html lang="en">` always). **Contrast** (body text ≥ 4.5:1; large text ≥ 3:1; brand color used for accents; if brand can't reach 4.5:1 against white, body text falls back to `#111111` and brand stays accent-only — the skill auto-darkens accents to maintain AA; contrast check script). **Open-now a11y** (text label AND color cue; `aria-live="polite"`; never color-only). Close by naming `tools/validate-a11y.mjs` as the validator that checks landmarks, heading order, alt presence, focus styles, contrast computation, and keyboard reachability of the services dropdown.

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all ten tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/10-a11y.sh SKILL.md
git commit -m "feat(skill): add Accessibility (WCAG 2.2 AA) baseline"
```

---

## Task 12: §5 SEO baseline + site-wide files

**Files:**
- Create: `tests/11-seo.sh`
- Modify: `SKILL.md` (fill `## SEO`)

**Source of truth:** spec section 5 — SEO.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# tests/11-seo.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Head elements
assert_contains "<title>" "11-seo:title"
assert_contains "60 chars" "11-seo:title-length"
assert_contains "<meta name=\"description\">" "11-seo:description"
assert_contains "140" "11-seo:description-min"
assert_contains "160" "11-seo:description-max"
assert_contains "<link rel=\"canonical\"" "11-seo:canonical"
assert_contains "New Website URL" "11-seo:canonical-root"
assert_contains "Open Graph" "11-seo:open-graph"
assert_contains "og:title" "11-seo:og-title"
assert_contains "og:description" "11-seo:og-description"
assert_contains "og:url" "11-seo:og-url"
assert_contains "og:type" "11-seo:og-type"
assert_contains "og:image" "11-seo:og-image"
assert_contains "1200x630" "11-seo:og-image-size"
assert_contains "twitter:card" "11-seo:twitter-card"
assert_contains "theme-color" "11-seo:theme-color"

# SEO_META doc verbatim use
assert_contains "SEO_META_Tags" "11-seo:seo-meta-doc"
assert_contains "verbatim" "11-seo:verbatim"

# Site-wide files
assert_contains "robots.txt" "11-seo:robots"
assert_contains "sitemap.xml" "11-seo:sitemap"
assert_contains "llms.txt" "11-seo:llms"
assert_contains "lastmod" "11-seo:lastmod"

pass "11-seo"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/11-seo.sh`
Expected: FAIL on `11-seo:title`.

- [ ] **Step 3: Write the `## SEO` section**

Subsections in order: **Required `<head>` elements** (per spec — title pattern; ≤ 60 chars; meta description 140–160 chars; canonical with root from build sheet `New Website URL`; exactly one `<h1>`; full Open Graph set; Twitter card basics; viewport, charset, theme-color = brand color; if `SEO_META_Tags_*.docx` supplies per-page titles, use verbatim and skip the pattern). **Site-wide files** (robots.txt allows all, references sitemap; sitemap.xml with every page, `lastmod` = build date, priorities 1.0/0.8/0.6; llms.txt per the llms.txt spec — `# <Pharmacy Name>`, short description, sectioned link lists Pages/Services/About).

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all eleven tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/11-seo.sh SKILL.md
git commit -m "feat(skill): add SEO baseline + site-wide file rules"
```

---

## Task 13: §5 Schema catalog (JSON-LD)

**Files:**
- Create: `tests/12-schema.sh`
- Modify: `SKILL.md` (fill `## Schema (JSON-LD)`)

**Source of truth:** spec section 5 — Schema catalog.

- [ ] **Step 1: Write the failing test**

```bash
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
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/12-schema.sh`
Expected: FAIL on `12-schema:pharmacy`.

- [ ] **Step 3: Write the `## Schema (JSON-LD)` section**

Subsections: **Every page** (Pharmacy extending LocalBusiness with the listed properties; geo only when already present in source/scrape — no external geocoding; WebPage with `name`/`description`/`url`/`inLanguage=en`/`isPartOf`; BreadcrumbList on non-home pages; FAQPage with Q/A from build sheet/scrape/QA doc — never invented). **Page-specific** (home WebSite with SearchAction only if real on-site search exists; per-service Service with provider→Pharmacy, serviceType, areaServed, description; contact explicit ContactPoint array; app page MobileApplication with real App Store + Google Play URLs from build sheet). **Validation** — `tools/validate-schema.mjs` extracts every `<script type="application/ld+json">`, parses each (fails on parse error), validates required properties against a schema map the skill includes inline, and posts to Google's Rich Results test only if `--online` flag is set. Default: offline.

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all twelve tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/12-schema.sh SKILL.md
git commit -m "feat(skill): add JSON-LD schema catalog + offline validator contract"
```

---

## Task 14: §6 Five-step process

**Files:**
- Create: `tests/13-process.sh`
- Modify: `SKILL.md` (fill `## Process`)

**Source of truth:** spec section 6 — The 5-step process.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# tests/13-process.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Step headers exist with correct labels
for step in \
  "Step 1 — Discover" \
  "Step 2 — Scrape" \
  "Step 3 — Plan" \
  "Step 4 — Generate" \
  "Step 5 — Validate"
do
  assert_contains "$step" "13-process:$step"
done

# Discover specifics
assert_contains "build/context.json" "13-process:context-json"
assert_contains "nullReason" "13-process:null-reason"

# Plan specifics
assert_contains "/build/page-plan.json" "13-process:page-plan"

# Generate specifics
assert_contains "head JS snippet" "13-process:head-js"
assert_contains "GA ID" "13-process:ga"

# Validate specifics
assert_contains "tools/validate-content.mjs" "13-process:val-content"
assert_contains "tools/validate-a11y.mjs" "13-process:val-a11y"
assert_contains "tools/validate-schema.mjs" "13-process:val-schema"

# Failure-mode language
assert_contains "no silent fallback" "13-process:no-silent-fallback"
assert_contains "do not declare done" "13-process:no-declare-done"

pass "13-process"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/13-process.sh`
Expected: FAIL on `13-process:Step 1 — Discover`.

- [ ] **Step 3: Write the `## Process` section**

Five subsections per spec §6. Each step lists: Input, Action, Exit criteria, Failure mode. Discover writes `build/context.json` with `nullReason` for absent fields. Scrape produces `manifest.json` or logs `scrape_status: "unreachable"` — no silent fallback. Plan produces `/build/page-plan.json`. Generate scaffolds the project, generates each page, writes `robots.txt`/`sitemap.xml`/`llms.txt`, wires head JS snippet + GA ID + brand color + Refill/Transfer/Patient Portal CTAs from the build sheet. Validate runs all three validators and the structural check; any FAIL halts the build — do not declare done.

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all thirteen tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/13-process.sh SKILL.md
git commit -m "feat(skill): add 5-step Process with explicit exit criteria"
```

---

## Task 15: §6 QA self-validation checklist (literal closing artifact)

**Files:**
- Create: `tests/14-checklist.sh`
- Modify: `SKILL.md` (fill `## QA self-validation checklist`)

**Source of truth:** spec section 6 — the literal checklist.

- [ ] **Step 1: Write the failing test**

```bash
#!/usr/bin/env bash
# tests/14-checklist.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Group headers
for group in \
  "INPUTS" \
  "SCRAPE" \
  "PAGES" \
  "HEADER / SITE-WIDE SECTIONS" \
  "A11Y (WCAG 2.2 AA)" \
  "SEO + SCHEMA" \
  "CONTENT GUARDRAILS" \
  "WIRING" \
  "RESULT"
do
  assert_contains "$group" "14-checklist:group-$group"
done

# Spot-check critical line items
assert_contains "[ ] Build sheet parsed" "14-checklist:input-line"
assert_contains "[ ] Source site mirrored" "14-checklist:scrape-line"
assert_contains "[ ] Home, About, Contact" "14-checklist:pages-line"
assert_contains "[ ] Sticky header" "14-checklist:header-line"
assert_contains "[ ] Single H1 per page" "14-checklist:a11y-line"
assert_contains "[ ] robots.txt, sitemap.xml, llms.txt generated" "14-checklist:seo-line"
assert_contains "[ ] Banned phrasing scan: zero hits" "14-checklist:guardrails-line"
assert_contains "[ ] Refill CTA -> build sheet refill portal URL" "14-checklist:wiring-line"
assert_contains "[ ] All three validators PASS" "14-checklist:result-line"

# Reproduction directive
assert_contains "must reproduce" "14-checklist:must-reproduce"
assert_contains "build/log.md" "14-checklist:build-log"
assert_contains "Any unchecked box" "14-checklist:any-unchecked"

pass "14-checklist"
```

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/14-checklist.sh`
Expected: FAIL on `14-checklist:group-INPUTS`.

- [ ] **Step 3: Write the `## QA self-validation checklist` section**

A short lead paragraph: "Before declaring the build complete, reproduce this checklist in `/build/log.md` with each box checked. Any unchecked box = build not done."

Then paste the literal checklist block from spec §6 verbatim — every group header and every line item, exactly as written (use ASCII `->` not Unicode arrows; use `>= 4.5:1` not `≥`; those are the literal forms the test greps for).

- [ ] **Step 4: Run to verify all tests pass**

Run: `bash tests/run.sh`
Expected: all fourteen tests pass.

- [ ] **Step 5: Commit**

```bash
git add tests/14-checklist.sh SKILL.md
git commit -m "feat(skill): add closing QA self-validation checklist"
```

---

## Task 16: Genericity test (no pharmacy-specific leakage)

**Files:**
- Create: `tests/15-genericity.sh`

**Why:** the spec was scrubbed of AmCare-specific data and the SKILL.md must remain pharmacy-agnostic. This is the regression guard.

- [ ] **Step 1: Write the test**

```bash
#!/usr/bin/env bash
# tests/15-genericity.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Banned literal references to the example build
for needle in \
  "amcare" \
  "amcarerxpharmacy" \
  "amcarerxpharmacy.com" \
  "AMCare" \
  "AmCare" \
  "Corona, CA" \
  "0014v00002ZifNlAAJ" \
  "951-268-6486" \
  "G-JGCM348B13"
do
  assert_not_contains "$needle" "15-genericity:no-$needle"
done

pass "15-genericity"
```

- [ ] **Step 2: Run to verify it passes (SKILL.md should already be clean)**

Run: `bash tests/run.sh`
Expected: all fifteen tests pass.

If any genericity assertion fails: the offending value leaked from the spec into SKILL.md during one of the earlier tasks. Remove it inline and rerun.

- [ ] **Step 3: Commit**

```bash
git add tests/15-genericity.sh
git commit -m "test(skill): add regression guard against pharmacy-specific leakage"
```

---

## Task 17: README — operator instructions

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Write the README**

```markdown
# pharmacy-builder-kit

A single-file skill that instructs Replit Agent (or Claude) to build a clean, modern, accessible, factually faithful pharmacy website from a build folder.

The deliverable is [`SKILL.md`](SKILL.md). The skill is stack-agnostic — the agent picks the framework.

## What's in this repo

| Path | Purpose |
|---|---|
| `SKILL.md` | The skill itself. Paste this into Replit Agent as the system prompt, or commit it into your Replit project as a skill. |
| `README.md` | This file. |
| `docs/superpowers/specs/` | Design spec the SKILL.md was built from. Authoritative for any future revisions. |
| `docs/superpowers/plans/` | Implementation plan used to build the SKILL.md. |
| `tests/` | Shell-based structural tests that verify SKILL.md satisfies the spec. |

## How to use it

1. Assemble a **build folder** for the pharmacy. At minimum it must contain:
   - A build sheet (`.docx`) whose filename contains `Build Sheet`.
   - A logo file (PNG / JPG / SVG) — either in the folder root, or fetched from the `Logo:` URL in the build sheet.
2. Optionally include any of: `Website content*.docx`, `QA *.docx`, `SEO_META_Tags_*.docx`, and any additional photos / PDFs / videos. The skill auto-detects them.
3. In Replit, open or create the project. Paste the contents of `SKILL.md` as the agent's system prompt (or place the file in `.replit/skills/` if your Replit instance supports loaded skills).
4. Tell the agent the path to the build folder. The skill drives the rest:
   - **Discover** — parses the build sheet into `build/context.json`.
   - **Scrape** — mirrors the pharmacy's existing live site (per the `Website URL` field) into `/scraped/`.
   - **Plan** — writes `/build/page-plan.json` enumerating every page and section.
   - **Generate** — scaffolds the project (agent picks the stack), generates each page, writes `robots.txt`/`sitemap.xml`/`llms.txt`.
   - **Validate** — runs three validators (content guardrails, accessibility, schema) and reproduces the closing QA checklist in `/build/log.md`.
5. Inspect `/build/log.md`. **If any box is unchecked, the build is not done.**

## Guarantees the skill enforces

- No fabricated facts (hours, address, phone, staff, credentials, licenses, services, insurance, awards, etc.).
- No PHI collection of any kind on public forms.
- WCAG 2.2 AA accessibility baseline (single H1, landmarks, skip-link, visible focus, AA contrast, keyboard-operable services dropdown).
- Per-page SEO baseline (title, description, canonical, OG, Twitter card, single H1).
- JSON-LD schema on every page (Pharmacy/LocalBusiness, WebPage, BreadcrumbList, FAQPage, plus Service / ContactPoint / MobileApplication where relevant).
- `robots.txt` + `sitemap.xml` + `llms.txt` always generated.
- No marketing hyperbole, no comparative claims, no clinical advice. Banned-phrasing scan fails the build on any hit.

## Verifying the SKILL.md after edits

Any change to `SKILL.md` must keep the structural tests passing:

```sh
bash tests/run.sh
```

The tests are grep-based and live under `tests/`. They check that every required contract section, banned phrasing, schema type, accessibility rule, and checklist line item is present.

## Maintaining the skill

The skill's design is captured in `docs/superpowers/specs/2026-05-20-pharmacy-builder-skill-design.md`. If you want to change a rule (e.g., add a new banned phrasing, expand the schema catalog, change the open-now indicator's fallback text):

1. Update the spec.
2. Update or add the corresponding test under `tests/`.
3. Update `SKILL.md` to satisfy the new test.
4. Run `bash tests/run.sh` to verify the whole suite is green.
5. Commit the spec, test, and SKILL.md changes together.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README explaining the kit, the build folder, and how to verify SKILL.md"
```

---

## Task 18: Acceptance — manual end-to-end dry run with the AmCare example

**Files:**
- Create: `docs/superpowers/acceptance/2026-05-20-amcare-dry-run.md`

**Why:** the test suite verifies SKILL.md's structure. It does not verify that an agent reading SKILL.md actually produces a correct site. This task records a manual dry run against the example build folder so future maintainers have a known-good reference.

- [ ] **Step 1: Run a real end-to-end build against the example**

Open Replit Agent (or `claude` in this project), paste `SKILL.md` as the system prompt, and provide:

> Build folder: `/Users/troy.hammond/Downloads/AmCare Pharmacy/`

Let the agent execute Discover → Scrape → Plan → Generate → Validate. Save the full session transcript.

- [ ] **Step 2: Capture observations into the acceptance doc**

Create `docs/superpowers/acceptance/2026-05-20-amcare-dry-run.md` recording:

- The agent's chosen stack and why.
- The contents of `build/context.json` (paste it in).
- The contents of `scraped/manifest.json` (paste it in or summarize).
- The contents of `build/page-plan.json`.
- A short table of generated pages with their `<title>` / `<h1>` / line count.
- The full reproduction of the closing QA checklist from `build/log.md`.
- Any rule the agent struggled to satisfy → file an issue + revise the spec.

This file is the canonical "what does a passing build look like" reference. Keep it in the repo.

- [ ] **Step 3: Commit**

```bash
mkdir -p docs/superpowers/acceptance
git add docs/superpowers/acceptance/2026-05-20-amcare-dry-run.md
git commit -m "docs: capture acceptance dry-run output for the AmCare example build folder"
```

- [ ] **Step 4: Final clean run**

Run `bash tests/run.sh`. Expected: all fifteen tests pass.

If any test fails: fix SKILL.md inline, re-run, and amend the last commit.

---

## Self-review

I read the plan back against the spec. Coverage matrix:

| Spec section | Plan task(s) | Test file(s) |
|---|---|---|
| §1 Skeleton & input contract | T1 scaffold, T2 frontmatter, T3 headings, T4 Inputs | `01-frontmatter.sh`, `02-section-headings.sh`, `03-inputs.sh` |
| §2 Scrape step | T5 | `04-scrape.sh` |
| §3 Pages | T6 | `05-pages.sh` |
| §3 Sections | T7 | `06-sections.sh` |
| §4 Voice | T8 | `07-voice.sh` |
| §4 Banned phrasings | T9 | `08-banned-phrasings.sh` |
| §4 Factual guardrails / PHI / clinical advice | T10 | `09-guardrails.sh` |
| §5 A11y | T11 | `10-a11y.sh` |
| §5 SEO | T12 | `11-seo.sh` |
| §5 Schema | T13 | `12-schema.sh` |
| §6 5-step process | T14 | `13-process.sh` |
| §6 QA checklist | T15 | `14-checklist.sh` |
| Genericity guard (out of any single spec section but required) | T16 | `15-genericity.sh` |
| Operator workflow | T17 | (README) |
| End-to-end acceptance | T18 | manual dry run |

Placeholder scan: every step either shows the exact code/test/content to write, or directs the engineer to a numbered spec section with an enumerated content list and a corresponding test that proves the section is complete. No "TBD," "TODO," or "add appropriate X" anywhere.

Type consistency: validator filenames (`tools/validate-content.mjs`, `tools/validate-a11y.mjs`, `tools/validate-schema.mjs`) match across tasks 9, 11, 13, 14. Output paths (`build/context.json`, `/build/page-plan.json`, `/scraped/manifest.json`, `/build/log.md`) match across tasks 4, 5, 14, 15. Mandated emergency phrase ("Call 911 or go to the nearest emergency room.") is referenced verbatim in task 10 and asserted verbatim in `09-guardrails.sh`.
