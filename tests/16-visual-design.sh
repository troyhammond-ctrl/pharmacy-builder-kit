#!/usr/bin/env bash
# tests/16-visual-design.sh
# Locks the lean, single-pass visual design contract. Guards against
# regressions that would reintroduce the heavy three-skill toolchain
# (ui-ux-pro-max / huashu-design / Impeccable) or add unauthorized
# design review-pass loops.
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Section still present
assert_contains_regex '^## Visual design$' "16-visual:section"

# Single-pass, cost-aware framing
assert_contains "single generation pass" "16-visual:single-pass"
assert_contains "Do not invoke external design-agent skills" "16-visual:no-external-agents"
assert_contains "No design review pass is required" "16-visual:no-review-pass"
assert_contains "Cost note" "16-visual:cost-note"

# Recommended stack
assert_contains "React + Tailwind + shadcn/ui" "16-visual:stack"
assert_contains "shadcn MCP" "16-visual:shadcn-mcp"

# Style direction
assert_contains "Clean, modern, professional" "16-visual:style-direction"
assert_contains "minimalism" "16-visual:style-minimalism"
assert_contains "Avoid brutalism" "16-visual:style-avoid-brutalism"

# Constraint precedence
assert_contains "Brand color is canonical" "16-visual:brand-canonical"
assert_contains "Accessibility, Voice, Required sections, Conversion, and PHI wins on conflict" "16-visual:constraints-win"

# Iconography + typography defaults
assert_contains "Lucide recommended" "16-visual:icons-lucide"
assert_contains "Inter" "16-visual:font-inter"
assert_contains "font-size ≥ 16px" "16-visual:font-min"

# Responsive baseline
assert_contains "box-sizing: border-box" "16-visual:box-sizing"
assert_contains "320px viewport" "16-visual:no-h-scroll-320"

# Dark mode policy
assert_contains "Never ship a degraded dark mode" "16-visual:dark-mode-policy"

# HARD GUARDS: the three heavy skills must NOT reappear anywhere in SKILL.md
assert_not_contains "ui-ux-pro-max" "16-visual:guard-no-pro-max"
assert_not_contains "huashu-design" "16-visual:guard-no-huashu"
assert_not_contains "Impeccable" "16-visual:guard-no-impeccable"
assert_not_contains "Design skill toolchain" "16-visual:guard-no-toolchain-heading"

pass "16-visual-design"
