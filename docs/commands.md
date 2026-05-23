# KOS Commands Reference

Kodex OS (KOS) is a skills-based system for managing a personal knowledge vault using an AI agent as your librarian. You invoke each command as a **skill** by typing its name (e.g., `/kos`, `/kos-ingest`).

---

## `/kos` — Set Up a New Vault

**Use when:** You're starting a brand-new KOS vault for the first time.

Walks you through a five-step guided wizard to create the complete directory structure, install the schema, and wire up your AI agent config. Do **not** run this if a vault already exists — use the other commands instead.

### Wizard Steps

| Step | What You're Asked | Default |
|------|-------------------|---------|
| 1 | Vault name (folder name) | `kos-vault` |
| 2 | Location to create the vault | `~/Documents/` |
| 3 | One-sentence description of what the vault is for | `Personal knowledge management and research archive system` |
| 4 | Which AI agent(s) to generate config files for | Auto-detected |
| 4.5 | Fresh start vs. existing archive with established volume numbers | Fresh |
| 5 | Optional CLI tools to install (`summarize`, `agent-browser`, `md-to-pdf`, `ripgrep`) | All recommended |

### What Gets Created

```text
<vault-name>/
├── SCHEMA.md               # The contract — all skills read this before operating
├── CLAUDE.md               # Agent config (filename varies by agent)
├── raw/                    # Your inbox — drop sources here; never modified by KOS
│   ├── Field-Logs/         # Field Log memo books
│   │   └── FL-vol-001/     # Pre-created in fresh mode; add your own in archived mode
│   ├── Field-Research/     # Field Research memo books
│   │   └── FR-vol-001/     # Pre-created in fresh mode
│   ├── Field-Studies/      # Field Study memo books — one subject per volume
│   ├── assets/             # Images and binary attachments referenced by raw pages
│   ├── clippings/          # Web articles saved via Obsidian Web Clipper
│   └── transcripts/        # Audio and video transcripts
│       ├── meetings/       # Proton Meet or similar meeting recordings
│       ├── youtube/        # YouTube video transcripts
│       └── podcasts/       # Podcast episode transcripts
├── wiki/                   # LLM-maintained — do not edit by hand
│   ├── index.md            # Master catalog of all wiki pages
│   ├── log.md              # Chronological record of every KOS operation
│   ├── sources/            # One summary page per ingested source
│   ├── books/              # One page per active memo book
│   │   └── _archived/      # Completed books archived to Layer 3 envelopes
│   ├── entities/           # People, organizations, products, tools, places
│   ├── concepts/           # Ideas, frameworks, theories, patterns
│   ├── synthesis/          # Cross-source comparisons, analyses, and themes
│   └── questions/          # Open questions extracted from raw sources
└── output/                 # Reports and generated artifacts
```

### After Setup

The recommended workflow:

1. Write in physical Field Notes memo books (Layer 0)
2. Transcribe or scan pages into the appropriate `raw/` subfolder
3. Clip web articles using the Obsidian Web Clipper into `raw/clippings/`
4. Run `/kos-ingest` to process sources into the wiki
5. Run `/kos-query` to ask questions against the wiki
6. Run `/kos-lint` periodically to keep the vault healthy

---

## `/kos-ingest` — Process Raw Sources into the Wiki

**Use when:** You have new content in `raw/` that needs to be turned into structured wiki pages.

Reads source files from `raw/`, synthesizes them into interlinked wiki pages in `wiki/`, creates cross-references and wikilinks, expands bit.ly URL slugs, and updates `wiki/index.md` and `wiki/log.md`. Never modifies anything in `raw/` — that layer is immutable.

### Input: What You Can Ingest

| Source Type | Location | Notes |
|-------------|----------|-------|
| Field Log pages | `raw/Field-Logs/FL-vol-XXX/` | Daily log entries; one or two entries per page |
| Field Research pages | `raw/Field-Research/FR-vol-XXX/` | Research and catchall pages |
| Field Study pages | `raw/Field-Studies/FS-vol-XXX/` | Single-subject knowledge docs; accumulate into one wiki page per volume |
| Web clippings | `raw/clippings/` | Saved via Obsidian Web Clipper |
| Meeting transcripts | `raw/transcripts/meetings/` | From Proton Meet or similar |
| YouTube transcripts | `raw/transcripts/youtube/` | Generated with yt-dlp or similar |
| Podcast transcripts | `raw/transcripts/podcasts/` | Generated with Whisper or similar |
| Papers and articles | `raw/` subdirectories | Any `.md` file in `raw/` |

### PDF Capture Modes (Scanned Field Notes)

When you scan Field Notes pages as PDFs, the filename suffix tells KOS how to handle them:

| Filename Pattern | Mode | Behavior |
|-----------------|------|----------|
| `page-007.pdf` | Bare page | Ingested immediately as a single source |
| `page-007-sticky.pdf` | Composite (front) | Waits to collect companion scans before ingesting |
| `page-007-under.pdf` | Companion | Page text under a peeled-back sticky — **not ingested alone** |
| `page-007-flip.pdf` | Companion | Back face of the sticky — **not ingested alone** |

When a `-sticky` scan is detected, KOS automatically collects all companion files (`-under`, `-flip`) and merges them into one composite source before writing anything to the wiki. If a companion is missing, it will warn you and ask whether to continue or wait.

### Ingest Modes

| Mode | When to Use |
|------|-------------|
| **Discussion mode** (default for first source) | KOS shares 3–5 key takeaways and asks for confirmation before writing each page. Use when you want to curate. |
| **Quick mode** | Ingests everything without checking in. Use for batches or when you just want it done. |

### What Gets Created or Updated

Each source typically touches 5–15 wiki pages:

- `wiki/sources/<path>-<file>.md` — factual summary of the source
- `wiki/books/<volume>.md` — book page updated with a link to the new source
- `wiki/entities/<name>.md` — one per person, organization, product, tool, or place mentioned
- `wiki/concepts/<name>.md` — one per idea, framework, theory, or pattern
- `wiki/questions/<question>.md` — extracted from `?` questions, `TODO:`, `look into:`, etc.
- `wiki/index.md` — updated with new entries
- `wiki/log.md` — operation appended

---

## `/kos-query` — Search and Answer from the Wiki

**Use when:** You want to ask a question and get an answer sourced from your own captured knowledge.

Searches across all wiki directories, follows wikilinks, and synthesizes a cited answer. **Will not fabricate** — if the wiki doesn't contain the answer, it says so explicitly rather than drawing on general knowledge.

### Query Types

| Query Type | Example | How It's Answered |
|------------|---------|-------------------|
| Factual lookup | "What does my wiki say about Zettelkasten?" | Direct answer with citations |
| Time-scoped | "What was I working on in March?" | Chronological list or narrative |
| Status-scoped | "What questions are still open?" | Bulleted list grouped by category |
| Comparison | "How do X and Y differ in my notes?" | Table or structured side-by-side |
| Exploration | "What have I been thinking about lately?" | Narrative connecting linked concepts |
| Source-tracing | "Where did I read about X?" | List of sources with one-line context |
| Archive lookup | "What's in envelope 7?" | Searches `wiki/books/_archived/` by envelope number |

### Search Strategy (in order)

1. Reads `wiki/index.md` for fast structured signal
2. Uses `qmd` for semantic search (if installed)
3. Falls back to `grep` for keyword matching
4. Reads up to ~20 directly relevant pages before asking you whether to keep searching
5. Follows `[[wikilinks]]` one hop only — does not recurse, which would explode in a well-linked wiki
6. Falls back to reading raw sources only as a last resort

### Saving Answers as Synthesis Pages

If an answer represents new analysis that isn't already captured in the wiki, KOS will offer to save it as a `wiki/synthesis/<topic>.md` page and cross-link it from the cited sources.

### All Queries Are Logged

Every query appends an entry to `wiki/log.md` recording the question, pages consulted, and whether it was answered from the wiki (`yes`, `partial`, or `no`). This helps identify knowledge gaps over time.

---

## `/kos-lint` — Health-Check the Wiki

**Use when:** You want to audit the wiki for structural problems — broken links, missing pages, invalid frontmatter, schema issues.

Validates the vault against `SCHEMA.md`, reports findings by severity, and offers to fix each issue with your confirmation. Never makes changes without asking first.

### Audit Scopes

| Scope | What It Runs | When to Use |
|-------|-------------|-------------|
| **Quick** (default) | Checks 1, 2, 3, 7 — structural integrity only | After ingests; the default when you just type `/kos-lint` |
| **Full** | All checks except 9 and 10 | Explicit request — "full lint" or "audit everything" |
| **Scoped** | Limited to a directory, time window, or specific book | Targeted investigation |
| **Deep** | Everything including contradiction and stale-claim checks | Only on explicit request — slow, produces false positives |

### The 10 Checks

| # | Check | Severity | Included In |
|---|-------|----------|-------------|
| 1 | Every `raw/` file has a corresponding `wiki/sources/` page | Error | Quick+ |
| 2 | Every memo book folder has a `wiki/books/` entry; archived metadata is valid | Error | Quick+ |
| 2b | Orphaned companion scans (`-under`/`-flip` with no `-sticky`) | Warning | Full+ |
| 3 | All `[[wikilinks]]` resolve to real pages | Error | Quick+ |
| 4 | `wiki/index.md` matches reality — every page listed, no dead entries, books in the right section | Error/Warning | Quick+ |
| 5 | Frontmatter is valid on every wiki page — required fields, correct types, valid dates | Error | Quick+ |
| 6 | Unresolved bit.ly slugs flagged in the log | Warning | Quick+ |
| 7 | Vault's `schema-version` matches the installed KOS schema | Error/Info | Quick+ |
| 8 | Orphan pages — entities, concepts, synthesis, and questions with no incoming wikilinks | Warning | Full+ |
| 9 | Duplicate entity pages — same real-world thing with multiple pages | Warning | Deep only |
| 10 | Stale claims and contradictions between source summaries | Info | Deep only |

### How Fixes Work

After the report, KOS asks about each finding individually — **not in batch**. You can:

- **yes** — apply this specific fix
- **no** — skip this finding
- **skip all errors** — stop offering fixes and finish the report

For ambiguous fixes (e.g., orphan pages: link or delete? duplicate entities: which page survives?), KOS presents the options and waits for your choice.

### When to Lint

- After every ~10 ingests
- Monthly at minimum
- Before major query sessions
- Before archiving a book to Layer 3

---

## `/kos-archive` — Archive a Completed Memo Book

**Use when:** A physical Field Notes memo book is full and being placed into a Layer 3 archive envelope.

Validates the book's wiki representation is complete, updates its status metadata, optionally moves the page to `wiki/books/_archived/`, and updates the index and log. Ties the digital wiki to the physical archive envelope number so you can find the book later.

### What You're Asked

| Parameter | Description | Default |
|-----------|-------------|---------|
| Volume ID | Which book to archive (e.g., `FL-vol-003`) | Shown a list of active books to choose from |
| Envelope number | Which physical archive envelope it goes into | Auto-increments from the highest existing envelope |
| Archive date | When the book was physically archived | Today |

### Pre-Archive Validation (Mandatory)

Before anything is changed, KOS runs a scoped lint on the book:

- All raw pages for this volume must have wiki source pages — **Error**, blocks archiving
- All wikilinks within the book's pages must resolve — **Error**, blocks archiving
- Frontmatter on the book page must be valid — **Error**, blocks archiving
- Unresolved bit.ly slugs in source pages — **Warning**, asks to fix or continue

If errors are found, KOS stops and tells you to run `/kos-ingest` or fix the wiki before re-running. You can override errors with an explicit instruction, but it won't happen accidentally.

### What Gets Changed

1. **Book page frontmatter** — sets `status: archived`, `archived-on`, `envelope-number`, and `updated`
2. **Page location** — optionally moves `wiki/books/<volume>.md` → `wiki/books/_archived/<volume>.md` (wikilinks resolve either way; this is purely visual organization)
3. **`wiki/index.md`** — entry moves from `## Books` to `## Archived Books` with the envelope number
4. **`wiki/log.md`** — operation appended

### What Doesn't Change

- `raw/` — never touched; raw transcriptions stay immutable forever
- `wiki/sources/` pages — all source pages and their `raw-path:` pointers are preserved unchanged
- The book remains fully searchable via `/kos-query` — archive lookup by envelope number or date

### When to Archive

- Physical book is full (most common)
- End of year or calendar boundary
- Bulk-archiving an existing physical collection when first setting up KOS

---

## Command Quick Reference

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/kos` | Set up a new vault from scratch | First time only |
| `/kos-ingest` | Turn raw sources into wiki pages | Whenever you have new content in `raw/` |
| `/kos-query` | Ask questions against your wiki | Whenever you want to retrieve captured knowledge |
| `/kos-lint` | Health-check the vault structure | After ~10 ingests, monthly, before archiving |
| `/kos-archive` | Archive a completed memo book | When a physical book is full |
