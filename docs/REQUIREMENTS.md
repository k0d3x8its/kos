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

- **`raw/`** — the immutable input sub-layer. Scanned and transcribed Field Notes pages, clipped articles, papers, transcripts. Each Field Notes memo book maps 1:1 to a folder under `raw/` (e.g. `FN-vol-001/`, `R-vol-001/`). The LLM **never modifies** anything here.
- **`wiki/`** — the LLM-generated, LLM-maintained output sub-layer. Subdivided into `sources/`, `entities/`, `concepts/`, and `synthesis/`, plus two special files: `index.md` (the master catalog) and `log.md` (the chronological operation record).
- **`output/`** — generated reports, query results, and synthesis artifacts.
- **`SCHEMA.md`** — the rules the LLM follows when maintaining the wiki. This is the contract.

The system runs entirely on markdown. No vector store, no embedding pipeline, no fancy RAG. Just files, conventions, and a librarian (the LLM) that follows `SCHEMA.md`.

The agent config file at the vault root (`CLAUDE.md`, `AGENTS.md`, etc.) tells the LLM how to behave as that librarian — the architecture, operations, page format, and rules.

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

**A scanner or scanning app** — for Field Notes pages. Anything that produces legible images the LLM can transcribe. Scans go into the appropriate `raw/FN-vol-XXX/` folder.

---

## FOUR OPERATIONS

KOS exposes four Agent Skills, one per operation:

**`/kos` — Onboarding.** Scaffolds a new Layer 1 vault. Creates `raw/`, `wiki/` (with `sources/`, `entities/`, `concepts/`, `synthesis/`), and `output/`. Bootstraps `wiki/index.md` and `wiki/log.md`. Generates the agent config file. Installs `SCHEMA.md` from the kos template.

**`/kos-ingest` — Ingest.** Processes a raw source into wiki pages. Reads from `raw/`, creates a summary in `wiki/sources/`, creates or updates entity and concept pages, adds wikilinks between related pages, updates `index.md` and `log.md`. A single source typically touches 10–15 wiki pages. Never modifies `raw/`.

**`/kos-query` — Query.** Answers questions against the wiki. Reads `index.md` to find relevant pages, follows wikilinks, synthesizes an answer with citations back to specific wiki pages, offers to save valuable results as `synthesis/` pages.

**`/kos-lint` — Lint.** Health-checks the wiki. Scans for broken wikilinks, orphan pages, contradictions, stale claims, missing cross-references between `raw/` sources and `wiki/sources/` entries, and data gaps. Reports findings by severity. Does not make destructive changes without explicit approval.

---

## THE AGENT CONFIG FILE

The agent config is the brain of Layer 1. It tells the LLM exactly how to behave. The key sections:

- **Architecture** — four locations (`raw/`, `wiki/`, `output/`, `SCHEMA.md`), wiki subdirectories (`sources/`, `entities/`, `concepts/`, `synthesis/`), two special files (`index.md`, `log.md`)
- **Page format** — YAML frontmatter (tags, sources, created, updated) + wikilink syntax
- **Operations** — step-by-step workflows for ingest, query, and lint
- **Rules** — the constraints governing the LLM's behavior (never modify `raw/`, always update `index.md`, every `raw/` source must have a `wiki/sources/` entry, etc.)

The `/kos` onboarding skill generates this file from the canonical rules in `skills/kos/references/wiki-schema.md`. You can edit it after generation — but if you change the rules, run `/kos-lint` afterward to confirm the existing wiki still conforms.

---

## SCHEMA OWNERSHIP

`SCHEMA.md` is the contract between you and the LLM. KOS ships a default `SCHEMA.md` template that aligns with the Kodex OS Layer 1 specification. The default schema is opinionated:

- Each Field Notes memo book maps 1:1 to a folder under `raw/`
- Each `raw/` source must have exactly one `wiki/sources/` summary page
- Wiki pages use Obsidian wikilinks (`[[double-bracket]]`), not markdown links
- `index.md` is updated on every ingest
- `log.md` records every ingest, query, and lint with a timestamp

You can override any of this in your vault's `SCHEMA.md`. KOS will follow whatever is there. But the defaults are what make a KOS vault interoperate with the rest of the Kodex OS stack.

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
| "Dump raw sources" | `raw/` directory + Field Notes scans + Obsidian Web Clipper |
| "LLM compiles a wiki" | `/kos-ingest` — reads sources, creates/updates wiki pages, maintains `index.md` and `log.md` |
| "Browse in Obsidian" | Obsidian reads `wiki/` with backlinks and graph view |
| "Ask questions" | `/kos-query` — searches wiki, synthesizes answers with citations |
| "Maintain quality" | `/kos-lint` — audits for contradictions, orphans, stale claims, raw/wiki sync |
| "Set it up" | `/kos` — interactive wizard scaffolds everything |
| "The contract" | `SCHEMA.md` at the vault root, generated from KOS defaults |

The idea is Karpathy's. The blueprint for KOS is this document. The architecture is [Kodex OS](https://github.com/k0d3x8its/kodex-os). The `skills/` directory is the executable implementation — but you could build your own Layer 1 from this blueprint using any LLM and any tooling you prefer, as long as it respects the `raw/` → `wiki/` → Layer 2 dependency direction.
