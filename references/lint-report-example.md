# Lint Report Example

> Referenced by `kos-lint`. The LLM reads this file before writing the findings report.
> Present findings grouped by severity, then by check.

---

## Report Format

```markdown
# KOS Lint Report — YYYY-MM-DD HH:MM

**Scope:** Full audit
**Pages scanned:** 247 sources, 12 books, 89 entities, 34 concepts, 18 synthesis, 56 questions
**Schema version:** v5 (current)

## Errors (5)

### Check 1: Raw → wiki/sources/ sync
- `raw/Field-Logs/FL-vol-003/page-012.md` — no wiki/sources/ page
  Fix: run `/kos-ingest` on this file
- `raw/clippings/2026-04-20-article.md` — no wiki/sources/ page
  Fix: run `/kos-ingest` on this file

### Check 3: Broken wikilinks
- `wiki/concepts/zettelkasten.md:14` — `[[niklas-luhmann]]` does not exist
  Fix: create `wiki/entities/niklas-luhmann.md` or correct the link

### Check 5: Frontmatter validation
- `wiki/entities/anthropic.md` — missing required field: `entity-kind`
  Fix: add `entity-kind: organization` to frontmatter

### Check 7: Schema version
- Vault is on schema v3, KOS ships v5
  Fix: review diff in `templates/SCHEMA.md` upstream and update vault SCHEMA.md manually

## Warnings (3)

### Check 2b: Orphaned companion scans
- `raw/Field-Research/FR-vol-001/page-012-under.pdf` — no corresponding -sticky scan
  Fix: upload `page-012-sticky.pdf`, or rename this file if misnamed

### Check 6: Unresolved bit.ly slugs
- `unresolved-slug: <F13LdN0t3>` in [[FR-vol-001-page-007]]
  Fix: visit https://bit.ly/F13LdN0t3 and add a description in the source page

### Check 8: Orphan pages
- `wiki/concepts/dependency-direction.md` — no incoming wikilinks
  Fix: link from a relevant source or concept page, or delete if no longer relevant

## Info (1)

### Check 10: Stale claims
- `wiki/entities/anthropic.md` — last updated from a source 47 days ago; 3 newer sources mention Anthropic
  Fix: review and update the entity page

## Summary

- 5 errors require fixing
- 3 warnings should be reviewed
- 1 info item for consideration
```
