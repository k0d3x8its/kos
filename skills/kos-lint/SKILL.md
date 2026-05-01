---
name: kos-lint
description: Use this skill when the user wants to health-check their Kodex OS Layer 1 LLM Wiki for structural issues. Triggers include "lint kos", "check my wiki", "audit the wiki", "find broken links", or any explicit request for a wiki integrity report. The skill verifies that the vault conforms to its SCHEMA.md, that every raw/ source has a corresponding wiki/sources/ entry, that every memo book folder has a wiki/books/ entry, that wikilinks resolve, that frontmatter is valid, and that bit.ly slugs are resolved. Reports findings grouped by severity. Does not make changes unless the user explicitly approves each fix. Do not use this skill for routine ingest (use kos-ingest) or content questions (use kos-query).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# KOS — Lint

Health-check the wiki against SCHEMA.md and report issues with actionable fixes.

## Before You Begin: Read the Contract

**Always read `<vault-root>/SCHEMA.md` first.** It defines what valid structure looks like for this vault. The user may have customized it. SCHEMA.md Section 6.4 lists the checks lint MUST perform. If anything in this skill conflicts with SCHEMA.md, **SCHEMA.md wins**.

If `SCHEMA.md` does not exist at the vault root, stop and tell the user the vault is not initialized. Suggest they run `/kos`.

Note the `schema-version` from SCHEMA.md's YAML header. You'll compare it against the canonical version shipped with KOS later (Check 8).

---

## Determine Scope

Ask the user, unless they've already specified:

- **Full audit** (default) — all checks against the entire vault. Use after batches of ingests, monthly, or before major queries.
- **Quick audit** — Checks 1, 2, 3, 7, 8 only (structural integrity). Skips slow checks (orphans, duplicates, contradictions).
- **Scoped audit** — checks limited to a directory (`wiki/books/`), a recent time window ("since last lint"), or a specific book (`FL-vol-001`).
- **Deep audit** — full audit plus contradiction and stale-claim checks (Checks 9, 10). These are slow and produce false positives — only run when the user explicitly asks.

Default to **full audit** if the user just says "lint."

---

## Audit Checks

Run the checks in this order. Each finding gets a severity:

- **Error** — violates a SCHEMA.md MUST rule. Must be fixed.
- **Warning** — likely a problem but may be intentional.
- **Info** — suggestion, not a defect.

For every finding, capture: `severity`, `check`, `path`, `line` (if applicable), `message`, `suggested-fix`.

### Check 1: Raw → wiki/sources/ sync (Error)

Every file under `raw/` (excluding `raw/assets/` and binary files) must have a corresponding page in `wiki/sources/` per SCHEMA.md Section 3.2's filename derivation rule (`raw/<path>/<file>.md` → `wiki/sources/<path>-<file>.md`).

```bash
# List raw sources, excluding assets and binaries
find raw -type f -name '*.md' ! -path 'raw/assets/*'
```

For each raw file, derive the expected wiki source path. If the wiki source page does not exist, report:

- **Severity:** Error
- **Message:** `Unprocessed source: <raw-path> has no wiki/sources/ page`
- **Fix:** Run `/kos-ingest` on this file

### Check 2: Memo book → wiki/books/ sync (Error)

Every folder under `raw/` matching `^F[LRS]-vol-\d{3}$` must have a corresponding page at `wiki/books/<volume>.md` with a `book-type` in frontmatter that matches the prefix per SCHEMA.md Section 3.3.

```bash
find raw -maxdepth 1 -type d -regex '.*F[LRS]-vol-[0-9][0-9][0-9]'
```

For each memo book folder:

- If `wiki/books/<volume>.md` is missing → **Error**, fix: run `/kos-ingest` on a page from this book to trigger book page creation
- If `book-type` in frontmatter doesn't match the prefix mapping → **Error**, fix: correct the frontmatter

Prefix → expected `book-type`:

| Prefix | book-type |
|--------|-----------|
| `FL-vol-` | `field-log` |
| `FR-vol-` | `field-research` |
| `FS-vol-` | `field-study` |

### Check 3: Broken wikilinks (Error)

Scan all wiki pages for `[[wikilink]]` references and verify each target exists. Handle display aliases.

```bash
# Capture filename, line number, and link text
grep -rn '\[\[[^]]*\]\]' wiki/
```

For each match:

- Extract just the page name: in `[[page-name|display text]]`, take the part before `|`
- Resolve to a target file by searching `wiki/**/*.md` for `<page-name>.md`
- If no file matches → **Error**, message: `Broken wikilink: [[<page-name>]] in <file>:<line>`, fix: create the target page or correct the link

### Check 4: Index consistency (Error / Warning)

Verify `wiki/index.md` reflects reality:

- Every page in `wiki/{sources,books,entities,concepts,synthesis,questions}/` must have an entry in `index.md` under the matching section header → **Error** if missing
- No entry in `index.md` should point to a page that doesn't exist → **Error**
- Entries should be alphabetized within each section → **Warning** (cosmetic)

### Check 5: Frontmatter validation (Error)

For each wiki page, verify frontmatter against SCHEMA.md Section 4 and the type-specific fields in Section 3:

| Page directory | Required fields |
|----------------|-----------------|
| `wiki/sources/` | `type: source`, `raw-path`, `source-type`, `tags`, `created`, `updated` |
| `wiki/books/` | `type: book`, `volume`, `book-type`, `date-start`, `date-end`, `status`, `tags`, `created`, `updated`. Plus `subject` if `book-type: field-study` |
| `wiki/entities/` | `type: entity`, `entity-kind`, `aliases`, `tags`, `created`, `updated` |
| `wiki/concepts/` | `type: concept`, `aliases`, `tags`, `created`, `updated` |
| `wiki/synthesis/` | `type: synthesis`, `tags`, `sources`, `created`, `updated` |
| `wiki/questions/` | `type: question`, `status`, `sources`, `tags`, `created`, `updated` |

Also verify:
- `created` and `updated` are valid ISO 8601 timestamps (`YYYY-MM-DDTHH:MM:SSZ`)
- `type:` matches the directory the page is in
- `book-type:` for `wiki/books/` matches the volume prefix per Check 2's mapping

Each violation: **Error**, with the specific missing or malformed field named.

### Check 6: Unresolved bit.ly slugs (Warning)

Scan `wiki/log.md` for `unresolved-slug:` entries (per SCHEMA.md Section 5.3). For each, report:

- **Severity:** Warning
- **Message:** `Unresolved bit.ly slug: <slug> in <source-page>`
- **Fix:** Visit `https://bit.ly/<slug>` to determine the target, or add a description in the source page; then re-ingest

Cross-vault consistency (per SCHEMA.md Section 5.4): if the same slug appears in multiple `wiki/sources/` pages with different descriptions or different URLs, report:

- **Severity:** Warning
- **Message:** `Inconsistent slug usage: <slug> linked differently across <pages>`

### Check 7: Schema version (Error / Info)

Compare `schema-version` in the vault's SCHEMA.md against the canonical version shipped with the current KOS install (read from the skill's reference, or from the user's `npx skills` install metadata if available).

- If vault version < KOS version → **Error**: `Schema out of date: vault is on v<X>, KOS ships v<Y>`. Fix: review the diff in `templates/SCHEMA.md` upstream and update the vault. Lint should NOT auto-migrate the schema.
- If vault version > KOS version → **Info**: vault is ahead of the install (rare; user may have edited locally)
- If vault version == KOS version → no finding

### Check 8: Orphan pages (Warning)

A page is an orphan if no other page links to it via `[[wikilink]]`. Orphan checks **exclude**:

- `wiki/sources/` (sources are leaf nodes; many have no inbound links)
- `wiki/books/` (books are top-level containers, often only linked from index.md)
- `wiki/index.md` and `wiki/log.md` (special files)

For each remaining page (entities, concepts, synthesis, questions):

- Search all wiki pages for `[[<page-name>]]`
- If no match → **Warning**, message: `Orphan page: <path> has no incoming wikilinks`, fix: link it from a relevant source/concept/synthesis page, or delete if no longer relevant

### Check 9 (deep audit only): Duplicate entities (Warning)

Scan `wiki/entities/` for pages that appear to refer to the same thing:

- Compare `aliases:` lists across entity pages
- Compare titles for case-insensitive or whitespace-only differences
- Use the LLM to identify obvious duplicates (e.g., `wiki/entities/anthropic.md` and `wiki/entities/anthropic-pbc.md`)

For each candidate pair: **Warning**, fix: merge the pages, consolidate aliases, redirect wikilinks.

### Check 10 (deep audit only): Stale claims & contradictions (Info)

These checks are expensive and produce false positives. Only run during deep audit.

- **Stale claims:** an entity or concept page cites only sources older than N days when newer sources mention the same entity/concept
- **Contradictions:** two source summaries make opposing claims about the same entity or concept

For each: **Info**, fix: review and update the wiki page.

If the wiki has more than 100 pages, ask the user to scope this check (e.g., "check entities mentioned in sources from the last 30 days") rather than scanning everything.

---

## Report

Present findings grouped by severity, then by check:

```markdown
# KOS Lint Report — 2026-05-01 14:32

**Scope:** Full audit
**Pages scanned:** 247 sources, 12 books, 89 entities, 34 concepts, 18 synthesis, 56 questions
**Schema version:** v1 (current)

## Errors (5)

### Check 1: Raw → wiki/sources/ sync
- `raw/FL-vol-003/page-012.md` — no wiki/sources/ page (fix: `/kos-ingest`)
- `raw/clippings/2026-04-20-article.md` — no wiki/sources/ page (fix: `/kos-ingest`)

### Check 3: Broken wikilinks
- `wiki/concepts/zettelkasten.md:14` — `[[niklas-luhmann]]` does not exist
  Fix: create `wiki/entities/niklas-luhmann.md` or correct the link

...

## Warnings (3)

...

## Info (2)

...

## Summary

- 5 errors require fixing
- 3 warnings should be reviewed
- 2 info items for consideration
```

---

## After the Report

Ask the user, per finding (NOT batch):

> "Want to fix [Check 1: 2 unprocessed sources]? I'll run /kos-ingest on each. (yes / no / skip all errors)"

Process each error individually. The user may say:
- **yes** — apply this specific fix
- **no** — skip this finding, move to the next
- **skip all errors** — stop offering fixes; finish the report

Some findings have ambiguous fixes (orphan pages: link or delete? duplicate entities: which page survives?). For these, present the options and let the user choose. **Never auto-fix ambiguous findings.**

For findings the user approves, apply the fix and confirm what changed.

---

## Log the Lint Pass

Append to `wiki/log.md` per SCHEMA.md Section 3.9 format:

```markdown
## 2026-05-01 14:32 — lint

- **Operation:** lint
- **Scope:** full
- **Pages scanned:** 247 sources, 12 books, 89 entities, 34 concepts, 18 synthesis, 56 questions
- **Findings:** 5 errors, 3 warnings, 2 info
- **Fixes applied:** 2 (re-ingested raw/FL-vol-003/page-012.md, raw/clippings/2026-04-20-article.md)
- **Notes:** 3 errors deferred per user
```

---

## Conventions

- **Read SCHEMA.md first.** It is the source of truth.
- **Report by severity, fix per finding.** Never batch-apply fixes without per-item confirmation.
- **Errors map to SCHEMA.md MUST violations.** Warnings are likely problems. Info is advisory.
- **Don't auto-migrate schemas.** If the vault's schema is out of date, report it; let the user review the diff manually.
- **Bash paths are relative to vault root.** `cd` there before running grep/find commands.

---

## When to Lint

- **After every ~10 ingests** — catches gaps while context is fresh
- **Monthly minimum** — catches drift over time
- **Before major queries** — ensures wiki integrity before relying on it
- **Before archiving (Layer 3)** — confirms the wiki accurately reflects the raw material being archived

---

## Related Skills

- `/kos-ingest` — process new sources into wiki pages
- `/kos-query` — ask questions against the wiki
