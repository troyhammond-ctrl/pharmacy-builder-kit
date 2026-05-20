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
