#!/usr/bin/env bash
# tests/16-visual-design.sh
# Locks the three-skill design toolchain (ui-ux-pro-max ->
# huashu-design -> Impeccable) and the precedence rules that
# guarantee design quality without overriding accessibility,
# voice, conversion, or required-section contracts.
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Section + toolchain subsection
assert_contains_regex '^## Visual design$' "16-visual:section"
assert_contains "Design skill toolchain" "16-visual:toolchain-subsection"

# All three skills named
assert_contains "ui-ux-pro-max" "16-visual:pro-max-name"
assert_contains "huashu-design" "16-visual:huashu-name"
assert_contains "Impeccable" "16-visual:impeccable-name"

# Order is explicit
assert_contains "ui-ux-pro-max\` → \`huashu-design\` → \`Impeccable" "16-visual:order-explicit"

# Roles are differentiated
assert_contains "initial design system" "16-visual:pro-max-role"
assert_contains "aesthetic refinement" "16-visual:huashu-role"
assert_contains "final polish" "16-visual:impeccable-role"

# Absence policy: log, never substitute
assert_contains "skip it and log the absence" "16-visual:skip-and-log"
assert_contains "never substitute" "16-visual:no-substitution"

# Style direction
assert_contains "Clean, modern, professional" "16-visual:style-direction"
assert_contains "minimalism" "16-visual:style-minimalism"

# Stack hint
assert_contains "Tailwind" "16-visual:tailwind"
assert_contains "shadcn" "16-visual:shadcn"

# Constraint precedence
assert_contains "Brand color is canonical" "16-visual:brand-canonical"
assert_contains "Accessibility wins" "16-visual:a11y-wins"
assert_contains "Voice wins" "16-visual:voice-wins"
assert_contains "Required sections are non-negotiable" "16-visual:sections-non-negotiable"
assert_contains "Conversion contract" "16-visual:conversion-contract"

# Dark mode policy
assert_contains "Never force a degraded dark mode" "16-visual:dark-mode-policy"

# Review passes for each skill
assert_contains "Review passes" "16-visual:review-passes"
assert_contains "Pro-max \`review\`" "16-visual:pro-max-review"
assert_contains "Huashu-design review" "16-visual:huashu-review"
assert_contains "Impeccable review" "16-visual:impeccable-review"

# Wired into Step 4 of Process
assert_contains "Invoke the three design skills in order" "16-visual:wired-into-step-4"

pass "16-visual-design"
