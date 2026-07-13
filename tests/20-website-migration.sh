#!/usr/bin/env bash
# tests/20-website-migration.sh
# WEBSITE-MIGRATION-SKILL.md is the migration/rebuild variant of SKILL.md.
# Its head (frontmatter, H1, §Inputs, §Scrape) diverges to describe a
# Replit-produced scraped manifest input; its shared body (from
# `## Required pages` onward) must stay byte-identical to SKILL.md.
# This test guards against drift on both fronts.
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

MIG="$(pwd)/WEBSITE-MIGRATION-SKILL.md"
SKILL="$(pwd)/SKILL.md"

[[ -f "$MIG" ]] || _fail "20-migration:file-exists" "expected WEBSITE-MIGRATION-SKILL.md at $MIG"

# Frontmatter tuned for migration
grep -E -q '^name: website-migration$' "$MIG" \
  || _fail "20-migration:frontmatter-name" "expected name: website-migration"

# Description carries migration triggers and describes the manifest input
for phrase in \
  "migrate a pharmacy site" \
  "rebuild a pharmacy website" \
  "port the existing pharmacy site" \
  "website migration" \
  "site rebuild" \
  "manifest.json" \
  "Replit"
do
  grep -F -q -- "$phrase" "$MIG" \
    || _fail "20-migration:desc-$phrase" "description missing phrase: $phrase"
done

# Description explicitly says there is no build sheet in the migration flow
grep -F -q "no jotform build sheet" "$MIG" \
  || _fail "20-migration:no-build-sheet" "description must state there is no build sheet"

# H1 renamed
grep -F -q "# Website Migration Skill" "$MIG" \
  || _fail "20-migration:h1" "expected '# Website Migration Skill' H1"

# Cross-reference the primary skill so operators know they share the shared body
grep -F -q "same body from \`## Required pages\` onward" "$MIG" \
  || _fail "20-migration:shared-body-note" "description must acknowledge shared body starts at ## Required pages"

# §Inputs describes the manifest folder layout, NOT a docx build sheet
grep -F -q "manifest.json" "$MIG" \
  || _fail "20-migration:inputs-manifest" "Inputs must reference manifest.json"
grep -F -q "scraped/raw/" "$MIG" \
  || _fail "20-migration:inputs-scraped-raw" "Inputs must reference scraped/raw/"
grep -F -q "scraped/text/" "$MIG" \
  || _fail "20-migration:inputs-scraped-text" "Inputs must reference scraped/text/"
grep -F -q "scraped/assets/" "$MIG" \
  || _fail "20-migration:inputs-scraped-assets" "Inputs must reference scraped/assets/"

# §Inputs must NOT list the build sheet or logo file as required inputs
head -n 125 "$MIG" | grep -F -q "Build Sheet" \
  && _fail "20-migration:head-has-build-sheet" "migration head must not require a Build Sheet .docx"
head -n 125 "$MIG" | grep -F -q "Logo (PNG/JPG/SVG)" \
  && _fail "20-migration:head-has-logo-file" "migration head must not require a separate logo file"

# Content variation policy exemption stated in §Inputs
grep -F -q "Content variation policy — not applicable" "$MIG" \
  || _fail "20-migration:variation-exempt" "Inputs must declare §Content variation policy skipped for rebuilds"

# Provenance mapping table present so shared-body 'build sheet' references translate
grep -F -q "Provenance mapping for the shared body" "$MIG" \
  || _fail "20-migration:provenance-mapping" "Inputs must include a Provenance mapping section"

# §Scrape is reframed as consumption rules — Replit already did the crawl
grep -F -q "scrape is done upstream by Replit" "$MIG" \
  || _fail "20-migration:scrape-upstream" "Scrape must state Replit did the crawl upstream"
grep -F -q "consume the scrape as a fact source" "$MIG" \
  || _fail "20-migration:scrape-consume" "Scrape must frame this skill's role as consumption"

# HARD sync check: from `## Required pages` onward, byte-match SKILL.md.
skill_anchor=$(grep -nE '^## Required pages$' "$SKILL" | head -1 | cut -d: -f1)
mig_anchor=$(grep -nE '^## Required pages$' "$MIG" | head -1 | cut -d: -f1)
if [[ -z "$skill_anchor" || -z "$mig_anchor" ]]; then
  _fail "20-migration:anchor-missing" "'## Required pages' anchor missing in SKILL ($skill_anchor) or MIG ($mig_anchor)"
fi

if ! diff -q <(tail -n +"$skill_anchor" "$SKILL") <(tail -n +"$mig_anchor" "$MIG") > /dev/null 2>&1; then
  echo "  FAIL [20-migration:body-sync]: WEBSITE-MIGRATION-SKILL.md shared body drifted from SKILL.md."
  echo "  Fix: run 'bash tools/refresh-migration-skill.sh' to resync from '## Required pages' onward."
  echo
  echo "  Diff (from '## Required pages' onward):"
  diff <(tail -n +"$skill_anchor" "$SKILL") <(tail -n +"$mig_anchor" "$MIG") | head -40 | sed 's/^/    /'
  exit 1
fi

# Wrong triggers must NOT appear (the primary skill's frontmatter shouldn't be duplicated)
grep -E -q '^name: pharmacy-builder$' "$MIG" \
  && _fail "20-migration:leaked-primary-name" "must not carry name: pharmacy-builder"
grep -F -q "# Pharmacy Builder Skill" "$MIG" \
  && _fail "20-migration:leaked-primary-h1" "must not carry the primary skill's H1"

pass "20-website-migration"
