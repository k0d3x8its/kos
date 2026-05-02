#!/usr/bin/env bash
# test_schema_contract.sh
# SCHEMA.md is the rulebook the LLM follows when maintaining your vault.
# This test validates that it contains the required structural contracts
# defined in the KOS spec. A SCHEMA.md missing these is a silent bug
# that won't surface until the LLM corrupts your vault.

set -euo pipefail

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA="$REPO_ROOT/templates/SCHEMA.md"

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

echo ""
echo "═══════════════════════════════════════"
echo "  TEST: Schema Contract Validation"
echo "═══════════════════════════════════════"

# --- SCHEMA.md must exist to continue ---
if [ ! -f "$SCHEMA" ]; then
  echo "  ❌ SCHEMA.md not found at templates/SCHEMA.md — aborting"
  exit 1
fi

echo ""
echo "▸ Checking Layer boundary declarations..."

# KOS spec: raw/ is immutable — the LLM must not write to it
if grep -qi "raw/" "$SCHEMA"; then
  pass "SCHEMA.md references raw/ directory"
else
  fail "SCHEMA.md does not mention raw/ — immutability rule may be missing"
fi

# KOS spec: wiki/ is owned by the LLM
if grep -qi "wiki/" "$SCHEMA"; then
  pass "SCHEMA.md references wiki/ directory"
else
  fail "SCHEMA.md does not mention wiki/ — LLM ownership rule may be missing"
fi

echo ""
echo "▸ Checking required wiki/ subdirectory contracts..."

# These subdirectories are defined in the README vault structure
for subdir in sources entities concepts synthesis questions; do
  if grep -qi "$subdir" "$SCHEMA"; then
    pass "SCHEMA.md references wiki/$subdir"
  else
    fail "SCHEMA.md missing reference to wiki/$subdir"
  fi
done

echo ""
echo "▸ Checking index and log contracts..."

# wiki/index.md is the master catalog — must be in the schema
if grep -qi "index" "$SCHEMA"; then
  pass "SCHEMA.md references index"
else
  fail "SCHEMA.md missing index reference (wiki/index.md)"
fi

# wiki/log.md is the operation record — must be in the schema
if grep -qi "log" "$SCHEMA"; then
  pass "SCHEMA.md references log"
else
  fail "SCHEMA.md missing log reference (wiki/log.md)"
fi

echo ""
echo "▸ Checking Layer isolation contract..."

# KOS must not cross layer boundaries — this is the core architectural rule
if grep -qi "layer" "$SCHEMA"; then
  pass "SCHEMA.md references layer boundaries"
else
  fail "SCHEMA.md missing layer boundary declaration"
fi

# --- Summary ---
echo ""
echo "───────────────────────────────────────"
echo "  PASSED: $PASS  |  FAILED: $FAIL"
echo "───────────────────────────────────────"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
