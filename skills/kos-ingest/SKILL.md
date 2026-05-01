---
name: kos-ingest
description: Use this skill when the user wants to process raw sources into their Kodex OS Layer 1 LLM Wiki. Triggers include "ingest", "process my raw notes", "update the wiki", "add this to kos", or dropping new files into the vault's raw/ folder (scanned Field Notes pages, transcribed memo book pages, clipped articles, papers, transcripts). The skill reads from raw/, writes structured pages to wiki/, creates wikilinks and cross-references, expands inline bit.ly slugs, and updates wiki/index.md and wiki/log.md. Never modifies content in raw/ — that sub-layer is immutable per the KOS schema. Do not use this skill to answer questions about existing wiki content (use kos-query) or to check wiki health (use kos-lint).
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

**Always read `<vault-root>/SCHEMA.md` first.** It is the contract for this vault. The user may have edited it to override defaults. SCHEMA.md defines:

- The directory structure (Section 3)
- Page format requirements (Section 4)
- Inline conventions like the bit.ly slug expansion (Section 5)
- Operation rules you must follow (Section 6)

If anything in this skill conflicts with SCHEMA.md, **SCHEMA.md wins**. Tell the user about the conflict.

If `SCHEMA.md` does not exist at the vault root, stop and tell the user the vault is not initialized. Suggest they run `/kos`.

---

## Identify Sources to Process

Determine which files need ingestion:

1. **If the user specifies a file or files**, use those.

2. **If the user says "process new sources" or similar**, detect unprocessed files:
   - Glob all files in `raw/` recursively, excluding `raw/assets/` and any binary files (`.png`, `.jpg`, `.pdf`, etc. — these are referenced by other sources, not ingested directly)
   - For each candidate file, derive its expected wiki source filename per SCHEMA.md Section 3.2:
     - `raw/<path>/<file>.md` → `wiki/sources/<path>-<file>.md` (slashes become hyphens)
     - Example: `raw/FL-vol-001/page-007.md` → `wiki/sources/FL-vol-001-page-007.md`
   - A file is **unprocessed** if its derived `wiki/sources/` page does not exist
   - Do NOT rely on parsing `wiki/log.md` to detect unprocessed files — file existence is the source of truth

3. **If no unprocessed files are found**, tell the user and stop.

---

## Choose Ingest Mode

Ask the user which mode to use, unless they've already specified:

- **Quick mode** — ingest each source without checking in. Use when processing many sources at once or when the user has said "just ingest everything."
- **Discussion mode** — for each source, share key takeaways and confirm before writing. Use when the user wants to curate, especially for important sources or first-time ingests.

Default to discussion mode for the first source. If the user signals they want to keep going without checking in, switch to quick mode for the rest of the batch.

---

## Process Each Source

For each source file, follow this workflow:

### 1. Read the source completely

Read the entire file. If it references images in `raw/assets/`, read the relevant ones if they contain important information.

For memo book sources (`raw/FL-vol-XXX/`, `raw/FR-vol-XXX/`, `raw/FS-vol-XXX/`), also note:
- The book volume (e.g., `FL-vol-001`)
- Any date stamps on the page (per Kodex OS convention, format `M/D/YY` or similar)
- Cross-references to other pages in the same book

### 2. Discuss key takeaways (discussion mode only)

Share the 3–5 most important takeaways. Ask the user if they want to emphasize anything or skip topics. Wait for confirmation before proceeding.

In quick mode, skip this step.

### 3. Expand inline URL slugs (per SCHEMA.md Section 5)

Scan the source for any `<{slug}>` matches using the pattern `<[A-Za-z0-9]+>` at word boundaries.

For each match:
- Construct the URL: `https://bit.ly/{slug}` (preserve case exactly — bit.ly is case-sensitive)
- Look at surrounding context for a description the user wrote near the slug
- If you have web access and no description is present, follow the redirect to determine the target
- Hold these expanded URLs to embed in the source page (step 4) and cross-reference if they identify entities (step 5)

If a slug cannot be resolved (no description, no web access, or the redirect fails), **note it for the log entry in step 9** as `unresolved-slug: <{slug}>`.

**Do NOT expand:** angle-bracket spans containing non-alphanumeric characters (`<3`, `<see note>`, `<TODO>`). These are literal user notation, not URL slugs.

### 4. Create the source summary page

Create the file at the deterministic path per SCHEMA.md Section 3.2.

Use this frontmatter (matches SCHEMA.md Section 4):

```yaml
---
type: source
raw-path: raw/FL-vol-001/page-007.md
source-type: field-log-page    # or article, paper, transcript, podcast, etc.
tags: [tag1, tag2]
created: 2026-05-01T14:32:00Z
updated: 2026-05-01T14:32:00Z
---
```

Body structure:

```markdown
# Source Title

## Summary

Factual summary of the source content. No interpretation — save that for synthesis pages.

## Key Claims

- Claim 1
- Claim 2

## Entities Mentioned

- [[entity-name]] — brief context

## Concepts Covered

- [[concept-name]] — brief context

## Questions Raised

- [[why-does-x-happen]]

## External References

- [<F13LdN0t3>](https://bit.ly/F13LdN0t3) — description if known
```

The source summary is **factual only**. Save interpretation for `wiki/concepts/` and `wiki/synthesis/`.

### 5. Create or update the book page (memo book sources only)

If the source came from a folder matching `^F[LRS]-vol-\d{3}$`, the book has a corresponding page in `wiki/books/`.

**If the book page exists:**
- Append a wikilink to the new source page under the source list
- Update `date-end` in frontmatter if this page extends the book's date range
- Update the `updated:` timestamp

**If the book page does not exist** (first ingest from this book):
- Create `wiki/books/<volume>.md` (e.g., `wiki/books/FL-vol-001.md`)
- Use this frontmatter, with `book-type` mapped from the prefix per SCHEMA.md Section 3.3:

```yaml
---
type: book
volume: FL-vol-001
book-type: field-log    # field-log | field-research | field-study
subject:                # required for field-study; omit for others
date-start: 2026-01-15
date-end: 2026-01-15
status: active
tags: []
created: 2026-05-01T14:32:00Z
updated: 2026-05-01T14:32:00Z
---
```

For `FS-vol-XXX` (field-study) books, ask the user for the subject if it isn't obvious from context.

### 6. Update entity and concept pages

For each entity (person, organization, product, tool, place) and concept (idea, framework, theory, pattern) mentioned:

**If a wiki page exists:**
- Read it, add new information from this source
- Update the `updated:` timestamp
- If new information contradicts existing content, update the page AND note the contradiction with both sources cited

**If no wiki page exists:**
- Create one in the appropriate subdirectory (`wiki/entities/` or `wiki/concepts/`)
- Use kebab-case filenames (`anthropic.md`, `dependency-direction.md`)
- Include SCHEMA.md-compliant frontmatter

**Prefer updating existing pages over creating new ones.** Only create a new page when the topic is genuinely distinct.

### 7. Extract questions

Per SCHEMA.md Section 3.7, extract a question to `wiki/questions/` when:

- The user explicitly writes a question (sentence ending in `?`)
- The user writes "TODO:", "look into:", "investigate:", "?:", "how to", "learn more", or similar follow-up markers
- A claim in the raw source is unsupported and worth verifying

For each extracted question:
- Filename: kebab-case truncation of the question (`why-does-bit-ly-strip-trailing-slashes.md`)
- If the question already exists, add this source to its `sources:` list
- Set `status: open`

Frontmatter:

```yaml
---
type: question
status: open
sources: [[FL-vol-001-page-007]]
answer-link:           # optional wikilink to a synthesis page
tags: []
created: 2026-05-01T14:32:00Z
updated: 2026-05-01T14:32:00Z
---
```

### 8. Cross-link with wikilinks

Ensure all related pages link to each other using `[[wikilink]]` syntax. Every mention of an entity, concept, question, or book that has its own page should be linked. Use markdown `[text](url)` only for external URLs.

### 9. Update `wiki/log.md`

Append (per SCHEMA.md Section 3.9 — append-only, never rewrite):

```markdown
## 2026-05-01 14:32 — ingest

- **Operation:** ingest
- **Source(s):** raw/FL-vol-001/page-007.md
- **Pages affected:** 1 created (sources), 1 updated (books), 2 created + 1 updated (entities), 1 created (concepts), 2 created (questions)
- **Notes:** First ingest from FL-vol-001.
- **Unresolved:** unresolved-slug: <F13LdN0t3> in [[FL-vol-001-page-007]]
```

Omit the `Unresolved:` line if there's nothing unresolved.

### 10. Update `wiki/index.md`

Add an entry for each new page created, under the matching section header (Books, Sources, Entities, Concepts, Synthesis, Questions). Update the "Last updated" timestamp at the top of the file.

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
- **All filenames kebab-case, ASCII only**, per SCHEMA.md Section 6.1.
- **Frontmatter is mandatory** on every page, per SCHEMA.md Section 6.1.
- **`raw/` is immutable.** Never write to it. Period.

---

## What's Next

After ingesting:

- **Ask questions** with `/kos-query` to explore what was ingested
- **Ingest more sources** — `/kos-ingest` again
- **Health-check** with `/kos-lint` after every ~10 ingests to catch gaps
