#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

assert_file_exists "$SKILL_FILE" "01-frontmatter:file-exists"

# Frontmatter delimiters (both opening and closing)
assert_contains_regex '^---$' "01-frontmatter:opening-delimiter"
assert_count_at_least "---" 2 "01-frontmatter:both-delimiters"

# Required frontmatter keys
assert_contains_regex '^name: pharmacy-builder$' "01-frontmatter:name"
assert_contains_regex '^description:' "01-frontmatter:description-key"

# Trigger phrases must live on the description: line (not just anywhere in
# the file). Once SKILL.md grows in later tasks, scoped assertions prevent
# false-positive matches against unrelated prose.
assert_contains_regex '^description:.*build pharmacy site' "01-frontmatter:trigger-pharmacy-site"
assert_contains_regex '^description:.*build pharmacy website' "01-frontmatter:trigger-pharmacy-website"
assert_contains_regex '^description:.*pharmacy build sheet' "01-frontmatter:trigger-build-sheet"
assert_contains_regex '^description:.*Lumistry pharmacy build' "01-frontmatter:trigger-lumistry"
assert_contains_regex '^description:.*Longhorn' "01-frontmatter:trigger-longhorn"

pass "01-frontmatter"
