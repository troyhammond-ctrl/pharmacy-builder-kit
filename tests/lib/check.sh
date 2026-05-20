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
  # Case-sensitive by design — matches assert_contains semantics. Tests that
  # need case-insensitive matching should enumerate the case variants explicitly.
  local needle="$1"
  local test_name="${2:-not-contains}"
  local file="${3:-$SKILL_FILE}"
  if grep -F -q -- "$needle" "$file"; then
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
