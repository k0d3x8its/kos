# Cursor Agent Config Template

This template generates a `.cursor/rules/kos.mdc` file in the vault.

## Output File
- **Filename:** `kos.mdc`
- **Location:** `.cursor/rules/` (relative to vault root)

## Template

The onboarding skill should create the `.cursor/rules/` directory if it doesn't exist, then generate a file with this structure, replacing all `{{placeholder}}` values with the user's wizard answers:

---

    ---
    description: Knowledge base librarian rules for {{VAULT_NAME}}
    globs:
    alwaysApply: true
    ---

    # {{VAULT_NAME}}

    > {{DOMAIN_DESCRIPTION}}

    ## How to operate this vault

    Before any operation, read `./SCHEMA.md` at the vault root. It is the authoritative
    contract — directory structure, page format, operation rules, and all conventions
    including the bit.ly slug convention (Section 5) and the archiving workflow (Section 3.3).

    If SCHEMA.md does not exist, stop and tell the user the vault is not initialized.
    Suggest running `/kos`.

    ## Skills

    Use these skills for all vault operations:

    - `/kos` — onboarding wizard (do not run on an existing vault)
    - `/kos-ingest` — process raw sources into wiki pages
    - `/kos-query` — answer questions from wiki content
    - `/kos-lint` — health-check the vault against SCHEMA.md
    - `/kos-archive` — archive a completed memo book to a Layer 3 envelope

    ## Three rules that override everything else

    1. **`raw/` is immutable.** Never write to, rename, move, or delete anything under `raw/`.
    2. **No fabrication during query.** Answer only from wiki content. When the wiki doesn't
       have an answer, say so. Do not use training data to fill gaps.
    3. **SCHEMA.md wins.** If anything in a skill's instructions conflicts with SCHEMA.md,
       follow SCHEMA.md and flag the conflict.

    ## Memo book conventions

    | Prefix | Type | Location |
    |--------|------|----------|
    | `FL-vol-XXX` | Field Log | `raw/Field-Logs/` |
    | `FR-vol-XXX` | Field Research | `raw/Field-Research/` |
    | `FS-vol-XXX` | Field Study | `raw/Field-Studies/` |

    ## Session management

    Start a **new Cursor session** for each KOS operation. Do NOT resume previous sessions —
    carried context inflates token cost and risks hitting limits mid-operation.

    One session. One operation. Done.

## Placeholder Definitions

- `{{VAULT_NAME}}` — the vault name from wizard step 1
- `{{DOMAIN_DESCRIPTION}}` — the domain/topic from wizard step 3, formatted as a one-line description
