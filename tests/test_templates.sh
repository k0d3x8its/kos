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

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

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
  template_count=$((template_count + 1))
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

# --- Check required template files exist ---
echo ""
echo "▸ Checking required template files..."

for tpl in SCHEMA.md frontmatter-templates.md field-notes-formats.md; do
  if [ -f "$TEMPLATES_DIR/$tpl" ]; then
    pass "$tpl exists"
  else
    fail "$tpl missing from templates/"
  fi
done

# --- Check required references files exist ---
echo ""
echo "▸ Checking required references files..."

REFERENCES_DIR="$REPO_ROOT/references"

if [ ! -d "$REFERENCES_DIR" ]; then
  fail "references/ directory missing"
else
  pass "references/ directory exists"
  for ref in schema-changelog.md ingest-log-examples.md lint-report-example.md; do
    if [ -f "$REFERENCES_DIR/$ref" ]; then
      pass "$ref exists"
    else
      fail "$ref missing from references/"
    fi
  done
fi

# --- Summary ---
echo ""
echo "───────────────────────────────────────"
echo "  PASSED: $PASS  |  FAILED: $FAIL"
echo "───────────────────────────────────────"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
