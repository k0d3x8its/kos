#!/usr/bin/env bash
# test_agent_configs.sh
# Validates that all AI agent configuration templates exist and are well-formed.
# They must contain required placeholders, core skills, and primary safety rules.

set -euo pipefail

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGS_DIR="$REPO_ROOT/skills/kos/references/agent-configs"

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

echo ""
echo "═══════════════════════════════════════"
echo "  TEST: Agent Configurations Integrity"
echo "═══════════════════════════════════════"

# --- Checking directory ---
echo ""
echo "▸ Checking agent-configs directory..."
if [ ! -d "$CONFIGS_DIR" ]; then
  echo "  ❌ agent-configs directory not found at $CONFIGS_DIR — aborting"
  exit 1
fi
pass "agent-configs directory exists"

# --- Expected config files ---
echo ""
echo "▸ Checking expected config files exist..."
EXPECTED_FILES=(
  "claude-code.md"
  "codex.md"
  "cursor.md"
  "deepseek.md"
  "gemini.md"
)

for file in "${EXPECTED_FILES[@]}"; do
  if [ -f "$CONFIGS_DIR/$file" ]; then
    pass "Config file exists: $file"
  else
    fail "Missing config file: $file"
  fi
done

# --- Validating contents of each config file ---
for file in "${EXPECTED_FILES[@]}"; do
  filepath="$CONFIGS_DIR/$file"
  [ -f "$filepath" ] || continue

  echo ""
  echo "▸ Validating content of $file..."

  # 1. Check placeholders
  for placeholder in "{{VAULT_NAME}}" "{{DOMAIN_DESCRIPTION}}"; do
    if grep -q "$placeholder" "$filepath"; then
      pass "$file: contains placeholder $placeholder"
    else
      fail "$file: missing placeholder $placeholder"
    fi
  done

  # 2. Check 5 KOS skills
  for skill in "/kos" "/kos-ingest" "/kos-query" "/kos-lint" "/kos-archive"; do
    if grep -q -i "$skill" "$filepath"; then
      pass "$file: references skill $skill"
    else
      fail "$file: missing reference to skill $skill"
    fi
  done

  # 3. Check "raw/" is immutable rule
  if grep -q -i "raw/.*immutable" "$filepath" || (grep -q -i "raw/" "$filepath" && grep -q -i "immutable" "$filepath"); then
    pass "$file: references immutability of raw/"
  else
    fail "$file: missing immutability rule of raw/"
  fi
done

# --- Summary ---
echo ""
echo "───────────────────────────────────────"
echo "  PASSED: $PASS  |  FAILED: $FAIL"
echo "───────────────────────────────────────"
echo ""

# Exit with error if any test failed
[ "$FAIL" -eq 0 ] || exit 1
