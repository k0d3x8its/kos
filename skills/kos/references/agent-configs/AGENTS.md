# {{VAULT_NAME}} — Agent Instructions

This file configures AI agents operating on this KOS vault.
KOS is the Layer 1 toolkit for Kodex OS. Full documentation: https://github.com/k0d3x8its/kos

## Vault identity

- **Name:** {{VAULT_NAME}}
- **Purpose:** {{DOMAIN_DESCRIPTION}}
- **Schema:** `./SCHEMA.md`
- **Layer:** Kodex OS Layer 1 — Knowledge Base

## First step for every operation

Read `./SCHEMA.md`. It is the contract. It defines the directory structure, page format, operation rules, and all conventions (including the bit.ly slug expansion in Section 5 and the archiving workflow in Section 3.3). Do not proceed with any vault operation without reading it first.

If SCHEMA.md is missing, stop. Tell the user the vault is not initialized and suggest running `/kos`.

## Available skills

This vault is operated through five KOS Agent Skills:

- `/kos` — onboarding wizard (do not run on an existing vault)
- `/kos-ingest` — process raw sources into wiki pages
- `/kos-query` — answer questions from wiki content
- `/kos-lint` — health-check the vault against SCHEMA.md
- `/kos-archive` — archive a completed memo book to a Layer 3 envelope

All vault operations go through one of these skills. Do not operate outside them.

## Non-negotiable rules

**Rule 1 — raw/ is immutable.**
Never write to, rename, move, or delete anything under `raw/`. This includes moving memo book folders when archiving. Raw transcriptions stay in place permanently.

**Rule 2 — No fabrication during query.**
During `/kos-query`, answer only from content in the wiki. If the wiki doesn't contain the answer, say so. Do not use training data to fill gaps.

**Rule 3 — SCHEMA.md is the authority.**
If anything in a skill's instructions contradicts SCHEMA.md, follow SCHEMA.md. Flag the contradiction to the user.

## Memo book conventions

Memo books are physical Field Notes notebooks with a 1:1 mapping to `raw/` folders:

- `raw/FL-vol-XXX/` — Field Log (daily log)
- `raw/FR-vol-XXX/` — Field Research (catchall)
- `raw/FS-vol-XXX/` — Field Study (dedicated subject, created in Phase II)

Each active book has a corresponding `wiki/books/<volume>.md`. Archived books have `wiki/books/_archived/<volume>.md` with `status: archived`, `archived-on:`, and `envelope-number:` in frontmatter.
