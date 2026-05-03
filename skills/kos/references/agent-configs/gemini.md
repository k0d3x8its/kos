# {{VAULT_NAME}}

**Vault type:** KOS — Kodex OS Layer 1 Knowledge Base
**Purpose:** {{DOMAIN_DESCRIPTION}}
**Operated by:** Gemini CLI with Agent Skills
**Schema:** `./SCHEMA.md`

---

## Operating instructions

This vault is maintained through the KOS Agent Skills system. Before any operation, read `./SCHEMA.md` at the vault root. SCHEMA.md is the authoritative contract — it defines directory structure, page format, operation rules, and all conventions including:

- The bit.ly URL slug expansion convention (Section 5)
- The Field Notes memo book taxonomy (FL/FR/FS prefixes, Section 3.1)
- The archiving workflow and `wiki/books/_archived/` convention (Section 3.3)

If SCHEMA.md does not exist, stop and tell the user the vault is not initialized. Suggest running `/kos`.

## Skills

Five KOS skills govern all vault operations:

**`/kos`** — Onboarding wizard. Do not run on an existing vault.

**`/kos-ingest`** — Reads raw sources from `raw/`, creates structured wiki pages across six directories, expands bit.ly slugs, extracts entities/concepts/questions, updates `wiki/index.md` and `wiki/log.md`.

**`/kos-query`** — Searches the wiki for answers. Cites all claims with wikilinks. **Never fabricates** — when the wiki doesn't have an answer, says so explicitly rather than using training data.

**`/kos-lint`** — Health-checks the vault against SCHEMA.md. Eight structural checks minimum. Reports per-finding, never batch-applies fixes.

**`/kos-archive`** — Archives a completed memo book. Validates wiki completeness first, collects envelope metadata, updates frontmatter, moves book page to `wiki/books/_archived/`, updates index and log.

Do not perform vault operations outside these skills.

## Absolute rules

1. **`raw/` is immutable.** Do not write, rename, move, or delete anything under `raw/`. Archiving a book does not move its raw folder.
2. **No fabrication.** During `/kos-query`, answer only from wiki content. Silence means "the wiki doesn't have this" — say so.
3. **SCHEMA.md is authority.** Conflicts between skill instructions and SCHEMA.md resolve in favor of SCHEMA.md.

## Memo book structure

Physical Field Notes books map 1:1 to `raw/` folders:

| Prefix | Book type | When created |
|--------|-----------|--------------|
| `FL-vol-XXX` | Field Log | Always active — daily capture |
| `FR-vol-XXX` | Field Research | Always active — catchall |
| `FS-vol-XXX` | Field Study | Phase II — when a subject earns a dedicated book |

Active books: `wiki/books/<volume>.md` (`status: active`)
Archived books: `wiki/books/_archived/<volume>.md` (`status: archived`, `archived-on:`, `envelope-number:`)
