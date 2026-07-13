#!/usr/bin/env bash
# tests/20-website-migration.sh
# WEBSITE-MIGRATION-SKILL.md is a rename of SKILL.md whose frontmatter
# and H1 fit migration/rebuild triggers. Bodies from line 7 onward
# must stay byte-identical between the two files — if SKILL.md is
# edited, the duplicate must be re-copied. This test guards against
# silent drift.
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

MIG="$(pwd)/WEBSITE-MIGRATION-SKILL.md"
SKILL="$(pwd)/SKILL.md"

[[ -f "$MIG" ]] || _fail "20-migration:file-exists" "expected WEBSITE-MIGRATION-SKILL.md at $MIG"

# Frontmatter tuned for migration
grep -E -q '^name: website-migration$' "$MIG" \
  || _fail "20-migration:frontmatter-name" "expected name: website-migration"

# Description carries migration triggers
for phrase in \
  "migrate a pharmacy site" \
  "rebuild a pharmacy website" \
  "port the existing pharmacy site" \
  "website migration" \
  "site rebuild" \
  "Build origin"
do
  grep -F -q -- "$phrase" "$MIG" \
    || _fail "20-migration:trigger-$phrase" "description missing trigger: $phrase"
done

# H1 renamed
grep -F -q "# Website Migration Skill" "$MIG" \
  || _fail "20-migration:h1" "expected '# Website Migration Skill' H1"

# Cross-reference the primary skill so operators know they share a body
grep -F -q "same body from the H1 onward" "$MIG" \
  || _fail "20-migration:shared-body-note" "description must acknowledge shared body with pharmacy-builder"

# HARD sync check: body from line 7 onward must byte-match SKILL.md.
# If SKILL.md changes, the duplicate MUST be re-copied.
if ! diff -q <(tail -n +7 "$SKILL") <(tail -n +7 "$MIG") > /dev/null 2>&1; then
  echo "  FAIL [20-migration:body-sync]: WEBSITE-MIGRATION-SKILL.md body drifted from SKILL.md."
  echo "  Fix: run 'cp SKILL.md WEBSITE-MIGRATION-SKILL.md' then reapply the frontmatter + H1 changes,"
  echo "  or use tools/refresh-migration-skill.sh (if present) to regenerate."
  echo
  echo "  Diff (line 7 onward):"
  diff <(tail -n +7 "$SKILL") <(tail -n +7 "$MIG") | head -40 | sed 's/^/    /'
  exit 1
fi

# Wrong triggers must NOT appear (the primary skill's frontmatter shouldn't be duplicated)
grep -E -q '^name: pharmacy-builder$' "$MIG" \
  && _fail "20-migration:leaked-primary-name" "must not carry name: pharmacy-builder"
grep -F -q "# Pharmacy Builder Skill" "$MIG" \
  && _fail "20-migration:leaked-primary-h1" "must not carry the primary skill's H1"

pass "20-website-migration"
