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
│
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

| Prefix | Type | Purpose | Entry format |
|--------|------|---------|--------------|
| `FL-vol-XXX` | Field Log | Daily log: what the user is doing, what's happening, observations of the day. Continuous chronological capture. | Structured header per entry (see Section 3.1.1) |
| `FR-vol-XXX` | Field Research | Catchall: things to learn, things to research, todos, scratch, lists, half-formed thoughts — anything that doesn't belong in the daily log. | Free-form; date stamp at end of session |
| `FS-vol-XXX` | Field Study | Dedicated subject book: a single subject pulled out for focused study. Created during Phase II — Data Extraction when a subject from `FL` or `FR` earns its own book. | Structured by subject hierarchy (see Section 3.1.2); no date stamps in handwriting — ingestion timestamp recorded in frontmatter |

`XXX` is the zero-padded volume number per type (e.g. `FL-vol-001`, `FR-vol-042`, `FS-vol-007`). Each prefix has its own independent volume sequence — `FL-vol-001`, `FR-vol-001`, and `FS-vol-001` are three different books.

#### 3.1.1 Field Log entry format

Field Log pages use a structured entry header. Each page contains **one or two
entries** — never more. A single entry may also span multiple pages when the
content is long.

**Entry header format:**

```
[DAY]  [TEMP]°  [TIME]  [DATE M/D/YY]
────────────────────────────────────────
[free-form journal text]
```

- `DAY` — three-letter abbreviation: `SUN`, `MON`, `TUE`, `WED`, `THU`, `FRI`, `SAT`
- `TEMP` — temperature in degrees (unit is Fahrenheit unless otherwise noted by
  the user), written as a number with a degree symbol: `59°`
- `TIME` — 12-hour clock with am/pm: `10:45am`
- `DATE` — session date in `M/D/YY` format: `5/3/26`
- A horizontal rule separates the header from the journal text and separates
  consecutive entries on the same page

**Multi-page entries.** When a single entry's journal text continues onto the next
physical page, the continuation page has no header — it begins mid-sentence. The
LLM MUST carry the most recent header's metadata forward as the canonical date,
time, temperature, and day for the continuation content.

**Two-entry pages.** When two entries appear on one page, each has its own header
and horizontal rule. The LLM MUST extract both entries independently and store
them as separate structured records within the source page.

**Extracted fields per entry** (used in `wiki/sources/` frontmatter — see
Section 3.2):

```yaml
entries:
  - date: YYYY-MM-DD       # M/D/YY converted to ISO 8601
    day: Sunday            # full day name, not abbreviation
    temp: 59               # integer, Fahrenheit
    time: "10:45am"        # string, preserve am/pm
    summary: ""            # brief LLM summary of this entry's content
  - date: YYYY-MM-DD
    day: Tuesday
    temp: 63
    time: "8:08am"
    summary: ""
```
#### 3.1.2 Field Study page format

Field Study pages are structured knowledge documents, not chronological logs.
They document a single subject in depth across one or more pages. There are no
date stamps in the handwriting — the ingestion timestamp in frontmatter serves
as the record of when the content entered the wiki.

**Required skeleton.** Every Field Study source page MUST include these sections
in this order. The LLM MUST create them even if the raw source has no content
for a section yet — leave the body empty and note it as unpopulated:

```markdown
## Origins
When, where, and how the subject began. Key historical context.

## Key Figures
People, organizations, or movements central to the subject.

## Core Principles
The fundamental ideas, rules, or frameworks that define the subject.

## Open Questions
What the user still wants to learn or investigate about this subject.
```

**Subject-specific sections.** After the required skeleton, the LLM MAY add
additional sections that fit the subject's unique structure. These are not
templated — the LLM derives them from the raw content. Examples:

- Stoicism: `## Virtues`, `## Practices`, `## Schools of Thought`
- A.I.: `## Architectures`, `## Training Methods`, `## Key Papers`

Subject-specific sections MUST appear after `## Core Principles` and before
`## Open Questions`.

**Multi-page studies.** A single Field Study subject may span many pages in the
physical book. The LLM MUST accumulate content across all ingested pages for the
same subject into the corresponding `wiki/sources/` page — it is a living
document, not a one-time snapshot. Each ingest from the same FS volume appends
and updates; it does not create a new source page per physical page.

**Frontmatter for Field Study sources:**

```yaml
---
type: source
raw-path:
  - raw/Field-Studies/FS-vol-001/page-001.pdf
  - raw/Field-Studies/FS-vol-001/page-002.pdf   # accumulates as pages are ingested
source-type: field-study-page
capture-mode: bare                               # or composite if stickies present
subject: Stoicism                                # must match wiki/books/ subject field
tags: []
created: YYYY-MM-DDTHH:MM:SSZ                   # set on first ingest, never updated
updated: YYYY-MM-DDTHH:MM:SSZ                   # updated on every subsequent ingest
---
```

Note that `created` is set once on first ingest and never changed. `updated`
reflects the most recent ingest from this study.

**Folder pattern.** All memo book folders match the regex `^F[LRS]-vol-\d{3}$` and reside under their respective parent directory (`raw/Field-Logs/`, `raw/Field-Research/`, `raw/Field-Studies/`).

**Other subdirectories:**
- `raw/assets/` — Binary files (images, scans) referenced by other raw sources.
- `raw/<topic>/` — Free-form folders for non-Field-Notes input (e.g. `raw/podcasts/`, `raw/papers/`, `raw/clippings/`). These live directly under `raw/`, not inside the typed subdirectories.

**Scanned page filename conventions.** When a Field Notes page is captured as a scanned PDF rather than a typed transcript, the filename encodes how many physical layers the scan contains. This tells the LLM how to interpret the scan and whether to wait for companion scans before ingesting.

| Suffix | Meaning | LLM behavior |
|--------|---------|--------------|
| `page-XXX` | Bare page, no stickies | Ingest immediately as a single source |
| `page-XXX-sticky` | Sticky note on top of page — both visible | Hold for companion scans; merge with `-under` and `-flip` if present |
| `page-XXX-under` | Sticky removed — full page revealed | Companion to `-sticky`; merged before ingest |
| `page-XXX-flip` | Sticky flipped over — back of sticky + page beneath visible | Companion to `-sticky`; merged before ingest |

**Merge rule.** Before creating a `wiki/sources/` page, the LLM MUST collect all files sharing the same `page-XXX` base (e.g. `page-012-sticky.pdf`, `page-012-under.pdf`, `page-012-flip.pdf`) and treat them as one composite source. The resulting source page in `wiki/sources/` gets a single entry — the base name without suffix (e.g. `FR-vol-001-page-012.md`). The `raw-path:` frontmatter field lists all companion files.

**Orphaned companion detection.** If a `-sticky` scan exists without a corresponding `-under` scan after 24 hours, `/kos-lint` MUST flag it as an incomplete capture. The user may have forgotten to scan the page underneath.

If the user adds a new memo book folder (any of the three prefixes), the LLM MUST create a corresponding page in `wiki/books/` on the next ingest.

### 3.2 `wiki/sources/` — One summary per source

One markdown file per ingested raw source. The filename is derived from the source filename:
- `raw/Field-Logs/FL-vol-001/page-007.md` → `wiki/sources/FL-vol-001-page-007.md`
- `raw/podcasts/2026-04-12-interview.md` → `wiki/sources/podcasts-2026-04-12-interview.md`

Each source page contains: a brief summary, key takeaways, wikilinks to related entities/concepts/questions, and the original source path.

**Frontmatter:** `type: source`, `raw-path`, `source-type`, `capture-mode`, `tags`,
`created`, `updated`. For `source-type: field-log-page`, also include `entries:`
per Section 3.1.1 — one list item per entry found on the page. For
`source-type: field-study-page`, also include `subject:` per Section 3.1.2 —
the subject must match the `subject:` field in the corresponding `wiki/books/`
page.

**`source-type` values for scanned Field Notes pages:**

| Value | When to use |
|-------|------------|
| `field-log-page` | Source came from `FL-vol-XXX` |
| `field-research-page` | Source came from `FR-vol-XXX` |
| `field-study-page` | Source came from `FS-vol-XXX` |

### 3.3 `wiki/books/` — One page per memo book

One markdown file per memo book of any type. Filename matches the `raw/` folder exactly: `wiki/books/FL-vol-001.md`, `wiki/books/FR-vol-042.md`, `wiki/books/FS-vol-007.md`.

Each book page contains: the book's date range, primary topics or subject (for `FS-` books), a list of all source pages from that book as wikilinks, and any cross-cutting observations the LLM has surfaced.

**The LLM MUST:**
- Create a `wiki/books/` page the first time it sees a new `raw/Field-Logs/FL-vol-*/`, `raw/Field-Research/FR-vol-*/`, or `raw/Field-Studies/FS-vol-*/` folder
- Set `book-type` in frontmatter according to the prefix (see mapping below)
- Append a wikilink to the new source on every ingest from that book
- Update the date range as new pages are added
- For `FS-` books, populate the `subject` field in frontmatter with the focused subject of the book

**Prefix → `book-type` mapping:**

| Prefix | `book-type` value |
|--------|-------------------|
| `FL-vol-XXX` | `field-log` |
| `FR-vol-XXX` | `field-research` |
| `FS-vol-XXX` | `field-study` |

**Frontmatter:**
```yaml
---
type: book
volume: FL-vol-001
book-type: field-log         # or "field-research" or "field-study"
subject: <subject-name>      # required for book-type: field-study; omit otherwise
date-start: YYYY-MM-DD
date-end: YYYY-MM-DD
status: active               # or "archived"
tags: [...]
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
---
```
**Archiving a book.** When the physical memo book is full and moved to a Layer 3 archive envelope, the user updates the corresponding `wiki/books/` page to reflect the archive. The `raw/<volume>/` folder is NEVER moved or deleted — raw transcriptions remain immutable per Section 6.1 rule 1, even after the book is archived. This preserves re-ingest capability and protects the integrity of all `raw-path:` pointers in `wiki/sources/`.

The archiving workflow:

1. Set `status: archived` in the book page's frontmatter
2. Set `archived-on: YYYY-MM-DD` (the date the physical book was placed in its envelope)
3. Set `envelope-number: <N>` (the Layer 3 archive envelope number)
4. **Optional but recommended:** move the book page from `wiki/books/<volume>.md` to `wiki/books/_archived/<volume>.md`. This is a purely visual organization aid that mirrors the physical archive (active books at the top, completed books tucked away). Wikilinks to the book continue to resolve because Obsidian matches by filename, not path.

Updated frontmatter for an archived book:

```yaml
---
type: book
volume: FL-vol-001
book-type: field-log
date-start: 2026-01-15
date-end: 2026-03-15
status: archived
archived-on: 2026-04-02
envelope-number: 7
tags: [...]
created: 2026-05-01T14:32:00Z
updated: 2026-04-02T10:15:00Z
---
```

When a book has `status: archived`, its entry in `wiki/index.md` MUST appear under the `## Archived Books` section header, not `## Books`. The LLM moves the entry on the next ingest or lint pass after the status change.

If new pages are added to `raw/<volume>/` after the book has been marked archived, ingest MUST warn the user: archiving signals the book is complete, and adding pages later is usually a mistake. The user can override the warning to extend the book's date range and re-open the archive.

### 3.4 `wiki/entities/` — People, orgs, products, tools, places

One page per entity. Filename is the entity name in kebab-case: `wiki/entities/anthropic.md`, `wiki/entities/claude-code.md`.

**Frontmatter:** `type: entity`, `entity-kind` (`person` | `organization` | `product` | `tool` | `place`), `aliases`, `tags`, `created`, `updated`.

### 3.5 `wiki/concepts/` — Ideas, frameworks, theories

One page per concept. Filename is the concept name in kebab-case: `wiki/concepts/zettelkasten.md`, `wiki/concepts/dependency-direction.md`.

**Frontmatter:** `type: concept`, `aliases`, `tags`, `created`, `updated`.

### 3.6 `wiki/synthesis/` — Cross-cutting analyses

One page per synthesis. Filename describes the synthesis: `wiki/synthesis/note-taking-systems-compared.md`.

Synthesis pages are written when the user asks `/kos-query` a question worth preserving, or when the LLM detects a pattern across multiple sources worth surfacing.

**Frontmatter:** `type: synthesis`, `tags`, `sources` (list of wikilinks), `created`, `updated`.

### 3.7 `wiki/questions/` — Open questions

One page per open question. Filename is the question in kebab-case, truncated: `wiki/questions/why-does-x-happen.md`.

**The LLM MUST extract questions from raw sources during ingest when:**
- The user explicitly writes a question (sentence ending in `?`)
- The user writes "TODO:", "look into:", "investigate:", "?:", "how to", "learn more" or similar follow-up markers
- A claim in raw material is unsupported and worth verifying

**Each question page contains:** the question, the source(s) where it came from (as wikilinks), the user's surrounding context, and a `status` field.

**Frontmatter:** `type: question`, `status` (`open` | `answered` | `dismissed`), `sources` (list of wikilinks), `answer-link` (optional wikilink to a synthesis page), `tags`, `created`, `updated`.

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
- [[FN-vol-001-page-007]]
- ...

## Entities
- ...

## Concepts
- ...

## Synthesis
- ...

## Questions (open)
- [[why-does-bit-ly-strip-trailing-slashes]]
- ...
```

### 3.9 `wiki/log.md` — Chronological operation record

Every operation appends an entry. The LLM MUST NOT rewrite or compact this file — it is append-only.

**Format:**
```markdown
## YYYY-MM-DD HH:MM — <operation>

- **Operation:** ingest | query | lint
- **Source(s):** <list, if applicable>
- **Pages affected:** <count and list>
- **Notes:** <free text, optional>
- **Unresolved:** <list of unresolved-slug, missing-context, etc.>
```

---

## 4. Page Format

Every wiki page MUST have YAML frontmatter and use Obsidian wikilinks (`[[double-bracket]]`), not markdown links, for internal references.

```markdown
---
type: source | book | entity | concept | synthesis | question
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
tags: [tag1, tag2]
# ... type-specific fields
---

# Page Title

Body content. Internal references use [[wikilinks]]. External URLs use markdown link syntax: [text](https://...).
```

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
- Must be at a word boundary (preceded by start-of-line, whitespace, or punctuation; followed by end-of-line, whitespace, or punctuation)
- Content between `<` and `>` MUST be alphanumeric only — slugs containing other characters (`<3`, `<see note>`, `<TODO>`) are NOT URL slugs and MUST be left literal

### 5.2 Capitalization (transcription rule)

In the user's handwriting, intended uppercase letters are marked with an underline beneath the letter. Bit.ly URLs are case-sensitive.

When transcribing scanned Field Notes pages into `raw/`:
- The transcribing LLM MUST read the underline annotations from the scan and produce the slug with correct capitalization
- A zero with a slash through it (`0̸` in the handwriting) is the digit `0`, not the letter `O` — transcribe as `0`
- After transcription, the slug in `raw/` is plain ASCII inside angle brackets — no underline markup is preserved

### 5.3 Ingest behavior

When ingesting a `raw/` source, for each `<{slug}>` match the LLM MUST:

1. Construct the URL: `https://bit.ly/{slug}` (preserve case exactly)
2. In the corresponding `wiki/sources/` page, render the slug as a markdown link:
```markdown
   [<F13LdN0t3>](https://bit.ly/F13LdN0t3)
```
3. If the user wrote a description near the slug in raw, include that description in the source summary
4. If the LLM has web access and the link's target is unknown, follow the redirect to determine what the link points to and add a one-line description
5. If the link target cannot be determined (no description, no web access, or the redirect fails), append an entry to `wiki/log.md`:
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
2. **`wiki/` is LLM-owned.** The user reviews; the LLM writes. The user MAY edit wiki pages, but should expect the LLM to reconcile its edits against this schema on the next operation.
3. **Every operation appends to `wiki/log.md`.** No exceptions.
4. **Every operation that creates or modifies wiki pages updates `wiki/index.md`.**
5. **Wikilinks are the primary linking mechanism.** Use `[[page-name]]` for internal references. Use markdown `[text](url)` only for external URLs.
6. **All filenames use kebab-case.** Lowercase, words separated by hyphens. ASCII only.
7. **Frontmatter is mandatory.** Every wiki page must have a complete YAML frontmatter block per Section 4.

### 6.2 Ingest rules

1. Read the source from `raw/` without modification.
2. Create exactly one `wiki/sources/` page per source. For Field Log sources,
   extract all entry headers (Section 3.1.1) and populate the `entries:` list
   in frontmatter. A page with two entries produces one source page with two
   items in `entries:`. A continuation page (no header) inherits the previous
   page's entry metadata.
3. Create or update the corresponding `wiki/books/` page if the source came from a memo book.
4. Extract entities into `wiki/entities/` (one page per entity, deduped by name and aliases).
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
- **Orphan pages** — pages with no incoming wikilinks (except books, sources, and the index/log)
- **Raw/wiki sync** — every file under `raw/` must have a corresponding `wiki/sources/` page; every folder matching `^F[LRS]-vol-\d{3}$` under `raw/Field-Logs/`, `raw/Field-Research/`, or `raw/Field-Studies/` must have a corresponding book page
- **Unresolved slugs** — `unresolved-slug:` entries in `log.md` that haven't been resolved
- **Schema-version mismatch** — vaults whose `schema-version` is older than the KOS-shipped schema
- **Frontmatter violations** — pages missing required frontmatter fields per Section 4
- **Duplicate entities** — multiple `wiki/entities/` pages that appear to refer to the same thing
- **Stale claims** — wiki content contradicting newer raw sources
- **Orphaned companion scans** — a `page-XXX-sticky` file in `raw/` with no corresponding `page-XXX-under` file after 24 hours (per Section 3.1 scanned page conventions)

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

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-05 | Initial KOS schema. Defines `raw/` (with `FL/FR/FS-vol-XXX` memo book conventions), `wiki/{sources,books,entities,concepts,synthesis,questions}/`, and `output/`. Establishes bit.ly slug convention (Section 5). Forked from NicholasSpisak/second-brain but versioned independently. |
| 2 | 2026-05 | Reorganized `raw/` into typed subdirectories: `Field-Logs/`, `Field-Research/`, `Field-Studies/`. Updated all path references and lint rules accordingly. |
| 3 | 2026-05 | Added scanned page filename conventions (Section 3.1)...
| 4 | 2026-06 | Added Field Log entry format (Section 3.1.1): structured header with day, temperature, time, and date. Added `entries:` frontmatter for `field-log-page` sources. Updated Section 3.2 and Section 6.2 ingest rules accordingly. |
| 5 | 2026-06 | Added Field Study page format (Section 3.1.2): required skeleton (Origins, Key Figures, Core Principles, Open Questions), subject-specific free-form sections, multi-page accumulation rule, and dedicated frontmatter. Updated Section 3.2 to require `subject:` field for `field-study-page` sources. |

---

*This schema is part of [KOS](https://github.com/k0d3x8its/kos), the Layer 1 toolkit for [Kodex OS](https://github.com/k0d3x8its/kodex-os).*
