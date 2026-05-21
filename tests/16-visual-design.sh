#!/usr/bin/env bash
# tests/16-visual-design.sh
# Locks the ui-ux-pro-max integration and the precedence rules that
# guarantee design quality without overriding accessibility, voice,
# or required-section contracts.
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Section + invocation
assert_contains_regex '^## Visual design$' "16-visual:section"
assert_contains "ui-ux-pro-max" "16-visual:pro-max-name"
assert_contains "Invoke the" "16-visual:invoke-directive"

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

# Dark mode policy
assert_contains "Never force a degraded dark mode" "16-visual:dark-mode-policy"

# Review pass
assert_contains "Review pass" "16-visual:review-pass"
assert_contains "review" "16-visual:review-action"

# Wired into Step 4 of Process
assert_contains "Invoke the \`ui-ux-pro-max\` skill per §Visual design" "16-visual:wired-into-step-4"

pass "16-visual-design"
