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
