#!/bin/bash

set -e

# Test: onboarding.sh creates correct vault structure
# Usage: bash tests/test_onboarding.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ONBOARDING="$REPO_ROOT/skills/kos/scripts/onboarding.sh"

TEST_DIR=$(mktemp -d)
TEST_VAULT="$TEST_DIR/test-vault"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

PASS=0
FAIL=0

assert_dir() {
  if [ -d "$1" ]; then
    echo "  PASS: directory exists — $1"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: directory missing — $1"
    FAIL=$((FAIL + 1))
  fi
}

assert_file() {
  if [ -f "$1" ]; then
    echo "  PASS: file exists — $1"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: file missing — $1"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  if grep -q "$2" "$1" 2>/dev/null; then
    echo "  PASS: file contains '$2' — $1"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: file does not contain '$2' — $1"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Test: onboarding.sh ==="
echo ""

# Test 1: Script runs successfully on a new directory
# STARTER_MODE must be exported so onboarding.sh can read it as an env var
echo "Test 1: Fresh vault scaffolding"
STARTER_MODE=fresh bash "$ONBOARDING" "$TEST_VAULT" 2>/dev/null

assert_dir "$TEST_VAULT/raw"
assert_dir "$TEST_VAULT/raw/assets"
assert_dir "$TEST_VAULT/raw/FL-vol-001"     # created in fresh mode
assert_dir "$TEST_VAULT/raw/FR-vol-001"     # created in fresh mode
assert_dir "$TEST_VAULT/wiki"
assert_dir "$TEST_VAULT/wiki/sources"
assert_dir "$TEST_VAULT/wiki/books"
assert_dir "$TEST_VAULT/wiki/_archived"     # stores retired Field Notes books
assert_dir "$TEST_VAULT/wiki/entities"
assert_dir "$TEST_VAULT/wiki/concepts"
assert_dir "$TEST_VAULT/wiki/synthesis"
assert_dir "$TEST_VAULT/wiki/questions"
assert_dir "$TEST_VAULT/output"

echo ""

# Test 2: wiki/index.md created with correct scaffolding
# Checks all sections defined in the heredoc inside onboarding.sh
echo "Test 2: wiki/index.md content"
assert_file "$TEST_VAULT/wiki/index.md"
assert_contains "$TEST_VAULT/wiki/index.md" "## Books"
assert_contains "$TEST_VAULT/wiki/index.md" "## Archived Books"
assert_contains "$TEST_VAULT/wiki/index.md" "## Sources"
assert_contains "$TEST_VAULT/wiki/index.md" "## Entities"
assert_contains "$TEST_VAULT/wiki/index.md" "## Concepts"
assert_contains "$TEST_VAULT/wiki/index.md" "## Synthesis"
assert_contains "$TEST_VAULT/wiki/index.md" "## Questions"

echo ""

# Test 3: wiki/log.md created with header
echo "Test 3: wiki/log.md content"
assert_file "$TEST_VAULT/wiki/log.md"
assert_contains "$TEST_VAULT/wiki/log.md" "# Log"

echo ""

# Test 4: Idempotent — running again doesn't overwrite existing files.
# Uses a second vault with pre-existing index/log to isolate the file
# guard logic from the SCHEMA.md existence check (which blocks re-runs).
echo "Test 4: Idempotency — existing wiki files are not overwritten"
SECOND_VAULT="$TEST_DIR/test-vault-2"
mkdir -p "$SECOND_VAULT/wiki"
echo "# Custom content" > "$SECOND_VAULT/wiki/index.md"
echo "# Log" > "$SECOND_VAULT/wiki/log.md"
STARTER_MODE=fresh bash "$ONBOARDING" "$SECOND_VAULT" 2>/dev/null || true
assert_contains "$SECOND_VAULT/wiki/index.md" "# Custom content"

echo ""

echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
