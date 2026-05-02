#!/usr/bin/env bash
# test_skills.sh
# Validates every skill file in skills/ against the Agent Skills spec.
# Each skill MUST have YAML frontmatter with a `name` and `description` field.
# Reference: https://agentskills.io

set -euo pipefail

PASS=0
FAIL=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ❌ $1"; FAIL=$((FAIL + 1)); }

echo ""
echo "═══════════════════════════════════════"
echo "  TEST: Skill File Compliance"
echo "═══════════════════════════════════════"

# --- Check skills/ directory exists and is non-empty ---
echo ""
echo "▸ Checking skills/ directory..."

if [ ! -d "$SKILLS_DIR" ]; then
  echo "  ❌ skills/ directory not found — aborting"
  exit 1
fi

# Skills live in subdirectories — search recursively for .md files
SKILL_FILES=$(find "$SKILLS_DIR" -name "*.md" | head -1)
if [ -z "$SKILL_FILES" ]; then
  echo "  ❌ No .md files found anywhere in skills/ — aborting"
  exit 1
fi

pass "skills/ directory exists and contains .md files"

# --- Required skill files ---
# Skills live at skills/<name>/SKILL.md per the Agent Skills spec
echo ""
echo "▸ Checking required skill files exist..."

for skill in kos kos-ingest kos-query kos-lint; do
  if [ -f "$SKILLS_DIR/$skill/SKILL.md" ]; then
    pass "Skill file exists: $skill/SKILL.md"
  else
    fail "Missing skill file: $skill/SKILL.md"
  fi
done

# --- Frontmatter validation ---
# The Agent Skills spec requires YAML frontmatter delimited by ---
# with at minimum `name` and `description` fields.
echo ""
echo "▸ Validating YAML frontmatter in all skill files..."

while IFS= read -r skill_file; do
  # Show path relative to skills/ for readability
  name=$(realpath --relative-to="$SKILLS_DIR" "$skill_file")

  # Check frontmatter opening delimiter exists on line 1
  first_line=$(head -1 "$skill_file")
  if [ "$first_line" != "---" ]; then
    fail "$name: missing YAML frontmatter opening '---' on line 1"
    continue
  fi

  # Extract everything between the first and second ---
  frontmatter=$(awk '/^---/{n++; if(n==2) exit} n==1' "$skill_file")

  # Check `name:` field exists
  if echo "$frontmatter" | grep -q "^name:"; then
    pass "$name: has 'name' field"
  else
    fail "$name: missing 'name' field in frontmatter"
  fi

  # Check `description:` field exists
  if echo "$frontmatter" | grep -q "^description:"; then
    pass "$name: has 'description' field"
  else
    fail "$name: missing 'description' field in frontmatter"
  fi

  # Check description is not empty
  desc_value=$(echo "$frontmatter" | grep "^description:" | sed 's/^description:[[:space:]]*//')
  if [ -n "$desc_value" ]; then
    pass "$name: 'description' field is non-empty"
  else
    fail "$name: 'description' field is empty"
  fi
done < <(find "$SKILLS_DIR" -name "*.md")

# --- Summary ---
echo ""
echo "───────────────────────────────────────"
echo "  PASSED: $PASS  |  FAILED: $FAIL"
echo "───────────────────────────────────────"
echo ""

[ "$FAIL" -eq 0 ] || exit 1
