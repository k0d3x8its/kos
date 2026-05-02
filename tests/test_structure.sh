#!/usr/bin/env bash
# test_structure.sh
# Validates that the KOS repo has all required top-level files and directories.
# If anything critical is missing, this fails immediately.

set -euo pipefail

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Helper: print pass/fail and track counts
pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

echo ""
echo "═══════════════════════════════════════"
echo "  TEST: Repository Structure"
echo "═══════════════════════════════════════"

# --- Required directories ---
echo ""
echo "▸ Checking required directories..."

for dir in skills templates docs tests; do
  if [ -d "$REPO_ROOT/$dir" ]; then
    pass "Directory exists: $dir/"
  else
    fail "Missing directory: $dir/"
  fi
done

# --- Required root files ---
echo ""
echo "▸ Checking required root files..."

for file in README.md .gitignore; do
  if [ -f "$REPO_ROOT/$file" ]; then
    pass "File exists: $file"
  else
    fail "Missing file: $file"
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
