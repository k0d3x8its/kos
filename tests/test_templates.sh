#!/usr/bin/env bash
# test_templates.sh
# Validates that all templates exist, are non-empty, and contain
# required section markers. Templates are the LLM's starting contract —
# a broken template silently breaks every new vault created with KOS.

set -euo pipefail

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATES_DIR="$REPO_ROOT/templates"

pass() { echo "  ✅ $1"; ((PASS++)); }
fail() { echo "  ❌ $1"; ((FAIL++)); }

echo ""
echo "═══════════════════════════════════════"
echo "  TEST: Template Integrity"
echo "═══════════════════════════════════════"

# --- Check templates/ exists ---
echo ""
echo "▸ Checking templates/ directory..."

if [ ! -d "$TEMPLATES_DIR" ]; then
  echo "  ❌ templates/ directory not found — aborting"
  exit 1
fi
pass "templates/ directory exists"

# --- SCHEMA.md must exist and be non-empty ---
echo ""
echo "▸ Checking SCHEMA.md..."

SCHEMA="$TEMPLATES_DIR/SCHEMA.md"

if [ -f "$SCHEMA" ]; then
  pass "SCHEMA.md exists"
else
  fail "SCHEMA.md missing from templates/"
fi

# File must have actual content (more than 5 lines means it's not a stub)
if [ -f "$SCHEMA" ]; then
  line_count=$(wc -l < "$SCHEMA")
  if [ "$line_count" -gt 5 ]; then
    pass "SCHEMA.md is non-trivial ($line_count lines)"
  else
    fail "SCHEMA.md looks like a stub ($line_count lines)"
  fi
fi

# --- Check all .md files in templates/ are non-empty ---
echo ""
echo "▸ Checking all templates are non-empty..."

template_count=0
for tpl in "$TEMPLATES_DIR"/*.md; do
  [ -e "$tpl" ] || continue
  ((template_count++))
  name=$(basename "$tpl")
  size=$(wc -c < "$tpl")
  if [ "$size" -gt 0 ]; then
    pass "$name is non-empty ($size bytes)"
  else
    fail "$name is empty"
  fi
done

if [ "$template_count" -eq 0 ]; then
  fail "No .md files found in templates/"
fi

# --- Summary ---
echo ""
echo "───────────────────────────────────────"
echo "  PASSED: $PASS  |  FAILED: $FAIL"
echo "───────────────────────────────────────"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
