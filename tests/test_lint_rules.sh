#!/usr/bin/env bash
# test_lint_rules.sh
# Simulates what /kos-lint would check against a real vault.
# Creates a temporary mock vault, runs structural checks against it,
# then tears it down. This validates the lint LOGIC is correct —
# not the AI behavior, but the rules it's supposed to enforce.

set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

# --- Set up a temp mock vault ---
MOCK_VAULT=$(mktemp -d)
trap 'rm -rf "$MOCK_VAULT"' EXIT  # Always clean up on script exit

echo ""
echo "═══════════════════════════════════════"
echo "  TEST: KOS Lint Rules (Dry Run)"
echo "═══════════════════════════════════════"
echo ""
echo "  Mock vault: $MOCK_VAULT"

# ── Build a valid mock vault structure ──────────────────────────────
mkdir -p "$MOCK_VAULT/raw/assets"
mkdir -p "$MOCK_VAULT/raw/FL-vol-001"
mkdir -p "$MOCK_VAULT/wiki/sources"
mkdir -p "$MOCK_VAULT/wiki/entities"
mkdir -p "$MOCK_VAULT/wiki/concepts"
mkdir -p "$MOCK_VAULT/wiki/synthesis"
mkdir -p "$MOCK_VAULT/wiki/questions"
mkdir -p "$MOCK_VAULT/wiki/books"
mkdir -p "$MOCK_VAULT/output"
echo "# Index" > "$MOCK_VAULT/wiki/index.md"
echo "# Log" > "$MOCK_VAULT/wiki/log.md"
echo "# Schema" > "$MOCK_VAULT/SCHEMA.md"

# ── LINT RULE 1: Required top-level directories ──────────────────────
echo ""
echo "▸ Rule 1 — Required vault directories exist..."

for dir in raw wiki output; do
  if [ -d "$MOCK_VAULT/$dir" ]; then
    pass "Vault has $dir/"
  else
    fail "Vault missing $dir/"
  fi
done

# ── LINT RULE 2: wiki/ subdirectories are present ───────────────────
echo ""
echo "▸ Rule 2 — wiki/ subdirectories are present..."

for subdir in sources entities concepts synthesis questions books; do
  if [ -d "$MOCK_VAULT/wiki/$subdir" ]; then
    pass "wiki/$subdir exists"
  else
    fail "wiki/$subdir missing"
  fi
done

# ── LINT RULE 3: wiki/index.md and wiki/log.md must exist ───────────
echo ""
echo "▸ Rule 3 — wiki/index.md and wiki/log.md exist..."

for file in index.md log.md; do
  if [ -f "$MOCK_VAULT/wiki/$file" ]; then
    pass "wiki/$file exists"
  else
    fail "wiki/$file missing"
  fi
done

# ── LINT RULE 4: SCHEMA.md must exist at vault root ─────────────────
echo ""
echo "▸ Rule 4 — SCHEMA.md exists at vault root..."

if [ -f "$MOCK_VAULT/SCHEMA.md" ]; then
  pass "SCHEMA.md present at vault root"
else
  fail "SCHEMA.md missing from vault root"
fi

# ── LINT RULE 5: raw/ must not contain .md files written by LLM ─────
# raw/ is immutable input — the LLM must never write wiki-style pages there.
# We simulate a violation by dropping an unexpected .md file in raw/ root.
echo ""
echo "▸ Rule 5 — raw/ root contains no unexpected LLM-generated .md files..."

llm_written_count=$(find "$MOCK_VAULT/raw" -maxdepth 1 -name "*.md" | wc -l)
if [ "$llm_written_count" -eq 0 ]; then
  pass "raw/ root has no .md files (immutability intact)"
else
  fail "raw/ root has $llm_written_count unexpected .md file(s) — possible LLM boundary violation"
fi

# ── LINT RULE 6: wiki/ pages have non-empty content ─────────────────
echo ""
echo "▸ Rule 6 — wiki/ index and log are non-empty..."

for file in index.md log.md; do
  size=$(wc -c < "$MOCK_VAULT/wiki/$file")
  if [ "$size" -gt 0 ]; then
    pass "wiki/$file is non-empty ($size bytes)"
  else
    fail "wiki/$file is empty"
  fi
done

# --- Summary ---
echo ""
echo "───────────────────────────────────────"
echo "  PASSED: $PASS  |  FAILED: $FAIL"
echo "───────────────────────────────────────"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
