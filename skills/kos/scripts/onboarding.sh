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
  "raw/clippings"
  "raw/transcripts"
  "raw/transcripts/meetings"
  "raw/transcripts/youtube"
  "raw/transcripts/podcasts"
  "wiki"
  "wiki/sources"
  "wiki/books"
  "wiki/books/_archived"   # stores completed/retired Field Notes books
  "wiki/entities"
  "wiki/concepts"
  "wiki/synthesis"
  "wiki/questions"
  "output"
  "templates"
  "references"
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

check_tool "summarize"     "summarize"     "npm i -g @steipete/summarize"
check_tool "agent-browser" "agent-browser" "npm i -g agent-browser && agent-browser install"
check_tool "md-to-pdf"     "md-to-pdf"     "npm i -g md-to-pdf"
check_capture_tool "ripgrep" "rg" \
  "fast wiki search — brew install ripgrep  OR  sudo apt install ripgrep"
# qmd is excluded from auto-check — the npm package is currently unreliable

# Check capture pipeline tools (required for Field Notes scanning workflow)
echo "" >&2
echo "Checking capture pipeline tooling..." >&2

check_capture_tool "rclone" "rclone" \
  "required for Proton Drive sync — see docs/CAPTURE.md for install instructions"
check_capture_tool "fuse3"  "fusermount3" \
  "required by rclone — install with: sudo apt install fuse3 -y"

# 5. Install SCHEMA.md — copy from bundled template
echo "" >&2
SCHEMA_DEST="$VAULT_ROOT/SCHEMA.md"

# Look for SCHEMA.md in several possible locations relative to this script
POSSIBLE_SCHEMAS=(
  "$(cd "$(dirname "$0")/../../.." 2>/dev/null && pwd)/templates/SCHEMA.md"
  "$(cd "$(dirname "$0")/../../../.." 2>/dev/null && pwd)/templates/SCHEMA.md"
  "$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)/templates/SCHEMA.md"
  "$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)/templates/SCHEMA.md"
  "$(cd "$(dirname "$0")" 2>/dev/null && pwd)/templates/SCHEMA.md"
  "$(cd "$(dirname "$0")/../templates" 2>/dev/null && pwd)/SCHEMA.md"
)

BUNDLED_SCHEMA=""
for path in "${POSSIBLE_SCHEMAS[@]}"; do
  if [ -f "$path" ]; then
    BUNDLED_SCHEMA="$path"
    break
  fi
done

if [ -f "$SCHEMA_DEST" ]; then
  echo "  SCHEMA.md already exists, skipping" >&2
else
  echo "Installing SCHEMA.md..." >&2
  if [ -z "$BUNDLED_SCHEMA" ] || [ ! -f "$BUNDLED_SCHEMA" ]; then
    echo "ERROR: Bundled SCHEMA.md not found" >&2
    exit 3
  fi
  cp "$BUNDLED_SCHEMA" "$SCHEMA_DEST"
  echo "  installed SCHEMA.md from $BUNDLED_SCHEMA" >&2
fi

# 5b. Install vault templates — copy from bundled templates directory
echo "" >&2
echo "Installing vault templates..." >&2

BUNDLED_TEMPLATES_DIR=""
if [ -n "$BUNDLED_SCHEMA" ] && [ -f "$BUNDLED_SCHEMA" ]; then
  BUNDLED_TEMPLATES_DIR="$(dirname "$BUNDLED_SCHEMA")"
fi

for tpl in frontmatter-templates.md transcript-formats.md field-notes-formats.md; do
  DEST="$VAULT_ROOT/templates/$tpl"
  if [ -f "$DEST" ]; then
    echo "  templates/$tpl already exists, skipping" >&2
  elif [ -n "$BUNDLED_TEMPLATES_DIR" ] && [ -f "$BUNDLED_TEMPLATES_DIR/$tpl" ]; then
    cp "$BUNDLED_TEMPLATES_DIR/$tpl" "$DEST"
    echo "  installed templates/$tpl" >&2
  else
    echo "  WARNING: bundled template not found: $tpl — copy manually to $DEST" >&2
  fi
done

# 5c. Install vault references — copy from bundled references directory
echo "" >&2
echo "Installing vault references..." >&2

BUNDLED_REFS_DIR=""
if [ -n "$BUNDLED_TEMPLATES_DIR" ]; then
  CANDIDATE="$(dirname "$BUNDLED_TEMPLATES_DIR")/references"
  [ -d "$CANDIDATE" ] && BUNDLED_REFS_DIR="$CANDIDATE"
fi

for ref in ingest-log-examples.md lint-report-example.md schema-changelog.md; do
  DEST="$VAULT_ROOT/references/$ref"
  if [ -f "$DEST" ]; then
    echo "  references/$ref already exists, skipping" >&2
  elif [ -n "$BUNDLED_REFS_DIR" ] && [ -f "$BUNDLED_REFS_DIR/$ref" ]; then
    cp "$BUNDLED_REFS_DIR/$ref" "$DEST"
    echo "  installed references/$ref" >&2
  else
    echo "  WARNING: bundled reference not found: $ref — copy manually to $DEST" >&2
  fi
done

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
if command -v obsidian > /dev/null 2>&1; then
  obsidian &                                    # launch Obsidian in background
elif command -v xdg-open > /dev/null 2>&1; then
  xdg-open "obsidian://" &                      # fallback — open via URI handler
fi
echo "  Open Obsidian → Open Vault as Folder → $VAULT_ABS" >&2

exit 0
