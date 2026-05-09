# Changelog

## v1.2.1 (2026-06)

- **⬆️:** `skills/kos-lint/SKILL.md` — default scope changed from full to quick audit; quick audit now runs Checks 1, 2, 3, 7 only; Check 2b (orphaned companion scans) and Check 8 (orphan pages) moved to full and deep audit only; Check 6 rewritten to grep `wiki/log.md` instead of reading it in full; grep-before-read and fresh-session-per-operation convention rules added
- **⬆️:** `skills/kos/references/agent-configs/CLAUDE.md` — session management section added
- **⬆️:** `skills/kos/references/agent-configs/AGENTS.md` — session management section added
- **⬆️:** `skills/kos/references/agent-configs/gemini.md` — session management section added
- **🐞🛠️:** `skills/kos/references/agent-configs/cursor.md` — broken `{{WIKI_SCHEMA}}` placeholder removed (`references/wiki-schema.md` was deprecated in v0.5.0b); `{{DOMAIN_TAGS}}` placeholder removed; template body rewritten to match CLAUDE.md/AGENTS.md/gemini.md pattern; truncated sentence at end of file fixed; session management section added
- **⬆️:** `skills/kos/SKILL.md` — Post-Wizard Step 4 inline log entry block replaced with `> Read ./references/ingest-log-examples.md` directive
- **⬆️:** `references/ingest-log-examples.md` — setup log entry format and example added
- **🛠️:** `docs/REQUIREMENTS.md` — `docs/CAPTURE.md` path reference corrected to `references/CAPTURE.md`
- **⬆️:** `tests/test_structure.sh` — `references/` added to required directories check
- **⬆️:** `tests/test_templates.sh` — required template files check added (`SCHEMA.md`, `frontmatter-templates.md`, `field-notes-formats.md`); required references files check added (`schema-changelog.md`, `ingest-log-examples.md`, `lint-report-example.md`)

## v1.2.0 (2026-06)

- **➕:** `templates/frontmatter-templates.md` — all YAML frontmatter blocks for every wiki page type (source, book, entity, concept, synthesis, question) extracted from `SCHEMA.md`; read on demand by skills when creating or updating wiki pages
- **➕:** `templates/field-notes-formats.md` — Field Log entry format (Section 3.1.1) and Field Study page format (Section 3.1.2) extracted from `SCHEMA.md`; read on demand by skills when ingesting FL or FS sources
- **➕:** `references/schema-changelog.md` — version history extracted from `SCHEMA.md` Section 8; read by `/kos-lint` during schema-version mismatch checks only
- **➕:** `references/log-examples.md` — new shared log entry reference covering all four operation types: ingest (bare, composite, missing companion, silent-add, re-open), query (yes/partial/no), lint, and archive; all five skills point to this file
- **➕:** `references/lint-report-example.md` — full lint report format example extracted from `kos-lint`; read on demand when writing findings reports
- **♻️:** `references/CAPTURE.md` — moved from `docs/`; reclassified as LLM operational reference (defines capture interpretation rules used during ingest)
- **⬆️:** `templates/SCHEMA.md` — now a rules-only document; all YAML frontmatter blocks, format specs, and version history delegated to new `templates/` and `references/` files and replaced with `> Read` directives; critical rules from delegated sections preserved as inline bullet summaries; directory structure diagram updated to include `templates/` and `references/`; token cost ~4,000 → ~2,100 (~47% reduction)
- **⬆️:** `skills/kos-ingest` — all frontmatter and body template blocks replaced with `> Read` directives; composite and Field Study body structures condensed; log entry examples delegated to `references/log-examples.md`; token cost ~4,000 → ~2,400 (~40% reduction)
- **⬆️:** `skills/kos-lint` — prefix → book-type table replaced with `> Read` directive; frontmatter required fields table replaced with `> Read` directive plus inline validation rules; report format and log entry delegated to `references/`; token cost ~2,700 → ~1,900 (~30% reduction)
- **⬆️:** `skills/kos-query` — synthesis frontmatter block replaced with `> Read` directive; query log entry delegated to `references/log-examples.md`; archive lookup added as explicit query classification type; token cost ~1,900 → ~1,550 (~18% reduction)
- **⬆️:** `skills/kos-archive` — log entry delegated to `references/log-examples.md`; token cost ~2,000 → ~1,750 (~13% reduction)

## v1.1.0-rc.1 (2026-05-06)

- **➕:** `docs/CAPTURE.md` — new document covering the full Field Notes scanning
  workflow: Proton Drive built-in scanner, filename suffix conventions, Rclone +
  Proton Drive setup, systemd automation (5-minute sync timer), and troubleshooting
- **➕:** `templates/SCHEMA.md` Section 3.1.1 — Field Log entry format: structured
  header (`[DAY] [TEMP]° [TIME] [DATE M/D/YY]`), one-or-two-entry-per-page rule,
  multi-page entry continuation, `entries:` frontmatter with `date`, `day`, `temp`,
  `time`, `summary` per entry
- **➕:** `templates/SCHEMA.md` Section 3.1.2 — Field Study page format: structured
  knowledge document (not chronological), required skeleton (Origins, Key Figures,
  Core Principles, Open Questions), subject-specific free-form sections, living-document
  accumulation rule (all FS volume pages → one source page), `subject:` frontmatter,
  ingestion timestamp as date of record
- **➕:** `templates/SCHEMA.md` Section 3.1 — scanned PDF filename suffix convention:
  `page-XXX`, `page-XXX-sticky`, `page-XXX-under`, `page-XXX-flip`; merge rule for
  companion sets; orphaned companion detection rule
- **⬆️:** `templates/SCHEMA.md` — Section 3.1 memo book table updated with Entry
  format column; Section 3.2 frontmatter note updated with conditional `entries:`
  (field-log-page) and `subject:` (field-study-page); Section 6.2 ingest rule 2
  updated for Field Log entry extraction and FS living-document behavior; Section 6.4
  orphaned companion scan lint rule added; schema-version bumped to 5
- **⬆️:** `skills/kos-ingest` — scanned PDF suffix detection and capture mode logic;
  companion collection and merge before ingest; orphaned companion warning; Field Log
  entry header extraction added to Reading scanned PDFs section; Field Study structure
  reading rules added; Step 1 date extraction logic split by book type (FL header, FR
  bottom stamp, FS none); Step 4 frontmatter example updated with `capture-mode`,
  `subject:`, and `entries:` fields; composite source page body structure added; Field
  Study living-document body structure added
- **⬆️:** `skills/kos-lint` — Check 1: `.pdf` files in memo book folders included in
  raw sync evaluation; Field Study living-document exception added (individual FS pages
  not flagged if volume source page exists); Check 2b (new): orphaned companion scan
  detection for missing `-sticky`, missing `-under`, and stale incomplete captures;
  Check 5: `wiki/sources/` frontmatter table updated with conditional `entries:` and
  `subject:` fields; `created` immutability check added for field-study-page sources
- **⬆️:** `skills/kos` — Post-Wizard Step 6 next steps updated to explain Field Study
  living-document behavior and subject prompt on first ingest
- **⬆️:** `scripts/onboarding.sh` — capture pipeline tooling check added: verifies
  `rclone` and `fuse3` are installed; reports install instructions if missing
- **⬆️:** `README.md` — Quick Start step 5 updated to reference `docs/CAPTURE.md`;
  Ongoing Workflow daily section updated to reference scanning workflow; directory tree
  updated to include `docs/CAPTURE.md`
- **⬆️:** `tests/test_onboarding.sh` — Test 3b added: verifies capture pipeline
  tooling check runs without error

## v1.0.0-rc.3 (2026-05-05)

- **🐞🛠️:** `skills/kos` — wizard had no step to collect `{{DOMAIN_DESCRIPTION}}`; agent was silently filling it with a generic default. Step 3 now explicitly asks the user for a one-sentence vault description before generating agent config files
- **🐞🛠️:** `skills/kos` — `obsidian://open?vault=` URI fails on unregistered vaults; replaced with `obsidian://open?path=` which opens by absolute path and registers the vault automatically. Cross-platform launcher detection added for macOS, Linux, and Windows (WSL)
- **🐞🛠️:** `scripts/onboarding.sh` — SCHEMA.md was never actually copied during onboarding; the script only printed it as an instruction for the wizard to handle manually. SCHEMA.md is now downloaded directly from GitHub at vault creation time, eliminating all path resolution logic and working for all install methods (`npx skills add`, local clone, etc.)
- **🐞🛠️:** `scripts/onboarding.sh` — SCHEMA.md download is skipped if the file already exists, making the script safe to re-run without overwriting a user-edited schema
- **🐞🛠️:** `tests/test_onboarding.sh` — Test 1 was asserting `wiki/_archived` but the script creates `wiki/books/_archived`; corrected to match actual directory structure
- **🐞🛠️:** `tests/test_onboarding.sh` — Test 4 mock vault was missing `raw/Field-Logs/` and `raw/Field-Research/` directories; fixed to match the structure a real first-run vault produces
- **🛠️:** `tests/test_onboarding.sh` — Test 1 now asserts `SCHEMA.md` exists in the vault root after onboarding, verifying the GitHub download step completed successfully
- **🛠️:** `tests/test_onboarding.sh` — Test 4 now pre-places `SCHEMA.md` in the second vault before re-running the script, correctly isolating the idempotency check for wiki files from the SCHEMA.md existence guard; also asserts SCHEMA.md is not overwritten on re-run
- **🛠️:** `scripts/onboarding.sh` — `check_tool` now detects binaries installed to `~/.npm-global/bin/` that are absent from the active PATH, and prints a specific shell config fix instead of a misleading "missing" status
- **❌:** `scripts/onboarding.sh` — `qmd` removed from tool check; `@tobilu/qmd` is currently unavailable or broken on npm. `grep` or `ripgrep` recommended as alternatives. May be re-added in a future release
- **❌:** `skills/kos` — `qmd` removed from Step 5 optional tool list and Post-Wizard Step 5 install instructions
- **❌:** `skills/kos` — misplaced duplicate "How to start" block removed from between Steps 2 and 4; content already exists in Post-Wizard Step 6
- **❌:** `skills/kos` — Post-Wizard "Next steps" echo reduced from 3 items to 2; SCHEMA.md install is now handled automatically by the script and no longer needs to be listed as a manual step

## v1.0.0-rc.2 (2026-05-04)

- **♻️:** `raw/` reorganized — FL/FR/FS volumes now live under typed subdirectories (`raw/Field-Logs/`, `raw/Field-Research/`, `raw/Field-Studies/`) instead of directly under `raw/`
- **🐞🛠️:** `scripts/onboarding.sh` — `wiki/_archived/` was being created at vault root level instead of `wiki/books/_archived/`; corrected
- **⬆️:** `templates/SCHEMA.md` — Section 2 directory tree, Section 3.1 folder pattern and path references, Section 3.2 source filename derivation example, Section 3.3 book page creation rule, Section 6.4 lint rule updated to reflect typed subdirectories; schema-version bumped to 2
- **⬆️:** `CLAUDE.md` — memo book table and folder pattern sentence updated
- **⬆️:** `AGENTS.md` — memo book folder paths updated
- **⬆️:** `GEMINI.md` — memo book table description and folder paths updated
- **⬆️:** `README.md` — Quick Start mkdir example, directory tree, and Ongoing Workflow daily section updated
- **⬆️:** `docs/REQUIREMENTS.md` — THE PATTERN, WHAT YOU NEED, and SCHEMA OWNERSHIP sections updated
- **⬆️:** `skills/kos` — Step 3 mkdir examples, Post-Wizard Step 1 directory list, and Post-Wizard Step 6 path references updated
- **⬆️:** `skills/kos-ingest` — source filename derivation example, memo book source paths, frontmatter raw-path example, book page creation condition, and log entry example updated
- **⬆️:** `skills/kos-lint` — Check 2 bash command and lint report/log examples updated
- **⬆️:** `skills/kos-archive` — Pre-Archive Validation sources sync check updated
- **⬆️:** `scripts/onboarding.sh` — typed subdirectories added to DIRS array, fresh-mode volume folder paths updated, `wiki/_archived/` corrected to `wiki/books/_archived/`
- **⬆️:** `tests/test_lint_rules.sh` — mock vault setup updated to create typed subdirectories; Rule 1 expanded to check `raw/Field-Logs/`, `raw/Field-Research/`, `raw/Field-Studies/`

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
