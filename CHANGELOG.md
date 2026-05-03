# Changelog

## v1.0.0-rc.1 (2026-05-02)

- **➕:** `/kos-archive` — archive completed Field Notes memo books to Layer 3 envelopes
- **➕:** `/kos-unarchive` added to v1.x roadmap (deferred — design after real archive usage)
- **➕:** Four agent-config templates (Claude Code, Codex, Cursor, Gemini CLI)
- **➕:** `wiki/books/_archived/` convention for visual organization of archived books
- **➕:** `archived-on:` and `envelope-number:` frontmatter fields for archived books
- **⬆️:** REQUIREMENTS.md — five operations, archiving workflow section, Layer 3 row updated
- **⬆️:** README.md — five skills table, ongoing workflow section, directory tree updated
- **⬆️:** CI — explicit skill enumeration check, spellcheck scope expanded to `tests/`
- **⬆️:** `ci-dev.yml` — mirrored skill enumeration check, gate job added, emojis added

## v0.5.0b (2026-05-01)

- **➕:** `/kos-lint` — health-check vault against SCHEMA.md (eight structured checks)
- **➕:** `/kos-query` — wiki-only answers with wikilink citations; do-not-fabricate enforcement
- **➕:** `wiki/questions/` directory — open questions extracted from raw sources during ingest
- **➕:** `wiki/books/` directory — one page per Field Notes memo book
- **➕:** FL/FR/FS memo book prefix conventions (Field Log, Field Research, Field Study)
- **➕:** Inline bit.ly slug convention — `<slug>` expands to `https://bit.ly/<slug>` on ingest
- **➕:** Schema versioning (`schema-version:` field in SCHEMA.md YAML header)
- **➕:** `docs/REQUIREMENTS.md` — full blueprint document
- **⬆️:** `templates/SCHEMA.md` — six wiki directories, book taxonomy, slug rules, archiving workflow
- **⬆️:** `skills/kos/scripts/onboarding.sh` — all six directories scaffolded, vault-existence check
- **♻️:** Deprecated `skills/kos/references/wiki-schema.md` — replaced by `templates/SCHEMA.md`

## v0.4.0b (2026-04-30)

- **➕:** `/kos-ingest` — processes raw sources into wiki pages across six directories
- **➕:** `wiki/sources/`, `wiki/entities/`, `wiki/concepts/`, `wiki/synthesis/` directories
- **➕:** `output/` directory for generated reports and artifacts
- **➕:** `wiki/index.md` — master catalog updated on every ingest
- **➕:** `wiki/log.md` — append-only chronological operation record
- **➕:** Discussion mode and quick mode for batch ingest sessions

## v0.3.0b (2026-04-29)

- **➕:** `/kos` — onboarding wizard with vault scaffolding and agent config generation
- **➕:** `templates/SCHEMA.md` — canonical schema installed into every new vault
- **➕:** Agent config generation (CLAUDE.md / AGENTS.md / .cursor/rules/kos.mdc / GEMINI.md)
- **➕:** `scripts/onboarding.sh` — directory scaffolding and CLI tool verification
- **➕:** `skills/kos/references/tooling.md` — CLI tool reference (summarize, qmd, agent-browser)
- **➕:** Vault-existence check — wizard refuses to overwrite an existing vault

## v0.2.0b (2026-04-28)

- **➕:** README.md
- **➕:** CI pipeline — five structural test scripts, spellcheck via `typos`, PR gate
- **➕:** `.github/workflows/ci-main.yml` — production gate (hard fail on all checks)
- **➕:** `.github/workflows/ci-dev.yml` — dev gate (tests hard fail; spellcheck advisory)
- **➕:** `skills/kos/references/agent-configs/` directory scaffolded

## v0.1.0b (2026-04-26)

- **➕:** Initial fork from [NicholasSpisak/second-brain](https://github.com/NicholasSpisak/second-brain)
- **➕:** Renamed commands from `second-brain` to `kos` (`/kos`, `/kos-ingest`, `/kos-query`, `/kos-lint`)
- **➕:** Renamed skill directories to `skills/kos/`, `skills/kos-ingest/`, `skills/kos-query/`, `skills/kos-lint/`
- **♻️:** Reoriented from generic second-brain pattern to Kodex OS Layer 1 spec
- **♻️:** README.md — KOS identity, Kodex OS layer model, FL/FR/FS book conventions

# Glossary

**ADDED** = ➕ **|**
**REMOVED** = ❌ **|**
**FIXED** = 🛠️ **|**
**BUG** = 🐞 **|**
**IMPROVED** = 🚀 **|**
**CHANGED** = ♻️ **|**
**SECURITY** = 🛡️ **|**
**DEPRECIATED** = ⚠️ **|**
**UPDATED** = ⬆️
