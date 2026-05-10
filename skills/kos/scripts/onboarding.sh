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
  "raw/Field-Logs"
  "raw/Field-Research"
  "raw/Field-Studies"
  "raw/assets"
  "wiki"
  "wiki/sources"
  "wiki/books"
  "wiki/books/_archived"   # stores completed/retired Field Notes books
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
  mkdir -p "$VAULT_ROOT/raw/Field-Logs/FL-vol-001"
  mkdir -p "$VAULT_ROOT/raw/Field-Research/FR-vol-001"
  echo "  created raw/Field-Logs/FL-vol-001/ (your first Field Log)" >&2
  echo "  created raw/Field-Research/FR-vol-001/ (your first Field Research)" >&2
  echo "  (FS-vol-001 not pre-created — Field Study books are created during Phase II)" >&2
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
  # Check PATH first, then check common npm global locations
  if command -v "$cmd" > /dev/null 2>&1; then
    echo "  [installed] $name" >&2
  elif [ -x "$HOME/.npm-global/bin/$cmd" ]; then
    echo "  [installed] $name (found at ~/.npm-global/bin/$cmd but not in PATH)" >&2
    echo "              Add this to your shell config: export PATH=\"\$HOME/.npm-global/bin:\$PATH\"" >&2
  else
    echo "  [missing]   $name — to install: $install_cmd" >&2
  fi
}

check_tool "summarize"     "summarize"     "npm i -g @steipete/summarize"
check_tool "agent-browser" "agent-browser" "npm i -g agent-browser && agent-browser install"
# qmd is excluded from auto-check — the npm package is currently unreliable

# Check capture pipeline tools (required for Field Notes scanning workflow)
echo "" >&2
echo "Checking capture pipeline tooling..." >&2

check_capture_tool() {
  local name="$1"
  local cmd="$2"
  local install_note="$3"
  if command -v "$cmd" > /dev/null 2>&1; then
    echo "  [installed] $name" >&2
  else
    echo "  [missing]   $name — $install_note" >&2
  fi
}

check_capture_tool "rclone" "rclone" \
  "required for Proton Drive sync — see docs/CAPTURE.md for install instructions"
check_capture_tool "fuse3"  "fusermount3" \
  "required by rclone — install with: sudo apt install fuse3 -y"

# 5. Install SCHEMA.md (download from GitHub — works regardless of how the skill was installed)
echo "" >&2
SCHEMA_URL="https://raw.githubusercontent.com/k0d3x8its/kos/main/templates/SCHEMA.md"
SCHEMA_DEST="$VAULT_ROOT/SCHEMA.md"

if [ -f "$SCHEMA_DEST" ]; then
  echo "  SCHEMA.md already exists, skipping download" >&2
else
  echo "Installing SCHEMA.md..." >&2
  # Try curl first, then wget — most systems have at least one
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$SCHEMA_URL" -o "$SCHEMA_DEST" || {
      echo "ERROR: Failed to download SCHEMA.md from $SCHEMA_URL" >&2
      exit 3
    }
  elif command -v wget > /dev/null 2>&1; then
    wget -q "$SCHEMA_URL" -O "$SCHEMA_DEST" || {
      echo "ERROR: Failed to download SCHEMA.md from $SCHEMA_URL" >&2
      exit 3
    }
  else
    echo "ERROR: Neither curl nor wget is installed. Cannot download SCHEMA.md." >&2
    echo "Install one of them and re-run, or manually copy SCHEMA.md from:" >&2
    echo "  $SCHEMA_URL" >&2
    exit 3
  fi

  # Sanity check: file should be non-empty
  if [ ! -s "$SCHEMA_DEST" ]; then
    echo "ERROR: SCHEMA.md downloaded but is empty. Aborting." >&2
    rm -f "$SCHEMA_DEST"
    exit 3
  fi

  echo "  installed SCHEMA.md" >&2
fi

# 6. Final status
echo "" >&2
VAULT_ABS=$(cd "$VAULT_ROOT" && pwd)
echo "=== Onboarding scaffold complete ===" >&2
echo "Vault: $VAULT_ABS" >&2
echo "" >&2
echo "Next steps for the wizard:" >&2
echo "  1. Generate agent config file(s)" >&2
echo "  2. Append the setup entry to wiki/log.md" >&2

# 7. Open vault
# Open vault in Obsidian using path URI (works on unregistered vaults)
ENCODED_PATH=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$VAULT_ABS/wiki/index.md', safe='/'))")
OBSIDIAN_URI="obsidian://open?path=$ENCODED_PATH"

if command -v open > /dev/null 2>&1; then
  open "$OBSIDIAN_URI"                          # macOS
elif command -v xdg-open > /dev/null 2>&1; then
  xdg-open "$OBSIDIAN_URI"                      # Linux
elif command -v explorer.exe > /dev/null 2>&1; then
  explorer.exe "$OBSIDIAN_URI"                  # Windows (WSL)
else
  echo "  Vault ready. Open Obsidian and select: $VAULT_ABS" >&2
fi

exit 0
