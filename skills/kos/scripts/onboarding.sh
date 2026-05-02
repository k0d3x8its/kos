#!/usr/bin/env bash
# KOS — Onboarding Script
# Scaffolds vault directory structure and verifies CLI tooling.
#
# Usage: STARTER_MODE=fresh bash onboarding.sh <vault-path>
# Output: Plain-text status to stderr. Exit code 0 on success, non-zero on failure.

set -u # error on undefined vars

VAULT_ROOT="${1:-}"

if [ -z "$VAULT_ROOT" ]; then
  echo "ERROR: vault path required" >&2
  echo "Usage: bash onboarding.sh <vault-path> [fresh|archived]" >&2
  exit 1
fi

if [ "$STARTER_MODE" != "fresh" ] && [ "$STARTER_MODE" != "archived" ]; then
  echo "ERROR: starter mode must be 'fresh' or 'archived', got: $STARTER_MODE" >&2
  exit 1
fi

# Refuse to scaffold over an existing vault
if [ -f "$VAULT_ROOT/SCHEMA.md" ]; then
  echo "ERROR: vault already exists at $VAULT_ROOT (SCHEMA.md present)" >&2
  echo "Refusing to overwrite. Delete or move the existing vault first." >&2
  exit 2
fi

echo "=== KOS Onboarding ===" >&2
echo "Vault path: $VAULT_ROOT" >&2

# 1. Create directory structure
echo "" >&2
echo "Creating directory structure..." >&2

DIRS=(
  "raw"
  "raw/assets"
  "wiki"
  "wiki/sources"
  "wiki/books"
  "wiki/_archived"   # stores completed/retired Field Notes books
  "wiki/entities"
  "wiki/concepts"
  "wiki/synthesis"
  "wiki/questions"
  "output"
)

for dir in "${DIRS[@]}"; do
  mkdir -p "$VAULT_ROOT/$dir" || {
    echo "ERROR: failed to create $VAULT_ROOT/$dir" >&2
    exit 3
  }
  echo "  created $dir/" >&2
done

# 1b. If fresh mode, pre-create the first FL and FR volume folders
if [ "$STARTER_MODE" = "fresh" ]; then
  echo "" >&2
  echo "Fresh start — pre-creating first volume folders..." >&2
  mkdir -p "$VAULT_ROOT/raw/FL-vol-001"
  mkdir -p "$VAULT_ROOT/raw/FR-vol-001"
  echo "  created raw/FL-vol-001/ (your first Field Log)" >&2
  echo "  created raw/FR-vol-001/ (your first Field Research)" >&2
  echo "  (FS-vol-001 not pre-created — Field Study books appear during Phase II)" >&2
fi

# 2. Create wiki/index.md if it doesn't exist
if [ ! -f "$VAULT_ROOT/wiki/index.md" ]; then
  cat > "$VAULT_ROOT/wiki/index.md" << 'EOF'
# Wiki Index

_Last updated: (none yet — run /kos-ingest to populate)_

## Books

## Archived Books

## Sources

## Entities

## Concepts

## Synthesis

## Questions (open)
EOF
  echo "  created wiki/index.md" >&2
else
  echo "  wiki/index.md already exists, skipping" >&2
fi

# 3. Create wiki/log.md if it doesn't exist
if [ ! -f "$VAULT_ROOT/wiki/log.md" ]; then
  cat > "$VAULT_ROOT/wiki/log.md" << 'EOF'
# Log

Append-only chronological record of all KOS operations on this vault.
Format defined in SCHEMA.md Section 3.9. Do not edit by hand.
EOF
  echo "  created wiki/log.md" >&2
else
  echo "  wiki/log.md already exists, skipping" >&2
fi

# 4. Check tooling
echo "" >&2
echo "Checking optional tooling..." >&2

check_tool() {
  local name="$1"
  local cmd="$2"
  local install_cmd="$3"
  if command -v "$cmd" > /dev/null 2>&1; then
    echo "  [installed] $name" >&2
  else
    echo "  [missing]   $name — to install: $install_cmd" >&2
  fi
}

check_tool "summarize"     "summarize"     "npm i -g @steipete/summarize"
check_tool "qmd"           "qmd"           "npm i -g @tobilu/qmd"
check_tool "agent-browser" "agent-browser" "npm i -g agent-browser && agent-browser install"

# 5. Final status
echo "" >&2
VAULT_ABS=$(cd "$VAULT_ROOT" && pwd)
echo "=== Onboarding scaffold complete ===" >&2
echo "Vault: $VAULT_ABS" >&2
echo "" >&2
echo "Next steps for the wizard:" >&2
echo "  1. Copy templates/SCHEMA.md to $VAULT_ABS/SCHEMA.md" >&2
echo "  2. Generate agent config file(s)" >&2
echo "  3. Append the setup entry to wiki/log.md" >&2

exit 0
