---
name: kos-ingest
description: Use this skill when the user wants to process raw sources into their Kodex OS Layer 1 LLM Wiki. Triggers include "ingest", "process my raw notes", "update the wiki", "add this to kos", or dropping new files into the vault's raw/ folder (scanned Field Notes pages as PDFs, transcribed memo book pages, clipped articles, papers, transcripts). The skill reads from raw/, detects scanned PDF capture mode from filename suffixes (-sticky, -under, -flip), merges companion scans before ingesting, writes structured pages to wiki/, creates wikilinks and cross-references, expands inline bit.ly slugs, and updates wiki/index.md and wiki/log.md. Never modifies content in raw/ — that sub-layer is immutable per the KOS schema. Do not use this skill to answer questions about existing wiki content (use kos-query) or to check wiki health (use kos-lint).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# KOS — Ingest

Process raw source documents into structured, interlinked wiki pages.

## Before You Begin: Read the Contract

**Always read `<vault-root>/SCHEMA.md` first.** It is the contract for this vault. The user may have edited it to override defaults. If anything in this skill conflicts with SCHEMA.md, **SCHEMA.md wins** — tell the user about the conflict.

If `SCHEMA.md` does not exist at the vault root, stop and tell the user the vault is not initialized. Suggest they run `/kos`.

---

## Identify Sources to Process

Determine which files need ingestion:

1. **If the user specifies files**, use those.

2. **If the user says "process new sources" or similar**, detect unprocessed files:
   - Glob all files in `raw/` recursively, excluding `raw/assets/` and binary files (`.png`, `.jpg`, etc.)
   - Include `.pdf` files found in memo book folders — these are scanned Field Notes pages and ARE ingested directly
   - Before evaluating any `.pdf`, check for companion scans (see **Scanned PDF Capture Mode** below) and collect the full companion set first
   - For each candidate file (or merged companion set), derive its expected `wiki/sources/` filename per SCHEMA.md Section 3.2:
     - `raw/<path>/<file>.md` → `wiki/sources/<path>-<file>.md` (slashes become hyphens)
     - `raw/<path>/page-007-sticky.pdf` → base name `page-007` → `wiki/sources/<path>-page-007.md`
   - A file (or companion set) is **unprocessed** if its derived `wiki/sources/` page does not exist
   - Do NOT rely on `wiki/log.md` to detect unprocessed files — file existence is the source of truth

3. **If no unprocessed files are found**, tell the user and stop.

---

## Scanned PDF Capture Mode

When a source file in a memo book folder has a `.pdf` extension, it is a scanned Field Notes page. Detect the suffix and handle accordingly before ingesting.

### Suffix detection

| Filename pattern | Capture mode | LLM behavior |
|-----------------|--------------|--------------|
| `page-XXX.pdf` | Bare page | Ingest immediately as a single source |
| `page-XXX-sticky.pdf` | Sticky on top | Collect companion scans before ingesting |
| `page-XXX-under.pdf` | Sticky removed | Companion to `-sticky`; do not ingest alone |
| `page-XXX-flip.pdf` | Sticky back + page | Companion to `-sticky`; do not ingest alone |

### Companion collection

When a `-sticky` file is detected:

1. Search the same `raw/` folder for all files sharing the base name (`page-XXX`):
```bash
ls raw/Field-Research/FR-vol-001/page-007*.pdf
```
2. Collect whichever of the following exist: `-sticky`, `-under`, `-flip`
3. Treat the full companion set as **one composite source**
4. If `-under` is missing, warn the user before proceeding:
   > "`page-007-sticky.pdf` found but no `page-007-under.pdf`. The page text under the sticky may be incomplete. Continue anyway, or wait until the under-scan is uploaded?"

   Wait for the user's choice. If they say continue, ingest what is available and note the missing companion in `wiki/log.md`.

### Orphaned companion rule

A `-under` or `-flip` found without a corresponding `-sticky` is orphaned. Warn the user:

> "`page-007-under.pdf` found but no `page-007-sticky.pdf`. This companion has no primary scan. Is this file misnamed, or is the sticky scan still pending?"

Do not ingest an orphaned companion alone. Wait for user confirmation.

### Reading scanned PDFs

The LLM reads the PDF directly — no OCR tool required. Read all pages in each companion file before synthesizing. When reading, note:

- **Dates** — FR pages: date stamp in `M/D/YY` at bottom; use latest as canonical. FL pages: date is in the entry header. FS pages: no date stamps — use ingestion timestamp only.
- **Bit.ly slugs** — `<slug>` in angle brackets (SCHEMA.md Section 5). Underlined letters = uppercase.
- **Sticky note boundaries** — in `-sticky` scans, transcribe sticky and page content separately under clearly labeled subsections.
- **Doodles and drawings** — note their presence; describe only if they contain text or a URL slug.
- **Field Study structure** — FS pages are structured knowledge documents, not chronological. Map content to the appropriate skeleton section (Origins, Key Figures, Core Principles, Open Questions) or a subject-specific section. Do not treat unlabeled content as a new section. Read `./templates/field-notes-formats.md#field-study` before ingesting any FS source.
- **Field Log entry headers** — FL pages use a structured header per entry. Detect each header in format `[DAY]  [TEMP]°  [TIME]  [DATE M/D/YY]` followed by a horizontal rule. A page may have one or two entries. A continuation page (no header) inherits the most recent header's metadata. Read `./templates/field-notes-formats.md#field-log` before ingesting any FL source.

---

## Choose Ingest Mode

Ask the user which mode to use, unless already specified:

- **Quick mode** — ingest each source without checking in. Use for batches or when the user says "just ingest everything."
- **Discussion mode** — share key takeaways and confirm before writing each source. Use when the user wants to curate.

Default to discussion mode for the first source. If the user signals they want to keep going, switch to quick mode for the rest of the batch.

---

## Process Each Source

For each source file, follow this workflow in order.

### 1. Read the source completely

Read the entire file. If it references images in `raw/assets/`, read relevant ones if they contain important information.

For scanned PDF sources, companion collection and capture mode detection happen before this step — by the time Step 1 runs, the composite source is already assembled.

For memo book sources, also note:
- The book volume (e.g., `FL-vol-001`)
- Date stamps: FR pages end with `M/D/YY` — use latest as canonical. FL pages carry the date in the entry header. FS pages have no date stamps — use ingestion timestamp only.
- Cross-references to other pages in the same book

### 2. Discuss key takeaways (discussion mode only)

Share the 3–5 most important takeaways. Ask the user if they want to emphasize or skip anything. Wait for confirmation before proceeding. Skip in quick mode.

### 3. Expand inline URL slugs (per SCHEMA.md Section 5)

Scan for `<[A-Za-z0-9]+>` matches at word boundaries.

For each match:
- Construct the URL: `https://bit.ly/{slug}` (preserve case exactly — bit.ly is case-sensitive)
- Check surrounding context for a user-written description
- If web access is available and no description is present, follow the redirect to determine the target URL only — do not read, summarize, or incorporate any content from the destination page
- Hold expanded URLs to embed in Step 4 and cross-reference in Step 5 if they identify entities

If a slug cannot be resolved, note it for the log entry in Step 9 as `unresolved-slug: <{slug}>`.

**Do NOT expand:** angle-bracket spans with non-alphanumeric characters (`<3`, `<see note>`, `<TODO>`). These are literal user notation.

### 4. Create the source summary page

Create the file at the deterministic path per SCHEMA.md Section 3.2.

> Read `./templates/frontmatter-templates.md` for the complete frontmatter block before creating this page.

**Key frontmatter rules for this step:**
- `source-type`: `field-log-page` | `field-research-page` | `field-study-page` | `article` | `paper` | `transcript` | `podcast`
- `capture-mode`: `bare` (typed or single scan) | `composite` (merged companions)
- `subject`: field-study-page only — must match `wiki/books/` subject field; omit for all other source-types
- `entries`: field-log-page only — one list item per entry found on the page; omit for all other source-types
- For field-study-page: `created` is set once on first ingest and never changed; `updated` reflects every subsequent ingest
- For composite scans, `raw-path` is a list of all companion files

**Standard source body structure:**

```markdown
# Source Title

## Summary
Factual summary of the source content. No interpretation — save that for synthesis pages.

## Key Claims
- Claim 1

## Entities Mentioned
- [[entity-name]] — brief context

## Concepts Covered
- [[concept-name]] — brief context

## Questions Raised
- [[why-does-x-happen]]

## External References
- [<F13LdN0t3>](https://bit.ly/F13LdN0t3) — description if known
```

**For composite scanned sources**, use this body structure instead:

```markdown
# FR-vol-001 — Page 007

## Sticky Note (front)
Content from the sticky note front face.

## Page
Content from the full page (synthesized from -sticky visible area + -under reveal).

## Sticky Note (back)
Content from the sticky note back face (from -flip scan). Omit if no -flip scan exists.

## Summary
Synthesized factual summary across all layers.

## Key Claims / Entities Mentioned / Concepts Covered / Questions Raised / External References
```

**For field-study-page sources**, use the living document structure from `./templates/field-notes-formats.md#field-study`. Append and update on every ingest from the same FS volume — do NOT create a new source page per physical page.

The source summary is **factual only**. Save interpretation for `wiki/concepts/` and `wiki/synthesis/`.

### 5. Create or update the book page (memo book sources only)

If the source came from a folder matching `^F[LRS]-vol-\d{3}$` under `raw/Field-Logs/`, `raw/Field-Research/`, or `raw/Field-Studies/`, find the book page:

```bash
find wiki/books -name "<volume>.md" -type f
```

**Case 1: Active book page exists** (`wiki/books/<volume>.md`)
- Append a wikilink to the new source under the source list
- Update `date-end` if this page extends the book's date range
- Update `updated:` timestamp
- **Preserve all other frontmatter fields exactly as found** — never rewrite from scratch; merge only changed fields

**Case 2: Archived book page exists** (`wiki/books/_archived/<volume>.md`)

Stop and ask the user before proceeding:

> "FL-vol-001 is marked as archived (envelope 7, archived 2026-04-02). I found a new page being ingested for it. What would you like to do?
>
> 1. **Add silently** — keep archived; add this page to its source list and update `date-end`.
> 2. **Re-open the archive** — set `status: active`, clear `archived-on` and `envelope-number`, move back to `wiki/books/<volume>.md`.
> 3. **Cancel ingest** — this page might be in the wrong volume folder."

Wait for the user's choice:
- **Add silently** → update in place at `wiki/books/_archived/<volume>.md`. Preserve `status: archived`, `archived-on:`, and `envelope-number:` exactly.
- **Re-open** → move file to `wiki/books/<volume>.md`. Set `status: active`, remove `archived-on:` and `envelope-number:` entirely. Note the re-open in Step 9's log entry.
- **Cancel** → skip this source. Tell the user the source file is unchanged in `raw/`.

**Case 3: No book page exists** (first ingest from this book)

Create `wiki/books/<volume>.md`. For `FS-vol-XXX` books, ask the user for the subject if not obvious from context.

> Read `./templates/frontmatter-templates.md` for the complete book page frontmatter block.

**Frontmatter merge rule (all cases that update an existing page):** Read existing frontmatter. Update only fields that need to change. Leave every other field exactly as found. Do not normalize, reorder, or strip fields — they may be user customizations.

### 6. Update entity and concept pages

For each entity (person, org, product, tool, place) and concept (idea, framework, theory, pattern) mentioned:

**Page exists** → read it, add new information, update `updated:` timestamp. If new information contradicts existing content, update AND note the contradiction with both sources cited.

**No page exists** → create one in `wiki/entities/` or `wiki/concepts/` with kebab-case filename.

> Read `./templates/frontmatter-templates.md` for the complete entity and concept frontmatter blocks.

**Prefer updating over creating.** Only create a new page when the topic is genuinely distinct.

### 7. Extract questions

Per SCHEMA.md Section 3.7, extract a question to `wiki/questions/` when:
- The user explicitly writes a question (ends in `?`)
- The user writes `TODO:`, `look into:`, `investigate:`, `?:`, `how to`, `learn more`, or similar follow-up markers
- A claim is unsupported and worth verifying

Filename: kebab-case truncation of the question. If the question already exists, add this source to its `sources:` list.

> Read `./templates/frontmatter-templates.md` for the complete question frontmatter block.

### 8. Cross-link with wikilinks

Every mention of an entity, concept, question, or book that has its own page MUST be linked using `[[wikilink]]` syntax. Use markdown `[text](url)` only for external URLs.

### 9. Update `wiki/log.md`

Append only — never rewrite. If Step 5 Case 2 triggered an archived-book interaction, include a `**Notes:**` line recording what happened (e.g., `Late-arriving page added to archived book FL-vol-001` or `Re-opened archive: FL-vol-001 returned to active status`).

> Read `./references/ingest-log-examples.md` for the exact log entry format and examples.

Omit the `Unresolved:` line if there is nothing unresolved.

### 10. Update `wiki/index.md`

Add an entry for each new page under the matching section header. Section headers per SCHEMA.md Section 3.8:

- `## Books` — active books (`status: active`)
- `## Archived Books` — books with `status: archived`; include envelope number, e.g., `[[FL-vol-001]] — Daily log, Jan–Mar 2026 (envelope 7)`
- `## Sources`
- `## Entities`
- `## Concepts`
- `## Synthesis`
- `## Questions (open)` — `status: open` only; closed/dismissed questions are not indexed

On book status change (Case 2 re-open in Step 5): move the book's index entry between `## Books` and `## Archived Books` to match the new status.

Update the `_Last updated:_` timestamp at the top of the file.

### 11. Report results

Tell the user:
- Pages created (with wikilinks)
- Pages updated (with what changed)
- New entities, concepts, and questions identified
- Any contradictions found
- Any unresolved slugs

Keep this concise. The user can read the wiki for details.

---

## Conventions

- **Source pages are factual.** Interpretation goes in concepts and synthesis.
- A single source typically touches **5–15 wiki pages**. This is normal.
- **Prefer updating over creating.** New pages only when genuinely distinct.
- **Wikilinks for internal references**, never raw file paths.
- **All filenames kebab-case, ASCII only** per SCHEMA.md Section 6.1.
- **Frontmatter is mandatory** on every page per SCHEMA.md Section 6.1.
- **`raw/` is immutable.** Never write to it. Period.
- **Scanned PDFs are read directly.** No OCR tool needed. Companion scans are merged before any wiki page is written.
- **Never ingest a companion alone.** A `-under` or `-flip` without its `-sticky` is orphaned — warn the user and wait.

---

## What's Next

- **Ask questions** with `/kos-query`
- **Ingest more sources** with `/kos-ingest`
- **Health-check** with `/kos-lint` after every ~10 ingests
