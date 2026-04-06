# Second Brain

An LLM-maintained personal knowledge base built on the [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). Drop raw sources into a folder, let the LLM compile them into a structured wiki, and browse it all in Obsidian.

![Second Brain Overview](docs/assets/second-brain-overview.png)

## How It Works

You feed raw material (articles, papers, notes, transcripts) into a `raw/` folder. The LLM reads everything, writes structured wiki pages, creates cross-references, and maintains an index. You browse the results in Obsidian — following links, exploring the graph view, and asking questions.

The LLM is the librarian. You're the curator.

## Install

```bash
npx skills add <repo-url>
```

This installs four skills into your AI agent (Claude Code, Codex, Cursor, Gemini CLI, and 40+ others):

| Skill | What it does |
|---|---|
| `/second-brain` | Set up a new vault (guided wizard) |
| `/second-brain-ingest` | Process raw sources into wiki pages |
| `/second-brain-query` | Ask questions against your wiki |
| `/second-brain-lint` | Health-check the wiki |

## Quick Start

1. **Install the skills** (see above)
2. **Run the wizard:** `/second-brain` — it walks you through setup
3. **Install Web Clipper:** [Obsidian Web Clipper](https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf) for saving articles to your vault
4. **Open in Obsidian** — point Obsidian at your new vault folder
5. **Clip an article** to `raw/`, then run `/second-brain-ingest`

## What You Get

```
your-vault/
├── raw/                    # Your inbox — drop sources here
│   └── assets/             # Images and attachments
├── wiki/                   # LLM-maintained wiki
│   ├── sources/            # One summary per ingested source
│   ├── entities/           # People, orgs, products, tools
│   ├── concepts/           # Ideas, frameworks, theories
│   ├── synthesis/          # Comparisons, analyses, themes
│   ├── index.md            # Master catalog of all pages
│   └── log.md              # Chronological operation record
├── output/                 # Reports and generated artifacts
└── CLAUDE.md               # Agent config (varies by agent)
```

## Optional Tools

The wizard offers to install these. All optional but recommended:

- **[summarize](https://github.com/steipete/summarize)** — summarize links, files, and media from the CLI
- **[qmd](https://github.com/tobi/qmd)** — local search engine for markdown files (useful as wiki grows)
- **[agent-browser](https://github.com/vercel-labs/agent-browser)** — browser automation for web research

## Based On

- [Andrej Karpathy's LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)
- [Agent Skills open standard](https://agentskills.io)
- [Blueprint & origin story](docs/REQUIREMENTS.md) — the founding document for this project
