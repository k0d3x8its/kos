# KOS — Blueprint

> This is the blueprint document for KOS: the Layer 1 toolkit for [Kodex OS](https://github.com/k0d3x8its/kodex-os). It describes the pattern, the requirements, and how the implementation maps to the Kodex OS architecture. You can use this as a reference to build your own Layer 1 implementation, or install this one via `npx skills add k0d3x8its/kos` (see [README.md](https://github.com/k0d3x8its/kos/blob/main/README.md)).

## ORIGIN

KOS is a fork of [NicholasSpisak/second-brain](https://github.com/NicholasSpisak/second-brain), itself an implementation of the LLM Wiki pattern Andrej Karpathy described in late 2025: dump raw source material into a folder, let an LLM compile it into a structured wiki, browse the whole thing in Obsidian.

- Karpathy's original thread: <https://x.com/karpathy/status/2039805659525644595>
- Karpathy's idea file: <https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f>

KOS adapts that pattern to the Kodex OS layer model. In Kodex OS, the LLM Wiki is **Layer 1 — the Knowledge Base**. It sits between Layer 0 (Field Notes, the physical intake layer) and Layer 2 (Notion, the operations layer). Layer 1's job is to be the bridge: it ingests scanned and transcribed Field Notes pages from `raw/` and produces an LLM-maintained wiki in `wiki/` that Layer 2 can draw from.

That dependency direction is fixed. `raw/` feeds `wiki/`. `wiki/` feeds Notion. Never the other way around.

---

## THE PATTERN (in Kodex OS terms)

A KOS vault contains four top-level locations:

- **`raw/`** — the immutable input sub-layer. Scanned and transcribed Field Notes pages, clipped articles, papers, transcripts. Each Field Notes memo book maps 1:1 to a folder under `raw/`, named by purpose: `FL-vol-XXX/` for daily logs (Field Log), `FR-vol-XXX/` for catchall research (Field Research), `FS-vol-XXX/` for dedicated subject study (Field Study). The LLM **never modifies** anything under `raw/`.
- **`wiki/`** — the LLM-generated, LLM-maintained output sub-layer. Subdivided into six purposeful directories — `sources/` (one summary per ingested raw file), `books/` (one page per memo book), `entities/` (people, orgs, products, tools, places), `concepts/` (ideas, frameworks, theories), `synthesis/` (cross-cutting analyses), and `questions/` (open questions extracted from sources) — plus two special files: `index.md` (the master catalog) and `log.md` (the chronological operation record).
- **`output/`** — generated reports, query results, and synthesis artifacts.
- **`SCHEMA.md`** — the rules the LLM follows when maintaining the wiki. This is the contract.

The system runs entirely on markdown. No vector store, no embedding pipeline, no fancy RAG. Just files, conventions, and a librarian (the LLM) that follows `SCHEMA.md`.

The agent config file at the vault root (`CLAUDE.md`, `AGENTS.md`, etc.) tells the LLM how to behave as that librarian — the architecture, operations, page format, and rules.

**One inline convention worth knowing:** the user can reference websites in raw sources using a bit.ly slug encoded in angle brackets (e.g., `<F13LdN0t3>` becomes `https://bit.ly/F13LdN0t3`). The LLM expands these on ingest. See SCHEMA.md Section 5 for the full convention.

---

## WHAT YOU NEED TO BUILD THIS

**[Field Notes memo books](https://fieldnotesbrand.com)** — Layer 0. KOS is downstream of Field Notes. Without a physical capture practice, KOS has nothing to ingest. (You can substitute any analog or digital intake source, but the Kodex OS reference implementation assumes Field Notes.)

**[Obsidian](https://obsidian.md)** — the frontend. A markdown editor that treats a folder of `.md` files like a wiki, with backlinks and a graph view. The KOS vault *is* an Obsidian vault.

**An AI coding agent** — the LLM that reads sources, writes wiki pages, and maintains everything. Any Agent Skills-compatible agent works:

- Claude Code → `CLAUDE.md`
- OpenAI Codex → `AGENTS.md`
- Cursor → `.cursor/rules/*.mdc`
- Gemini CLI → `GEMINI.md`

**[Obsidian Web Clipper](https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf)** — for web sources. Saves clipped articles as clean markdown directly into `raw/`.

**A scanner or scanning app** — for Field Notes pages. Anything that produces legible images the LLM can transcribe. Scans go into the appropriate `raw/F[LRS]-vol-XXX/` folder, depending on which kind of memo book they came from (log, research, or study).

---

## FOUR OPERATIONS

KOS exposes four Agent Skills, one per operation:

**`/kos` — Onboarding.** Scaffolds a new Layer 1 vault. Creates `raw/` (with `assets/`), `wiki/` (with all six subdirectories: `sources/`, `books/`, `entities/`, `concepts/`, `synthesis/`, `questions/`), and `output/`. Bootstraps `wiki/index.md` (with section headers for all six) and `wiki/log.md`. Installs `SCHEMA.md` from the canonical template at `templates/SCHEMA.md` in the KOS repo. Generates the agent config file (`CLAUDE.md`, `AGENTS.md`, etc.) tailored to the user's agent. Refuses to overwrite an existing vault.

**`/kos-ingest` — Ingest.** Processes a raw source into wiki pages. Reads from `raw/` without modification, creates a summary in `wiki/sources/`, creates or updates the corresponding `wiki/books/` page (for sources from memo books), extracts entities and concepts into their respective directories, extracts open questions into `wiki/questions/`, and expands inline bit.ly slugs (per SCHEMA.md Section 5). A single source typically touches 5–15 wiki pages. Always updates `wiki/index.md` and appends an entry to `wiki/log.md`. Has two modes: discussion (confirms takeaways with the user before writing) and quick (batch ingest without check-ins).

**`/kos-query` — Query.** Answers questions against the wiki. Classifies the query (factual lookup, time-scoped, status-scoped, comparison, exploration, source-tracing, archive-lookup), searches the matching directories, follows wikilinks one hop for context, and synthesizes an answer with kebab-case wikilink citations to specific wiki pages. **Refuses to fabricate** — when the wiki doesn't contain an answer, the skill says so explicitly rather than falling back on training data. Optionally saves valuable answers as new `wiki/synthesis/` pages. Always logs the query, including whether the wiki could answer it (`yes` / `partial` / `no`), so gaps in coverage are visible over time.

**`/kos-lint` — Lint.** Health-checks the wiki against SCHEMA.md. Runs eight checks at minimum (raw/sources sync, books/raw sync, broken wikilinks, index consistency, frontmatter validation, unresolved bit.ly slugs, schema version, orphan pages) plus optional deep-audit checks (duplicate entities, stale claims, contradictions). Findings are grouped by severity (Error / Warning / Info). Reports per-finding rather than batch — the user approves each fix individually, since some findings have ambiguous correct answers (orphan pages: link or delete? duplicate entities: which page survives?). Does not migrate schemas automatically.

---

## THE AGENT CONFIG FILE

The agent config is the entry point of Layer 1. It tells the LLM where it's operating and points to the contract. The key sections:

- **Vault location** — the path to the KOS vault and its purpose (filled in by the `/kos` wizard from the user's domain description)
- **Schema reference** — a pointer to `./SCHEMA.md` at the vault root, which is the canonical contract for the vault
- **Skills available** — the four (eventually five) KOS commands the agent can invoke against the vault
- **Operating rules** — a brief restatement of the most important constraints (raw is immutable, do not fabricate during query, follow SCHEMA.md when in doubt)

The agent config does **not** embed SCHEMA.md's contents. It references the schema file at the vault root. This way, if the user edits `SCHEMA.md` (to add a directory, change a convention, soften a rule), every agent picks up the change without the config drifting.

The `/kos` onboarding skill generates the config from a template in `skills/kos/references/agent-configs/` — one template per supported agent (Claude Code, Codex, Cursor, Gemini CLI). You can edit the generated file after onboarding; if you change the rules, run `/kos-lint` afterward to confirm the existing wiki still conforms.

---

## SCHEMA OWNERSHIP

`SCHEMA.md` is the contract between you and the LLM. KOS ships a canonical `SCHEMA.md` template at `templates/SCHEMA.md` in the repo root, and the `/kos` wizard installs it into every new vault. The default schema is opinionated:

- Memo books are typed by purpose: `FL-vol-XXX` (Field Log), `FR-vol-XXX` (Field Research), `FS-vol-XXX` (Field Study). Each maps 1:1 to a folder under `raw/`.
- Each `raw/` source has exactly one `wiki/sources/` summary page; each memo book has exactly one `wiki/books/` page.
- Open questions extracted from sources become first-class pages in `wiki/questions/`, with a `status:` field (open / answered / dismissed) for filtering.
- The user can encode a shortened bit.ly URL inline using angle brackets (`<slug>`); the LLM expands these to full URLs on ingest, with case-sensitivity preserved.
- Wiki pages use Obsidian wikilinks (`[[double-bracket]]`) for internal references and markdown links for external URLs.
- `wiki/index.md` is updated on every ingest. `wiki/log.md` records every ingest, query, lint, and archive with a structured entry.
- Filenames are kebab-case, ASCII only. Frontmatter is mandatory.

You can override any of this in your vault's `SCHEMA.md`. KOS will follow whatever is there. But the defaults are what make a KOS vault interoperate with the rest of the Kodex OS stack — particularly Layer 2 (Notion), which reads from a stable `wiki/` directory.

The schema is versioned (`schema-version:` field in the YAML header). When KOS ships a schema update, `/kos-lint` detects the version mismatch and surfaces it; migrations are user-driven, never automatic.

---

## MULTI-AGENT SUPPORT

The Layer 1 pattern is agent-agnostic — it's just markdown files and conventions. The same `SCHEMA.md` works in any Agent Skills-compatible agent. This means you can:

- Set up a vault with Claude Code, then also work in it from Cursor
- Switch agents without rebuilding the vault
- Have multiple agents operate on the same vault (they follow the same `SCHEMA.md`)

---

## RELATIONSHIP TO THE REST OF KODEX OS

KOS is one tool in a five-layer stack. It only owns Layer 1. The other layers are out of scope:

| Layer | Owned by | kos involvement |
| --- | --- | --- |
| Layer 0 — Raw Capture (Field Notes) | The physical world | KOS consumes scans/transcriptions of Field Notes into `raw/` |
| Layer 1 — Knowledge Base (LLM Wiki) | **KOS** | This repo |
| Layer 2 — Project Intelligence (Notion) | Notion | Layer 2 reads from `wiki/`; KOS does not write to Notion |
| Layer 3 — The Archive | Physical envelopes | KOS confirms wiki completeness before archiving |
| Layer 4 — Project Management (Trello) | Trello | No direct relationship |

The boundary matters. KOS does not orchestrate the other layers. It implements Layer 1 well and exposes a stable `wiki/` directory that downstream tools can read.

---

## OPTIONAL TOOLS

These extend what the LLM can do. None are required, but all are recommended as the wiki grows.

**summarize** — summarize links, files, and media from the CLI or Chrome Side Panel.

> `npm i -g @steipete/summarize`

**qmd** — local search engine for markdown files with hybrid BM25/vector search and LLM re-ranking, all on-device. Becomes important as the wiki grows past ~100 pages.

> `npm i -g @tobilu/qmd`

**agent-browser** — browser automation CLI for AI agents. Use for web research when native `web_search` or `web_fetch` fail.

> `npm i -g agent-browser && agent-browser install`

---

## HOW IT ALL FITS TOGETHER

Karpathy's pattern, restated in Kodex OS terms: capture freely (Layer 0), let the LLM compile a wiki (Layer 1, owned by KOS), develop projects from that knowledge (Layer 2), preserve the physical record (Layer 3), execute (Layer 4).

| Concept | Implementation in KOS |
| --- | --- |
| "Dump raw sources" | `raw/` directory + Field Notes transcriptions (FL/FR/FS volumes) + Obsidian Web Clipper |
| "LLM compiles a wiki" | `/kos-ingest` — reads sources, creates/updates pages across six wiki directories, expands bit.ly slugs, extracts open questions, maintains `index.md` and `log.md` |
| "Browse in Obsidian" | Obsidian reads `wiki/` with backlinks and graph view |
| "Ask questions" | `/kos-query` — searches wiki, synthesizes answers with citations, refuses to fabricate when the wiki is silent |
| "Maintain quality" | `/kos-lint` — runs eight schema-validation checks plus optional deep audits, reports per-finding |
| "Set it up" | `/kos` — interactive wizard scaffolds the vault, installs SCHEMA.md, generates the agent config |
| "The contract" | `SCHEMA.md` at the vault root, copied from `templates/SCHEMA.md` by the wizard |

The idea is Karpathy's. The blueprint for KOS is this document. The architecture is [Kodex OS](https://github.com/k0d3x8its/kodex-os). The `skills/` directory is the executable implementation — but you could build your own Layer 1 from this blueprint using any LLM and any tooling you prefer, as long as it respects the `raw/` → `wiki/` → Layer 2 dependency direction.
