# KOS

> The Layer 1 toolkit for [Kodex OS](https://github.com/k0d3x8its/kodex-os) — a set of Agent Skills that turn an Obsidian vault into an LLM-maintained knowledge base.

KOS is what you install when you want to add the LLM Wiki layer to your Kodex OS stack. It handles vault setup, ingest from `raw/`, querying with citations, and integrity checks against a versioned schema — everything the [Layer 1 spec](https://github.com/k0d3x8its/kodex-os#layer-1--knowledge-base) calls for.

Forked from [NicholasSpisak/second-brain](https://github.com/NicholasSpisak/second-brain) and based on [Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

---

## How It Works

You feed raw material into a `raw/` folder — scanned or mere photographed Field Notes pages, transcribed memo book entries, clipped articles, papers, transcripts. The LLM reads everything, writes structured wiki pages into `wiki/`, creates cross-references, and maintains an index. You browse the results in Obsidian — following links, exploring the graph view, and asking questions.

The LLM is the librarian. You're the curator. `raw/` is immutable. `wiki/` is owned by the LLM. The contract between you and the LLM lives in `SCHEMA.md` at the vault root.

This is Layer 1 of a [larger system](https://github.com/k0d3x8its/kodex-os). Layer 0 (Field Notes) feeds it. Layer 2 (Notion) reads from it. KOS does not cross those boundaries — it owns `wiki/` and nothing else.

## Prerequisites

- **[Obsidian](https://obsidian.md)** — the markdown editor you'll browse your wiki in
- **An AI coding agent** — [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [Cursor](https://cursor.com), [Gemini CLI](https://github.com/google-gemini/gemini-cli), or any agent that supports [Agent Skills](https://agentskills.io)
- **[Node.js](https://nodejs.org)** — required for installing the skills via npm
- **A Layer 0 capture practice** — recommended: [Field Notes memo books](https://fieldnotesbrand.com) per the Kodex OS spec, but any source of raw material works

## Install

```bash
npx skills add k0d3x8its/kos
```

This installs four skills into your AI agent:

| Skill | What it does |
| --- | --- |
| `/kos` | Set up a new Layer 1 vault (guided wizard) |
| `/kos-ingest` | Process raw sources into wiki pages |
| `/kos-query` | Ask questions against your wiki, with citations and no fabrication |
| `/kos-lint` | Health-check the wiki against SCHEMA.md |

## Quick Start

1. **Install the skills** (see above)
2. **Run the wizard:** type `/kos` in your AI agent — it walks you through naming, location, and tooling, and installs `SCHEMA.md` from the KOS default template
3. **Install Web Clipper:** [Obsidian Web Clipper](https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf) — configure it to save to your vault's `raw/` folder
4. **Open in Obsidian** — launch Obsidian, choose "Open folder as vault," select your vault folder
5. **Add your first source.** For Field Notes pages, create a memo-book folder under `raw/` and drop a transcribed page in:
    ```bash
        mkdir raw/FL-vol-001    # First Field Log book
        echo "your transcribed page content" > raw/FL-vol-001/page-001.md
    ```
   Or clip an article anywhere under `raw/` (`raw/assets/` is a common choice).
6. **Run `/kos-ingest`** — the LLM will discuss key takeaways and build wiki pages, including a `wiki/books/FL-vol-001.md` summary the first time it sees a new memo book
7. **Browse your wiki** in Obsidian — follow `[[wikilinks]]`, explore the graph view, check `wiki/index.md`
8. **Keep going** — `/kos-query` to ask questions, `/kos-lint` to health-check after every ~10 ingests

## What You Get

```text
your-vault/
├── raw/                    # Your inbox — drop sources here (immutable)
│   ├── FL-vol-XXX/         # Field Log: daily log memo books
│   ├── FR-vol-XXX/         # Field Research: catchall research memo books
│   ├── FS-vol-XXX/         # Field Study: dedicated subject memo books
│   └── assets/             # Images and attachments
├── wiki/                   # LLM-maintained (do not edit by hand)
│   ├── sources/            # One summary per ingested source
│   ├── books/              # One page per active memo book
│   │   └── _archived/      # Completed books that have been archived to Layer 3 envelopes
│   ├── entities/           # People, orgs, products, tools, places
│   ├── concepts/           # Ideas, frameworks, theories
│   ├── synthesis/          # Comparisons, analyses, themes
│   ├── questions/          # Open questions extracted from raw/
│   ├── index.md            # Master catalog of all pages
│   └── log.md              # Chronological operation record
├── output/                 # Reports and generated artifacts
├── SCHEMA.md               # Rules the LLM follows
└── CLAUDE.md               # Agent config (filename varies by agent)
```

## Ongoing Workflow

After your vault is set up and you've ingested your first sources, here's the rhythm of using KOS:

**Daily.** Capture in your Field Notes memo books (Layer 0). When you're ready to digitize, transcribe pages into the matching `raw/F[LRS]-vol-XXX/` folder and run `/kos-ingest`. The LLM creates wiki pages, extracts entities and open questions, and updates the index.

**Weekly-ish.** Run `/kos-query` against your wiki to find connections, recall things, or ask what you've been thinking about. The skill cites every claim back to specific wiki pages — if it can't cite, it tells you the wiki doesn't have an answer rather than making one up.

**Every ~10 ingests.** Run `/kos-lint` to catch broken wikilinks, frontmatter drift, unresolved bit.ly slugs, and orphan pages. Lint reports findings by severity and asks per-finding before applying fixes.

**When a memo book is full.** Place it in a numbered Layer 3 archive envelope. In your wiki, mark the corresponding `wiki/books/<volume>.md` page with `status: archived`, add `archived-on:` and `envelope-number:` to its frontmatter, and optionally move it to `wiki/books/_archived/` for visual organization. The `raw/<volume>/` folder is never moved or deleted — it stays as the immutable source. See [SCHEMA.md](templates/SCHEMA.md) Section 3.3 for the full archiving workflow.

## Where KOS Fits in Kodex OS

KOS is the reference implementation of [Kodex OS Layer 1](https://github.com/k0d3x8its/kodex-os#layer-1--knowledge-base). It sits between two layers it does not own:

```text
Layer 0: Raw Capture (Field Notes)  →  Layer 1: KOS (this repo)  →  Layer 2: Project Intelligence (Notion)
```

If you don't use Kodex OS, KOS still works fine as a standalone LLM Wiki tool — the layer model is the recommended context, not a requirement. If you do use Kodex OS, KOS is what makes Layer 1 real.

## Optional Tools

The wizard offers to install these. All optional but recommended:

- **[summarize](https://github.com/steipete/summarize)** — summarize links, files, and media from the CLI
- **[qmd](https://github.com/tobi/qmd)** — local search engine for markdown files (useful as wiki grows)
- **[agent-browser](https://github.com/vercel-labs/agent-browser)** — browser automation for web research

## Based On

- [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [Agent Skills open standard](https://agentskills.io)
- [NicholasSpisak/second-brain](https://github.com/NicholasSpisak/second-brain) — the upstream fork
- [Blueprint & full requirements](docs/REQUIREMENTS.md) — the design document for KOS

---

Part of [Kodex OS](https://github.com/k0d3x8its/kodex-os) — a layered personal knowledge management system.
