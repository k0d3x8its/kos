# Frontmatter Templates

> Referenced by SCHEMA.md. The LLM reads this file before creating or updating any wiki page.
> These are the canonical YAML frontmatter blocks for every page type in a KOS vault.

---

## Base Page Format

Every wiki page MUST have YAML frontmatter and use Obsidian wikilinks (`[[double-bracket]]`) for internal references. External URLs use markdown link syntax: `[text](https://...)`.

```markdown
---
type: source | book | entity | concept | synthesis | question
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
tags: [tag1, tag2]
# ... type-specific fields below
---

# Page Title

Body content.
```

---

## `wiki/sources/` — Source Page

```yaml
---
type: source
raw-path: raw/Field-Logs/FL-vol-001/page-007.md   # or list for composite scans
source-type: field-log-page                         # see values below
capture-mode: bare                                  # or composite if stickies present
tags: []
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
---
```

**`source-type` values:**

| Value | When to use |
|-------|-------------|
| `field-log-page` | Source came from `FL-vol-XXX` |
| `field-research-page` | Source came from `FR-vol-XXX` |
| `field-study-page` | Source came from `FS-vol-XXX` |

**For `field-log-page` sources**, also include `entries:` (one item per entry on the page):

```yaml
entries:
  - date: YYYY-MM-DD
    day: Sunday
    temp: 59
    time: "10:45am"
    summary: ""
  - date: YYYY-MM-DD
    day: Tuesday
    temp: 63
    time: "8:08am"
    summary: ""
```

**For `field-study-page` sources**, also include `subject:` (must match the `subject:` field in the corresponding `wiki/books/` page):

```yaml
---
type: source
raw-path:
  - raw/Field-Studies/FS-vol-001/page-001.pdf
  - raw/Field-Studies/FS-vol-001/page-002.pdf   # accumulates as pages are ingested
source-type: field-study-page
capture-mode: bare                               # or composite if stickies present
subject: Stoicism
tags: []
created: YYYY-MM-DDTHH:MM:SSZ                   # set on first ingest, never updated
updated: YYYY-MM-DDTHH:MM:SSZ                   # updated on every subsequent ingest
---
```

---

## `wiki/books/` — Book Page

```yaml
---
type: book
volume: FL-vol-001
book-type: field-log         # field-log | field-research | field-study
subject: <subject-name>      # required for book-type: field-study; omit otherwise
date-start: YYYY-MM-DD
date-end: YYYY-MM-DD
status: active               # or "archived"
tags: []
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
---
```

**Archived book variant** (add these fields when `status: archived`):

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
tags: []
created: 2026-05-01T14:32:00Z
updated: 2026-04-02T10:15:00Z
---
```

**Prefix → `book-type` mapping:**

| Prefix | `book-type` value |
|--------|-------------------|
| `FL-vol-XXX` | `field-log` |
| `FR-vol-XXX` | `field-research` |
| `FS-vol-XXX` | `field-study` |

---

## `wiki/entities/` — Entity Page

```yaml
---
type: entity
entity-kind: person          # person | organization | product | tool | place
aliases: []
tags: []
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
---
```

---

## `wiki/concepts/` — Concept Page

```yaml
---
type: concept
aliases: []
tags: []
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
---
```

---

## `wiki/synthesis/` — Synthesis Page

```yaml
---
type: synthesis
sources: []                  # list of wikilinks: [[source-page-name]]
tags: []
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
---
```

---

## `wiki/questions/` — Question Page

```yaml
---
type: question
status: open                 # open | answered | dismissed
sources: []                  # list of wikilinks
answer-link:                 # optional wikilink to a synthesis page
tags: []
created: YYYY-MM-DDTHH:MM:SSZ
updated: YYYY-MM-DDTHH:MM:SSZ
---
```
