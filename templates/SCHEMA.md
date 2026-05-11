# SCHEMA.md

> The contract between the user and the LLM for a Kodex OS Layer 1 (KOS) vault.
> The LLM reads this file before every operation. The user owns this file — edit it to adjust the rules KOS follows in this vault.

```yaml
schema-version: 5
schema-source: https://github.com/k0d3x8its/kos
kos-vault: true
```

---

## 1. Purpose

This vault implements **Layer 1** of [Kodex OS](https://github.com/k0d3x8its/kodex-os) — the LLM-maintained Knowledge Base. It bridges Layer 0 (raw capture, e.g., Field Notes memo books) and Layer 2 (Notion / project intelligence).

The LLM operates as the librarian. The user is the curator. The user provides raw material; the LLM organizes, interlinks, and maintains the wiki. The user reviews.

This file defines:
- The directory structure the LLM must respect
- What kind of content goes in each directory
- The rules the LLM must follow when reading, writing, and maintaining the vault
- How the LLM extracts structured information (URL slugs, questions, etc.) from raw sources

---

## 2. Directory Structure

```text
<vault-root>/
├── raw/                    # Inbox — user-owned, immutable to the LLM
│   ├── Field-Logs/         # Contains FL-vol-XXX memo book folders
│   │   └── FL-vol-XXX/     # Field Log: daily log memo books
│   ├── Field-Research/     # Contains FR-vol-XXX memo book folders
│   │   └── FR-vol-XXX/     # Field Research: catchall research memo books
│   ├── Field-Studies/      # Contains FS-vol-XXX memo book folders
│   │   └── FS-vol-XXX/     # Field Study: dedicated subject memo books
│
├── wiki/                   # LLM-owned, LLM-maintained
│   ├── sources/            # One summary page per ingested raw source
│   ├── books/              # One summary page per memo book
│   ├── entities/           # People, organizations, products, tools, places
│   ├── concepts/           # Ideas, frameworks, theories, definitions
│   ├── synthesis/          # Cross-cutting analyses, comparisons, themes
│   ├── questions/          # Open questions extracted from raw sources
│   ├── index.md            # Master catalog of all wiki pages
│   └── log.md              # Chronological record of every operation
│
├── output/                 # Generated reports, query results, exports
├── templates/              # Frontmatter templates and capture format specs
├── references/             # Schema changelog and lookup tables
└── SCHEMA.md               # This file
```

The agent config file (`CLAUDE.md`, `AGENTS.md`, `.cursor/rules/kos.mdc`, etc.) lives at the vault root and references this schema.

---

## 3. Directory Definitions

Each directory has a defined purpose. The LLM MUST route content according to these definitions.

### 3.1 `raw/` — User-owned input

**Owner:** The user.
**LLM access:** Read-only. The LLM MUST NEVER modify, rename, delete, or reorganize files under `raw/`.

Contains source material the user has provided: scanned and transcribed Field Notes pages, clipped articles, papers, transcripts, audio transcriptions, and any other input the user wants the LLM to ingest.

**Memo book conventions.** Every Field Notes memo book has a one-to-one mapping to a folder under `raw/`. All prefixes begin with `F` for Field Notes (the brand); the second letter denotes purpose. Three book types are recognized:

| Prefix | Type | Purpose |
|--------|------|---------|
| `FL-vol-XXX` | Field Log | Daily log: what the user is doing, what's happening, observations of the day. Continuous chronological capture. |
| `FR-vol-XXX` | Field Research | Catchall: things to learn, research, todos, scratch, lists, half-formed thoughts. |
| `FS-vol-XXX` | Field Study | Dedicated subject book: a single subject pulled out for focused study. Created during Phase II — Data Extraction. |

`XXX` is the zero-padded volume number per type (e.g. `FL-vol-001`, `FR-vol-042`, `FS-vol-007`). Each prefix has its own independent volume sequence.

#### 3.1.1 Field Log entry format

> Read `./templates/field-notes-formats.md#field-log` before ingesting any FL source.

Key rules the LLM MUST apply without re-reading the template:
- Each page has one or two entries, never more
- Continuation pages (no header) inherit the previous page's entry metadata
- Two-entry pages: extract both entries as separate records in `entries:` frontmatter

#### 3.1.2 Field Study page format

> Read `./templates/field-notes-formats.md#field-study` before ingesting any FS source.

Key rules the LLM MUST apply without re-reading the template:
- Required skeleton sections: Origins → Key Figures → Core Principles → Open Questions
- Subject-specific sections go between Core Principles and Open Questions
- Multi-page studies accumulate into one living `wiki/sources/` page — do NOT create a new source page per physical page

**Folder pattern.** All memo book folders match the regex `^F[LRS]-vol-\d{3}$` and reside under their respective parent directory.

**Other subdirectories:**
- `raw/assets/` — Binary files (images, scans) referenced by other raw sources
- `raw/<topic>/` — Free-form folders for non-Field-Notes input (e.g. `raw/podcasts/`, `raw/clippings/`)

**Scanned page filename conventions.**

| Suffix | Meaning | LLM behavior |
|--------|---------|--------------|
| `page-XXX` | Bare page, no stickies | Ingest immediately |
| `page-XXX-sticky` | Sticky on top of page — front of sticky + visible page text around it | Hold; merge with `-under` and `-flip` if present |
| `page-XXX-under` | Sticky peeled back (not removed) — reveals page text hidden beneath it | Companion to `-sticky`; merge before ingest |
| `page-XXX-flip` | Back of the sticky only — captured while peeled back | Companion to `-sticky`; merge before ingest |

**Merge rule.** Collect all files sharing the same `page-XXX` base and treat as one composite source. The resulting `wiki/sources/` page uses the base name (e.g. `FR-vol-001-page-012.md`). The `raw-path:` frontmatter field lists all companion files.

**Orphaned companion detection.** If a `-sticky` scan exists without a corresponding `-under` scan after 24 hours, `/kos-lint` MUST flag it as an incomplete capture.

If the user adds a new memo book folder, the LLM MUST create a corresponding `wiki/books/` page on the next ingest.

### 3.2 `wiki/sources/` — One summary per source

One markdown file per ingested raw source. Filename derived from the source filename:
- `raw/Field-Logs/FL-vol-001/page-007.md` → `wiki/sources/FL-vol-001-page-007.md`
- `raw/podcasts/2026-04-12-interview.md` → `wiki/sources/podcasts-2026-04-12-interview.md`

Each source page contains: a brief summary, key takeaways, wikilinks to related entities/concepts/questions, and the original source path.

> Read `./templates/frontmatter-templates.md` for the full frontmatter block before creating a source page.

### 3.3 `wiki/books/` — One page per memo book

One markdown file per memo book. Filename matches the `raw/` folder exactly: `wiki/books/FL-vol-001.md`.

Each book page contains: the book's date range, primary topics or subject (for `FS-` books), a list of all source pages from that book as wikilinks, and cross-cutting observations.

**The LLM MUST:**
- Create a `wiki/books/` page the first time it sees a new memo book folder
- Append a wikilink to the new source on every ingest from that book
- Update the date range as new pages are added
- For `FS-` books, populate the `subject` field in frontmatter

**Archiving a book.** When the physical memo book is full and moved to a Layer 3 archive envelope:

1. Set `status: archived` in frontmatter
2. Set `archived-on: YYYY-MM-DD`
3. Set `envelope-number: <N>`
4. Optionally move the page to `wiki/books/_archived/<volume>.md` (visual organization only — wikilinks still resolve)

The `raw/<volume>/` folder is NEVER moved or deleted — raw transcriptions remain immutable per Section 6.1 rule 1.

When a book has `status: archived`, its entry in `wiki/index.md` MUST appear under `## Archived Books`, not `## Books`.

If new pages are added to `raw/<volume>/` after the book is marked archived, ingest MUST warn the user. The user can override to extend the date range and re-open the archive.

> Read `./templates/frontmatter-templates.md` for the full frontmatter block before creating a book page.

### 3.4 `wiki/entities/` — People, orgs, products, tools, places

One page per entity. Filename is the entity name in kebab-case: `wiki/entities/anthropic.md`.

`entity-kind` values: `person` | `organization` | `product` | `tool` | `place`

> Read `./templates/frontmatter-templates.md` for the full frontmatter block.

### 3.5 `wiki/concepts/` — Ideas, frameworks, theories

One page per concept. Filename is the concept name in kebab-case: `wiki/concepts/zettelkasten.md`.

> Read `./templates/frontmatter-templates.md` for the full frontmatter block.

### 3.6 `wiki/synthesis/` — Cross-cutting analyses

One page per synthesis. Filename describes the synthesis: `wiki/synthesis/note-taking-systems-compared.md`.

Written when the user asks `/kos-query` a question worth preserving, or when the LLM detects a cross-source pattern worth surfacing.

> Read `./templates/frontmatter-templates.md` for the full frontmatter block.

### 3.7 `wiki/questions/` — Open questions

One page per open question. Filename is the question in kebab-case, truncated: `wiki/questions/why-does-x-happen.md`.

**The LLM MUST extract questions from raw sources during ingest when:**
- The user explicitly writes a question (sentence ending in `?`)
- The user writes `TODO:`, `look into:`, `investigate:`, `?:`, `how to`, `learn more`, or similar follow-up markers
- A claim in raw material is unsupported and worth verifying

Each question page contains: the question, source wikilinks, the user's surrounding context, and a `status` field.

> Read `./templates/frontmatter-templates.md` for the full frontmatter block.

### 3.8 `wiki/index.md` — Master catalog

The catalog of every page in the wiki, grouped by directory, sorted alphabetically. The LLM MUST update this file on every ingest.

**Format:**
```markdown
# Wiki Index

_Last updated: YYYY-MM-DD HH:MM_

## Books
- [[FR-vol-001]] — KOS architecture research

## Archived Books
- [[FL-vol-001]] — Daily log, Jan–Mar 2026 (envelope 7)

## Sources
- [[FL-vol-001-page-007]]

## Entities
## Concepts
## Synthesis
## Questions (open)
```

### 3.9 `wiki/log.md` — Chronological operation record

Every operation appends an entry. The LLM MUST NOT rewrite or compact this file — it is append-only.

**Format:**
```markdown
## YYYY-MM-DD HH:MM — <operation>

- **Operation:** ingest | query | lint | setup
- **Source(s):** <list, if applicable>
- **Pages affected:** <count and list>
- **Notes:** <free text, optional>
- **Unresolved:** <list of unresolved-slug, missing-context, etc.>
```

---

## 4. Page Format

> Read `./templates/frontmatter-templates.md` before creating any wiki page for the complete YAML frontmatter block for each page type.

Every wiki page MUST have YAML frontmatter and use Obsidian wikilinks (`[[double-bracket]]`) for internal references. External URLs use markdown link syntax: `[text](https://...)`. All filenames use kebab-case.

---

## 5. Inline URL Slug Convention

The user references websites in Field Notes using a shortened bit.ly slug encoded in angle brackets. The LLM MUST recognize and expand these during ingest.

### 5.1 Format

```
<F13LdN0t3>
```

This represents `https://bit.ly/F13LdN0t3`.

**Match rule:**
- Pattern: `<[A-Za-z0-9]+>`
- Must be at a word boundary
- Content MUST be alphanumeric only — `<3`, `<see note>`, `<TODO>` are NOT slugs and MUST be left literal

### 5.2 Capitalization (transcription rule)

In the user's handwriting, intended uppercase letters are marked with an underline beneath the letter. Bit.ly URLs are case-sensitive.

- The transcribing LLM MUST read underline annotations and produce the slug with correct capitalization
- A zero with a slash through it (`0̸`) is the digit `0`, not the letter `O`
- After transcription, the slug in `raw/` is plain ASCII — no underline markup preserved

### 5.3 Ingest behavior

For each `<{slug}>` match the LLM MUST:

1. Construct the URL: `https://bit.ly/{slug}` (preserve case exactly)
2. Render the slug as a markdown link in `wiki/sources/`:
   ```markdown
   [<F13LdN0t3>](https://bit.ly/F13LdN0t3)
   ```
3. Include any user-written description near the slug in the source summary
4. If the LLM has web access and the link target is unknown, follow the redirect and add a one-line description
5. If the link target cannot be determined, append to `wiki/log.md`:
   ```
   - **Unresolved:** unresolved-slug: <F13LdN0t3> in [[FR-vol-001-page-007]]
   ```

### 5.4 Cross-vault consistency

If the same slug appears in multiple sources, all `wiki/sources/` pages MUST link to the same URL with the same description. If descriptions diverge, `/kos-lint` flags the inconsistency.

---

## 6. Operation Rules

The LLM follows these rules during every operation. They are non-negotiable unless the user explicitly overrides them in this file.

### 6.1 Universal rules

1. **`raw/` is immutable.** The LLM MUST NEVER write to, rename, or delete files under `raw/`. Period.
2. **`wiki/` is LLM-owned.** The user reviews; the LLM writes.
3. **Every operation appends to `wiki/log.md`.** No exceptions.
4. **Every operation that creates or modifies wiki pages updates `wiki/index.md`.**
5. **Wikilinks are the primary linking mechanism.** Use `[[page-name]]` for internal references.
6. **All filenames use kebab-case.** Lowercase, words separated by hyphens. ASCII only.
7. **Frontmatter is mandatory.** Every wiki page must have a complete YAML frontmatter block per Section 4.

### 6.2 Ingest rules

1. Read the source from `raw/` without modification.
2. Create exactly one `wiki/sources/` page per source. For FL sources, extract all entry headers and populate `entries:` in frontmatter. A continuation page (no header) inherits the previous page's entry metadata.
3. Create or update the corresponding `wiki/books/` page if the source came from a memo book.
4. Extract entities into `wiki/entities/` (deduped by name and aliases).
5. Extract concepts into `wiki/concepts/`.
6. Extract questions into `wiki/questions/`.
7. Expand all `<slug>` matches per Section 5.
8. Cross-link all extracted pages with wikilinks.
9. Update `wiki/index.md`.
10. Append to `wiki/log.md`.

### 6.3 Query rules

1. Read `wiki/index.md` to find candidate pages.
2. Follow wikilinks to gather context.
3. Synthesize an answer with wikilink citations to specific wiki pages.
4. Offer to save the answer as a `wiki/synthesis/` page if it represents new analysis.
5. If the answer requires information not in the wiki, say so explicitly — do NOT fabricate.
6. Append the query and result summary to `wiki/log.md`.

### 6.4 Lint rules

The LLM MUST report (not fix, unless explicitly approved) the following:

- **Broken wikilinks** — links to pages that don't exist
- **Orphan pages** — pages with no incoming wikilinks (except books, sources, index, log)
- **Raw/wiki sync** — every file under `raw/` must have a `wiki/sources/` page; every memo book folder must have a `wiki/books/` page
- **Unresolved slugs** — `unresolved-slug:` entries in `log.md` not yet resolved
- **Schema-version mismatch** — vault schema older than KOS-shipped schema (see `./references/schema-changelog.md`)
- **Frontmatter violations** — pages missing required fields per Section 4
- **Duplicate entities** — multiple entity pages appearing to refer to the same thing
- **Stale claims** — wiki content contradicting newer raw sources
- **Orphaned companion scans** — a `page-XXX-sticky` with no corresponding `page-XXX-under` after 24 hours

---

## 7. Customization

The user MAY edit this file to:

- Add new wiki subdirectories (extend Section 3)
- Add new frontmatter fields (extend Section 4)
- Add new inline conventions like the bit.ly slug (extend Section 5)
- Soften or strengthen any operation rule (modify Section 6)

The user MUST NOT:

- Change `raw/` to be writable by the LLM
- Remove `wiki/index.md` or `wiki/log.md`
- Change the `schema-version` field manually (let `/kos-lint` handle migrations)

After editing this file, run `/kos-lint` to confirm the existing wiki still conforms.

---

## 8. Schema Version History

> See `./references/schema-changelog.md`.

---

*This schema is part of [KOS](https://github.com/k0d3x8its/kos), the Layer 1 toolkit for [Kodex OS](https://github.com/k0d3x8its/kodex-os).*
