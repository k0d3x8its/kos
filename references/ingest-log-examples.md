# Log Entry Examples

> Referenced by `kos-ingest`, `kos-lint`, `kos-query`, and `kos-archive`. The LLM reads this file when writing a `wiki/log.md` entry.
> Format is defined in SCHEMA.md Section 3.9. `wiki/log.md` is append-only — never rewrite or compact it.

---

## Standard Entry (bare source, no issues)

```markdown
## 2026-05-01 14:32 — ingest

- **Operation:** ingest
- **Source(s):** raw/Field-Logs/FL-vol-001/page-007.md (source-type: field-log-page, capture-mode: bare)
- **Pages affected:** 1 created (sources), 1 updated (books), 2 created + 1 updated (entities), 1 created (concepts), 2 created (questions)
- **Notes:** First ingest from FL-vol-001.
```

## Entry with Unresolved Slug

```markdown
## 2026-05-01 14:32 — ingest

- **Operation:** ingest
- **Source(s):** raw/Field-Logs/FL-vol-001/page-007.md (source-type: field-log-page, capture-mode: bare)
- **Pages affected:** 1 created (sources), 1 updated (books), 2 created (entities), 1 created (concepts), 2 created (questions)
- **Unresolved:** unresolved-slug: <F13LdN0t3> in [[FL-vol-001-page-007]]
```

## Composite Scanned Source Entry

```markdown
## 2026-05-01 14:32 — ingest

- **Operation:** ingest
- **Source(s):** raw/Field-Research/FR-vol-001/page-007-sticky.pdf,
  page-007-under.pdf, page-007-flip.pdf (source-type: field-research-page,
  capture-mode: composite)
- **Pages affected:** 1 created (sources), 1 updated (books), 3 created (entities),
  1 created (concepts), 2 created (questions)
- **Notes:** Composite source — 3 companion scans merged.
```

## Composite Entry with Missing Companion

```markdown
## 2026-05-01 14:32 — ingest

- **Operation:** ingest
- **Source(s):** raw/Field-Research/FR-vol-001/page-007-sticky.pdf (source-type: field-research-page, capture-mode: composite)
- **Pages affected:** 1 created (sources), 1 updated (books), 2 created (entities)
- **Notes:** Ingested with missing companion — page-007-under.pdf not yet uploaded. User confirmed continue.
- **Unresolved:** missing-companion: page-007-under.pdf for [[FR-vol-001-page-007]]
```

## Archived Book Interaction — Silent Add

```markdown
## 2026-05-01 14:32 — ingest

- **Operation:** ingest
- **Source(s):** raw/Field-Logs/FL-vol-001/page-042.md (source-type: field-log-page, capture-mode: bare)
- **Pages affected:** 1 created (sources), 1 updated (books)
- **Notes:** Late-arriving page added to archived book FL-vol-001. Book remains archived (envelope 7).
```

## Query Entry

```markdown
## 2026-05-01 14:32 — query

- **Operation:** query
- **Question:** "What note-taking systems have I researched?"
- **Pages read:** [[zettelkasten]], [[para-method]], [[karpathy-llm-wiki]] (3 pages)
- **Answered from wiki:** yes
- **Synthesis saved:** [[note-taking-systems-compared]]
- **Notes:** Wiki had partial coverage; gap noted on digital implementations.
```

## Query Entry — Partial Answer

```markdown
## 2026-05-01 14:32 — query

- **Operation:** query
- **Question:** "What do my notes say about transformer architectures?"
- **Pages read:** [[attention-mechanism]], [[gpt-architecture]] (2 pages)
- **Answered from wiki:** partial
- **Notes:** Wiki covers attention but has no notes on positional encoding. Suggested ingesting a source on this topic.
```

## Query Entry — Not in Wiki

```markdown
## 2026-05-01 14:32 — query

- **Operation:** query
- **Question:** "What is my take on active recall?"
- **Pages read:** [[spaced-repetition]] (1 page)
- **Answered from wiki:** no
- **Notes:** No wiki pages found on active recall. Closest match was [[spaced-repetition]]. User offered web search or ingest.
```

---

## Lint Pass Entry

```markdown
## 2026-05-01 14:32 — lint

- **Operation:** lint
- **Scope:** full
- **Pages scanned:** 247 sources, 12 books, 89 entities, 34 concepts, 18 synthesis, 56 questions
- **Findings:** 5 errors, 3 warnings, 1 info
- **Fixes applied:** 2 (re-ingested raw/Field-Logs/FL-vol-003/page-012.md, raw/clippings/2026-04-20-article.md)
- **Notes:** 3 errors deferred per user. Companion scan warnings: 0.
```

---

## Archived Book Interaction — Re-open

```markdown
## 2026-05-01 14:32 — ingest

- **Operation:** ingest
- **Source(s):** raw/Field-Logs/FL-vol-001/page-042.md (source-type: field-log-page, capture-mode: bare)
- **Pages affected:** 1 created (sources), 1 updated (books)
- **Notes:** Re-opened archive: FL-vol-001 returned to active status. Moved from wiki/books/_archived/ to wiki/books/.
```

---

## Archive Entry

```markdown
## 2026-05-01 14:32 — archive

- **Operation:** archive
- **Volume:** FL-vol-001
- **Archived-on:** 2026-04-02
- **Envelope:** 7
- **Page moved:** wiki/books/_archived/FL-vol-001.md (was wiki/books/FL-vol-001.md)
- **Lint findings before archive:** 0 errors, 1 warning (unresolved slug accepted by user)
- **Notes:** [free text or omit]
```

## Archive Entry — Page Not Moved

```markdown
## 2026-05-01 14:32 — archive

- **Operation:** archive
- **Volume:** FR-vol-003
- **Archived-on:** 2026-04-02
- **Envelope:** 8
- **Page moved:** no (kept at wiki/books/FR-vol-003.md)
- **Lint findings before archive:** 0 errors, 0 warnings
```
