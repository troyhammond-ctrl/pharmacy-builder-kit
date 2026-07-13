#!/usr/bin/env bash
# tools/refresh-migration-skill.sh
# Rebuilds WEBSITE-MIGRATION-SKILL.md from SKILL.md. Keeps the
# migration-tuned frontmatter and H1; syncs the body from line 7
# onward. Run whenever you edit SKILL.md so tests/20-website-
# migration.sh stays green.
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL="SKILL.md"
MIG="WEBSITE-MIGRATION-SKILL.md"

[[ -f "$SKILL" ]] || { echo "missing $SKILL" >&2; exit 1; }

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

{
  cat <<'EOF'
---
name: website-migration
description: Migrate or rebuild an existing pharmacy website onto a modern, accessible, factually faithful stack. Use when the user asks to "migrate a pharmacy site," "rebuild a pharmacy website," "port the existing pharmacy site," "modernize [pharmacy]'s website," "website migration," "site rebuild," or provides an existing pharmacy URL to be rebuilt. The input is a build folder with `Build origin: rebuild` — the pharmacy's existing live site is the primary source of truth for content and imagery, scraped and mirrored to `/scraped/` before generation. Same output contract as the pharmacy-builder skill (required pages, WCAG 2.2 AA accessibility, SEO + JSON-LD schema, voice and PHI guardrails, size-report.json, etc.), but the scrape drives content instead of a jotform build sheet's operator-written fields — the §Content variation policy is skipped for rebuilds. Stack-agnostic — the agent picks the framework. This skill and the pharmacy-builder skill share the same body from the H1 onward; only the frontmatter and H1 differ so the trigger surface fits migration language.
---

# Website Migration Skill
EOF
  tail -n +7 "$SKILL"
} > "$TMP"

if cmp -s "$TMP" "$MIG"; then
  echo "✓ $MIG is already in sync with $SKILL"
else
  mv "$TMP" "$MIG"
  trap - EXIT
  echo "✓ Regenerated $MIG from $SKILL"
fi
