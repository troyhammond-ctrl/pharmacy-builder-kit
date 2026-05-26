#!/usr/bin/env bash
# tests/lib/qa-check.sh
# Thin wrapper that points the standard check.sh helpers at QA-SKILL.md
# instead of SKILL.md. Source check.sh first, then this file.

QA_FILE="${QA_FILE:-QA-SKILL.md}"

qa_assert_file_exists() {
  [[ -f "$QA_FILE" ]] || _fail "${1:-qa-exists}" "expected QA-SKILL.md at $QA_FILE"
}

qa_assert_contains() {
  local needle="$1"
  local test_name="${2:-qa-contains}"
  grep -F -q -- "$needle" "$QA_FILE" \
    || _fail "$test_name" "$QA_FILE is missing literal: $needle"
}

qa_assert_contains_regex() {
  local pattern="$1"
  local test_name="${2:-qa-contains-regex}"
  grep -E -q -- "$pattern" "$QA_FILE" \
    || _fail "$test_name" "$QA_FILE is missing pattern: $pattern"
}
