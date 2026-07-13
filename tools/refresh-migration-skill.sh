#!/usr/bin/env bash
# tools/refresh-migration-skill.sh
# Keeps the SHARED BODY of WEBSITE-MIGRATION-SKILL.md byte-identical to
# SKILL.md, starting from the `## Required pages` heading. The migration
# skill's own head (frontmatter, H1, §Inputs, §Scrape) diverges because
# the migration flow consumes a Replit-produced scraped manifest instead
# of a jotform build sheet — those upper sections are hand-maintained.
# Run this whenever you edit SKILL.md so tests/20-website-migration.sh
# stays green.
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL="SKILL.md"
MIG="WEBSITE-MIGRATION-SKILL.md"
ANCHOR='^## Required pages$'

[[ -f "$SKILL" ]] || { echo "missing $SKILL" >&2; exit 1; }
[[ -f "$MIG" ]] || { echo "missing $MIG" >&2; exit 1; }

skill_anchor=$(grep -nE "$ANCHOR" "$SKILL" | head -1 | cut -d: -f1)
mig_anchor=$(grep -nE "$ANCHOR" "$MIG" | head -1 | cut -d: -f1)

if [[ -z "${skill_anchor:-}" || -z "${mig_anchor:-}" ]]; then
  echo "shared-body anchor '## Required pages' not found in one of the files" >&2
  echo "  SKILL.md: ${skill_anchor:-<missing>}" >&2
  echo "  $MIG: ${mig_anchor:-<missing>}" >&2
  exit 1
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

head -n $((mig_anchor - 1)) "$MIG" > "$TMP"
tail -n +"$skill_anchor" "$SKILL" >> "$TMP"

if cmp -s "$TMP" "$MIG"; then
  echo "✓ $MIG shared body already in sync with $SKILL (from '## Required pages' onward)"
else
  mv "$TMP" "$MIG"
  trap - EXIT
  echo "✓ Regenerated $MIG shared body from $SKILL (from '## Required pages' onward)"
fi
