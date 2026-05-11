---
name: kos
description: Use this skill when the user wants to set up a new Kodex OS Layer 1 vault (the LLM Wiki layer) from scratch. Triggers include phrases like "set up kos", "create a new kos vault", "initialize my Kodex Wiki", or any first-time setup request. This skill walks the user through naming the vault, choosing a location, scaffolding the directory structure (raw/ with FL/FR/FS memo book conventions, wiki/ with all six subdirectories, output/), installing SCHEMA.md, and wiring up their AI agent. Do not use this skill if a vault already exists — use kos-ingest, kos-query, or kos-lint instead. Do not use for Layer 0 (Field Notes), Layer 2 (Notion), Layer 3 (Archive), or Layer 4 (Trello) setup.
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
---

# KOS — Onboarding Wizard

Set up a new KOS vault: an Obsidian-compatible knowledge base implementing Kodex OS Layer 1. The LLM acts as librarian — reading raw sources, compiling them into a structured interlinked wiki, and maintaining it over time.

## Wizard Flow

Guide the user through these 5 steps. Ask ONE question at a time. Each step has a sensible default — the user can accept it or provide their own value.

### Step 1: Vault Name

Ask:
> "What would you like to name your knowledge base? This will be the folder name."
> Default: `kos-vault`

Accept any user-provided name. Validate: lowercase letters, digits, and hyphens only (kebab-case, per SCHEMA.md Section 6.1). If the user provides a name with spaces or capitals, suggest the kebab-case equivalent and confirm.

### Step 2: Vault Location

Ask:
> "Where should I create it? Give me a path, or I'll use the default."
> Default: `~/Documents/`

Accept any absolute or relative path. Resolve `~` to the user's home directory. The final vault path is `{location}/{vault-name}/`.

**Before proceeding:** check whether the resolved path already exists. If it does AND it contains a `SCHEMA.md` at its root, stop and tell the user:

> "There's already a KOS vault at this path. I won't overwrite it. If you want to start fresh, delete or move the existing folder first. If you want to work with the existing vault, use `/kos-ingest`, `/kos-query`, or `/kos-lint`."

Do NOT proceed with scaffolding if a vault is detected.

### Step 3: Domain Description

Ask:
> "In one sentence, what is this vault for? This helps configure your AI agent."
> Default: `Personal knowledge management and research archive system`

Accept any free-text answer. This value fills `{{DOMAIN_DESCRIPTION}}` in the agent config templates and the setup log entry.

### Step 4: Agent Config

Auto-detect which agent is running this skill:

| Detected via | Agent |
|---|---|
| Skill is being run by Claude Code | Claude Code |
| Environment indicates Codex | Codex |
| `.cursor/` exists in working directory | Cursor |
| `GEMINI.md` convention is in use | Gemini CLI |
| Otherwise | Ask the user |

State it clearly:
> "I'm running in **[Agent Name]**, so I'll generate a **[config file]** for this vault."

Then ask:
> "Do you use any other AI agents you'd like config files for? Options: Claude Code, Codex, Cursor, Gemini CLI — or skip."

Skip the agent that was auto-detected. Generate configs for all selected agents.

### Step 4.5: Existing or Fresh?

Ask:
> "Are you starting a fresh KOS vault, or do you already have an archive of Field Notes books with their own volume numbers?"
> 1. **Fresh** — I'm starting from scratch today
> 2. **Archived** — I have existing books with established volume numbers

If **Fresh**: the scaffolding script will pre-create `raw/FL-vol-001/` and `raw/FR-vol-001/` so the user has somewhere obvious to drop their first transcribed page. Skip `FS-vol-001/` since Field Study books only appear during Phase II — Data Extraction when a subject earns its own book.

If **Archived**: the scaffolding script will not pre-create any volume folders. The user already knows their volume numbers (e.g., they may be starting at `FL-vol-047`) and will create folders matching their existing books.

Pass the answer to `onboarding.sh` as the `STARTER_MODE` environment variable: `STARTER_MODE=fresh bash onboarding.sh <vault-path>` or `STARTER_MODE=archived bash onboarding.sh <vault-path>`.

### Step 5: Optional CLI Tools

Ask:
> "These tools extend what the LLM can do with your vault. All optional but recommended:"
>
> 1. **summarize** — summarize links, files, and media from the CLI
> 2. **agent-browser** — browser automation for web research
>
> "Install all, pick specific ones (e.g. '1 and 2'), or skip?"

Note: `qmd` (local markdown search) has been removed from this list — the npm package `@tobilu/qmd` is currently unreliable. It may be re-added in a future release once the package is stable. In the meantime, `grep` or `ripgrep` can serve the same purpose.

---

## Post-Wizard: Scaffold the Vault

After collecting all answers, execute these steps in order. If any step fails, stop and report — do NOT continue with a half-built vault.

### 1. Create directory structure and stub files

Run the onboarding script with the full vault path:

```bash
bash <skill-directory>/scripts/onboarding.sh <vault-path>
```

This creates:
- `raw/`, `raw/Field-Logs/`, `raw/Field-Research/`, `raw/Field-Studies/`, and `raw/assets/`
- `wiki/sources/`, `wiki/books/`, `wiki/entities/`, `wiki/concepts/`, `wiki/synthesis/`, `wiki/questions/`
- `output/`
- Stub `wiki/index.md` with all six section headers
- Stub `wiki/log.md`

Verify the script exits with status 0 before proceeding.

### 2. SCHEMA.md is installed by the onboarding script

`onboarding.sh` copies `SCHEMA.md` from the bundled template at `templates/SCHEMA.md` in the installed skill package and places it at `<vault-path>/SCHEMA.md`. No network call is made — the file is local. No action required from the wizard — this happens automatically as part of Step 1.

If the script reports that the bundled template is missing, stop and surface the error to the user. Do NOT continue building the vault without SCHEMA.md — it's the contract that all other skills depend on.

### 3. Generate agent config file(s)

For each selected agent, read the corresponding template from `<skill-directory>/references/agent-configs/` and write the rendered output:

| Agent | Template | Output File | Output Location |
|---|---|---|---|
| Claude Code | `claude-code.md` | `CLAUDE.md` | Vault root |
| Codex | `codex.md` | `AGENTS.md` | Vault root |
| Cursor | `cursor.md` | `kos.mdc` | `<vault>/.cursor/rules/` |
| Gemini CLI | `gemini.md` | `GEMINI.md` | Vault root |

Replace these placeholders in each template:

- `{{VAULT_NAME}}` → vault name from Step 1
- `{{DOMAIN_DESCRIPTION}}` → one-line description from Step 3
- `{{SCHEMA_PATH}}` → `./SCHEMA.md` (relative path from vault root)

The agent config templates must NOT embed SCHEMA.md's contents. They should reference it: "Read `./SCHEMA.md` for the full schema and operation rules." This keeps SCHEMA.md as the single source of truth — if the user edits SCHEMA.md, the agent picks up the change without the config drifting.

For Cursor specifically: ensure `<vault>/.cursor/rules/` exists before writing.

### 4. Append the setup entry to `wiki/log.md`

> Read `./references/ingest-log-examples.md` for the log entry format before writing.

The setup entry must include: operation (`setup`), vault name, schema version, agent configs generated, and the domain description as a note.

### 5. Install CLI tools (if selected)

For each tool the user selected in Step 5:

- summarize: `npm i -g @steipete/summarize`
- agent-browser: `npm i -g agent-browser && agent-browser install`

After each install, verify with `<tool> --version`. Report success or failure for each — installation failures should not abort the wizard, since the tools are optional.

### 5.5 Verify vault integrity before saving memory

Before printing the summary or saving any memory entry, confirm the vault is intact:

```bash
test -f <vault-path>/SCHEMA.md && echo "OK" || echo "MISSING"
```

If SCHEMA.md is missing: stop, report the failure, do NOT write a memory entry, do NOT print a success summary. Tell the user to re-run `/kos`.

Only proceed to Step 6 and save the memory entry after this check passes.

### 6. Print summary and next steps

Show the user:

**1. What was created** — the directory tree, SCHEMA.md, and config files.

**2. Required next step** — install the Obsidian Web Clipper:

> Install the Obsidian Web Clipper to easily save web articles into your vault:
> https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf
>
> Configure it to save to: `<vault-path>/raw/`

**3. How to start** — the Field Notes-aware workflow:

> Open the vault folder in Obsidian (File → Open Vault as Folder).
>
> When you're ready to add your first sources:
>
> - **Daily log pages** (Field Log) go in `raw/Field-Logs/FL-vol-001/page-001.md`, etc.
> - **Research/catchall pages** (Field Research) go in `raw/Field-Research/FR-vol-001/`
> - **Subject study pages** (Field Study) go in `raw/Field-Studies/FS-vol-001/` — Field
>   Study books are dedicated to a single subject (e.g., Stoicism, A.I.). When you run
>   `/kos-ingest` on a Field Study page for the first time, the LLM will ask you for the
>   subject name if it isn't obvious from context. Field Study source pages are living
>   documents — each new page you ingest from the same volume accumulates into one wiki
>   entry rather than creating separate pages per scan.
> - **Web clippings** go in `raw/clippings/` — save them directly using the Obsidian Web Clipper configured to this folder.
> - **Meeting transcripts** go in `raw/meetings/` — Proton Meet transcripts.
>
> Then run `/kos-ingest` and the LLM will process them into your wiki.

---

## Reference Files

These files are bundled with this skill at `<skill-directory>/`:

- `scripts/onboarding.sh` — directory scaffolding and tool checks
- `references/agent-configs/claude-code.md` — CLAUDE.md template
- `references/agent-configs/codex.md` — AGENTS.md template
- `references/agent-configs/cursor.md` — Cursor rules template
- `references/agent-configs/gemini.md` — GEMINI.md template

Note: SCHEMA.md is NOT in this skill's references — it's at the repo root in `templates/SCHEMA.md`. There is one canonical schema, and it lives in `templates/`. The wizard copies it into each new vault during scaffolding (Post-Wizard Step 2).

---

## Next Steps

After setup, the user's workflow is:

1. **Capture** — write in Field Notes memo books (Layer 0)
2. **Transcribe & clip** — scan or transcribe pages into `raw/F[LRS]-vol-XXX/`; clip articles to `raw/`
3. **Ingest** — run `/kos-ingest` to process raw files into wiki pages
4. **Query** — run `/kos-query` to ask questions against the wiki
5. **Lint** — run `/kos-lint` after every ~10 ingests to catch gaps
