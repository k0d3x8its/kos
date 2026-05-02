---
name: kos-archive
description: Use this skill when the user wants to archive a completed Field Notes memo book — typically when the physical book is full and being placed in a Layer 3 archive envelope. Triggers include "archive FL-vol-001", "kos archive", "I'm done with this book", "put this book in envelope 7", or any explicit request to mark a book as archived. The skill validates the book's wiki representation is complete, updates the book page's frontmatter (status, archived-on, envelope-number), optionally moves the page to wiki/books/_archived/, updates wiki/index.md, and logs the operation. Never modifies raw/ — archived books retain their immutable raw transcriptions. Do not use this skill to ingest new sources (use kos-ingest), to query (use kos-query), or to validate the entire wiki (use kos-lint).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# KOS — Archive

Mark a completed memo book as archived, tying the digital wiki to the physical Layer 3 archive envelope.

## Before You Begin: Read the Contract

**Always read `<vault-root>/SCHEMA.md` first.** SCHEMA.md Section 3.3 defines the archiving workflow this skill implements. The user may have customized it. If anything in this skill conflicts with SCHEMA.md, **SCHEMA.md wins**.

If `SCHEMA.md` does not exist at the vault root, stop and tell the user the vault is not initialized. Suggest they run `/kos`.

---

## What This Skill Does (and Doesn't)

This skill makes one specific transition: a book moves from `status: active` to `status: archived`, with metadata recording when and where (which envelope) it was archived.

**This skill MUST:**
- Validate the book is in a state where archiving makes sense (active, not already archived, has source pages)
- Run lint scoped to the book before archiving (per SCHEMA.md's "lint before archiving" recommendation)
- Update the book page's frontmatter atomically — all fields together, or none
- Optionally move the book page into `wiki/books/_archived/` for visual organization
- Update `wiki/index.md` to move the entry from `## Books` to `## Archived Books`
- Log the operation per SCHEMA.md Section 3.9

**This skill MUST NOT:**
- Touch `raw/` in any way. The raw transcriptions remain immutable per SCHEMA.md Section 6.1 rule 1.
- Modify `wiki/sources/` pages. Their `raw-path:` pointers must remain valid.
- Auto-fix lint findings. If the wiki representation is incomplete, surface the problems and let the user decide.
- Unarchive a book (reverse the operation). That's a separate workflow worth deliberate handling, not a flag on this skill.

---

## Identify the Book

Determine which book to archive:

1. **If the user specifies a volume** ("archive FL-vol-001"), use it. Validate the format matches `^F[LRS]-vol-\d{3}$`.

2. **If the user is ambiguous** ("archive my last book", "I just finished a book"), list active books from `wiki/books/` (top level only — books already in `_archived/` are not candidates):

```bash
   find wiki/books -maxdepth 1 -type f -name 'F[LRS]-vol-*.md'
```

   For each candidate, read the frontmatter and show: `volume`, `book-type`, `date-start`, `date-end`. Ask the user which one.

3. **Validate the book exists at `wiki/books/<volume>.md`.**
   - If it doesn't exist there but exists at `wiki/books/_archived/<volume>.md` → already archived. Tell the user, show the `archived-on` and `envelope-number`, and stop.
   - If it doesn't exist anywhere → tell the user the book has no wiki page yet. Suggest they run `/kos-ingest` on a page from the book first.
   - If it exists in both locations → this is a vault corruption that lint Check 2 should also flag. Stop and tell the user; this needs manual cleanup before archiving.

---

## Pre-Archive Validation

This is the most important part of the skill. Archiving signals "this book is done." We don't want to seal away a book whose wiki representation is incomplete — that's the moment when fixing it is cheapest.

### 1. Read the book page

Read `wiki/books/<volume>.md`. Confirm:
- `status:` is `active`. If it's anything else, stop and tell the user.
- The book has at least one source page in `wiki/sources/` linked from it. If zero sources, the book is empty — archiving an empty book is almost certainly a mistake. Ask the user to confirm before proceeding.

### 2. Run lint scoped to this book

Invoke the equivalent of `/kos-lint` filtered to this volume. Specifically check:

**Sources sync (Error if found):**
- Every file in `raw/<volume>/` must have a corresponding `wiki/sources/<volume>-<page>.md`. Look for unprocessed pages by checking that each `raw/<volume>/page-*.md` has a matching wiki source.

**Broken wikilinks within this book's pages (Error if found):**
- Read the book page and every source page from this book. Extract all `[[wikilink]]` references. Verify each target exists.

**Unresolved bit.ly slugs in this book's source pages (Warning if found):**
- Grep `wiki/log.md` for `unresolved-slug:` entries that reference source pages from this volume.

**Frontmatter validity on the book page itself (Error if found):**
- Verify `type: book`, `volume`, `book-type`, `date-start`, `date-end`, `status: active`, plus `subject` if `book-type: field-study`.

### 3. Report findings before proceeding

Present the lint results to the user. Three possible outcomes:

**Clean (no findings):** report it, proceed to "Collect Archive Metadata."

**Warnings only (typically unresolved slugs):** report them, ask the user:
> "Found N warnings. None block archiving — these slugs may be permanently unresolved (dead links, etc.). Archive anyway, or fix first?"

If "fix first," stop and tell the user to address the slugs (typically by re-ingesting the source after adding context, or by manually updating the source page) before re-running `/kos-archive`.

**Errors found:** report them, stop. Do NOT proceed to archiving. Tell the user:
> "Found N errors that should be resolved before archiving. Specifically: [list]. Run `/kos-ingest` for unprocessed sources, or fix the wiki manually. Then re-run `/kos-archive <volume>`."

The user CAN override errors with an explicit `--force` style instruction ("archive anyway"), but the skill must require an explicit override. Don't make it accidental.

---

## Collect Archive Metadata

Ask the user for two pieces of information. Provide sensible defaults.

### 1. Envelope number

Ask:
> "Which Layer 3 archive envelope is this book going into?"

Default suggestion: read the highest existing `envelope-number:` from any archived book page, add 1. If no books are archived yet, suggest 1.

```bash
# Find the highest existing envelope number
grep -rh '^envelope-number:' wiki/books/_archived/ 2>/dev/null \
  | awk '{print $2}' | sort -n | tail -1
```

If the user provides a non-sequential number (envelope 12 when 8 is the next), accept it. The skill records what the user tells it; envelope numbering is the user's prerogative.

### 2. Archive date

Ask:
> "When was the book physically archived? (default: today)"

Default: today's date in `YYYY-MM-DD` format. Accept any user-provided date in the same format. Validate the date is not in the future (an archive date later than today is almost certainly a typo).

If the date is more than 30 days in the past, confirm: "That's [N] days ago — is that right?" People archiving retrospectively is normal; people typo'ing the year is also normal. The check catches both.

---

## Apply the Archive

Now perform the actual archive operation. **Do all of these steps in this order. If any step fails, stop and tell the user — do NOT continue with a partially-archived book.**

### 1. Update the book page's frontmatter

Modify `wiki/books/<volume>.md` frontmatter:

- Set `status: archived`
- Add `archived-on: <date>` (the date from "Collect Archive Metadata")
- Add `envelope-number: <N>` (the envelope number from "Collect Archive Metadata")
- Update `updated:` to the current ISO 8601 timestamp

Preserve all other frontmatter fields exactly. Specifically: do NOT modify `created`, `volume`, `book-type`, `subject`, `date-start`, `date-end`, or `tags`.

### 2. Move the book page (default: yes; can be skipped)

Ask the user (unless they've already specified):
> "Move the book page to `wiki/books/_archived/`? (recommended for visual organization; wikilinks resolve either way)"

Default: yes.

If yes:
- Ensure `wiki/books/_archived/` exists (`mkdir -p wiki/books/_archived`)
- Move the file: `mv wiki/books/<volume>.md wiki/books/_archived/<volume>.md`

If no: leave the file at `wiki/books/<volume>.md`. The status field still drives behavior; the location is purely cosmetic.

Note for the user: wikilinks like `[[<volume>]]` continue to resolve regardless of which folder the file lives in, because Obsidian matches by filename, not path.

### 3. Update `wiki/index.md`

Two changes:

**Remove the entry from `## Books`:**
- Locate the line for `[[<volume>]]` under the `## Books` section header
- Delete that line (and any associated description)

**Add an entry to `## Archived Books`:**
- Format: `- [[<volume>]] — <existing-description-or-summary> (envelope <N>)`
- If the `## Archived Books` section doesn't exist (older index.md), create it after `## Books`

Update the "Last updated" timestamp at the top of index.md.

### 4. Append to `wiki/log.md`

Per SCHEMA.md Section 3.9 format:

```markdown
## 2026-05-01 14:32 — archive

- **Operation:** archive
- **Volume:** FL-vol-001
- **Archived-on:** 2026-04-02
- **Envelope:** 7
- **Page moved:** wiki/books/_archived/FL-vol-001.md (was wiki/books/FL-vol-001.md)
- **Lint findings before archive:** 0 errors, 1 warning (unresolved slug accepted)
- **Notes:** [free text or omit]
```

If the user chose not to move the page, write `Page moved: no (kept at wiki/books/FL-vol-001.md)` instead.

---

## Report Results

Tell the user:

1. **What was done:**
   - Volume archived: `FL-vol-001`
   - Envelope number: `7`
   - Archive date: `2026-04-02`
   - Page location: `wiki/books/_archived/FL-vol-001.md` (or top-level if not moved)
   - Index.md updated: yes
   - Log.md entry: yes

2. **Physical reminder:**
   > "Don't forget the physical step: write '7' on the envelope, place FL-vol-001 inside, and store the envelope in your archive box."

3. **What changed in the wiki:**
   - The book is now hidden from active views (`## Books` no longer lists it)
   - Queries can still find it via `## Archived Books` or by searching `wiki/books/_archived/` recursively
   - All `wiki/sources/` pages from this book are unchanged; their `raw-path:` pointers still resolve
   - Re-ingesting pages from this book will warn about adding to an archived book

4. **What to do next:** typically nothing. The user goes back to capturing in their next active book.

---

## Edge Cases

### User wants to extend an archived book

If the user later runs `/kos-ingest raw/FL-vol-001/page-097.md` after FL-vol-001 has been archived, ingest should warn them (per the ingest skill). If they confirm they want to extend, they should re-run `/kos-archive` on completion to update the date range and re-archive — but the existing envelope number stays.

This skill itself does not handle the extension flow. It just lets the user re-archive a book if its `status:` was set back to `active`.

### Archive metadata changed after archiving

If the user wants to correct envelope numbers, archive dates, or move a book between active and archived states, that's a manual edit to the book page's frontmatter. This skill is for the initial archive transition only.

### Multiple books archived in the same session

The skill handles one book per invocation. If the user wants to archive five books at once, they run the skill five times. This is deliberate — archiving is a deliberate, individually-considered action, not a batch operation. (If batch archiving becomes a real need later, build a separate `/kos-archive-batch` skill.)

---

## Conventions

- **Read SCHEMA.md first.** It is the source of truth.
- **Pre-archive lint is mandatory.** Don't seal away a book with broken wiki representation.
- **`raw/` is never touched.** Archive operations are wiki-only.
- **Frontmatter updates are atomic.** All four fields (status, archived-on, envelope-number, updated) change together, or none of them change.
- **Move is optional, status is mandatory.** The `_archived/` folder is visual organization. The `status: archived` field is what matters operationally.
- **One book per invocation.** No batch operations.
- **Errors block archiving by default.** Warnings prompt for confirmation. Override requires explicit user instruction.

---

## When to Archive

- **Physical book is full** — the most common case
- **Switching purposes** — you've decided FL-vol-007 is becoming a research book; archive it as a log book and start fresh
- **End of year** — some users archive on a calendar boundary even if books aren't full
- **Migrating to KOS** — bulk-archiving an existing physical archive when you first set up KOS

---

## Related Skills

- `/kos-ingest` — process raw sources into wiki pages (run before archiving to ensure raw/wiki sync)
- `/kos-query` — ask questions; archived books are still searchable
- `/kos-lint` — full vault health check (this skill runs lint scoped to one book; full lint catches cross-book issues)
