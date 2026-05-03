# {{VAULT_NAME}}

> This is a KOS vault — a Kodex OS Layer 1 knowledge base maintained by you and this agent together.
> Your role: librarian. The user's role: curator.
> All operating rules live in `./SCHEMA.md`. Read it before every operation.

## Vault

**Name:** {{VAULT_NAME}}
**Purpose:** {{DOMAIN_DESCRIPTION}}
**Schema:** `./SCHEMA.md` (schema-version tracked in its YAML header)
**Layer:** Kodex OS Layer 1 — Knowledge Base

## How to operate this vault

Before any operation, read `./SCHEMA.md`. It defines:
- The directory structure you must respect (`raw/`, `wiki/`, `output/`)
- What kind of content goes in each wiki subdirectory
- The rules you must follow when reading, writing, and maintaining pages
- The bit.ly slug convention (Section 5) and how to expand inline URL references
- The archiving workflow (Section 3.3) and what `wiki/books/_archived/` means

If SCHEMA.md does not exist at the vault root, stop and tell the user. Suggest they run `/kos`.

## Five skills available

Use these skills for all vault operations. Do not freelance outside them.

| Skill | When to use |
|-------|-------------|
| `/kos` | Set up a new vault (do not run against an existing vault) |
| `/kos-ingest` | Process new raw sources into wiki pages |
| `/kos-query` | Answer questions from wiki content |
| `/kos-lint` | Health-check the vault against SCHEMA.md |
| `/kos-archive` | Archive a completed memo book to a Layer 3 envelope |

## Three rules that override everything else

1. **`raw/` is immutable.** Never write to, rename, move, or delete anything under `raw/`. Ever.
2. **Do not fabricate during query.** Answer only from wiki content. When the wiki doesn't have an answer, say so explicitly. Do not fall back on training data.
3. **SCHEMA.md wins.** If anything in a skill's instructions conflicts with SCHEMA.md, follow SCHEMA.md and flag the conflict.

## Memo book conventions

This vault uses typed Field Notes memo books. Each maps 1:1 to a folder under `raw/`:

| Prefix | Type | Purpose |
|--------|------|---------|
| `FL-vol-XXX` | Field Log | Daily log — what the user is doing, what's happening |
| `FR-vol-XXX` | Field Research | Catchall — research, todos, scratch, anything else |
| `FS-vol-XXX` | Field Study | Dedicated subject — created in Phase II when a subject earns its own book |

All memo book folders match `^F[LRS]-vol-\d{3}$`. Each has a corresponding page in `wiki/books/` (or `wiki/books/_archived/` if archived).
