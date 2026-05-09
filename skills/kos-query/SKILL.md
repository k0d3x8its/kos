---
name: kos-query
description: Use this skill when the user wants to ask a question, search, or retrieve information from their existing Kodex OS Layer 1 LLM Wiki. Triggers include "ask kos", "what does my wiki say about X", "find notes on Y", "search my wiki", "what's open on Z", or any retrieval-style question that should be answered from the user's own captured knowledge rather than general world knowledge. The skill searches across all six wiki directories (sources, books including the _archived/ subfolder, entities, concepts, synthesis, questions), follows wikilinks, and synthesizes an answer with citations to specific wiki pages. Refuses to fabricate when the wiki doesn't contain the answer. Do not use this skill to add new content (use kos-ingest) or to validate wiki structure (use kos-lint).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# KOS — Query

Answer questions by searching and synthesizing knowledge from the wiki.

## Before You Begin: Read the Contract

**Always read `<vault-root>/SCHEMA.md` first.** It defines the directory structure, page format, and operation rules. The user may have customized it. If anything in this skill conflicts with SCHEMA.md, **SCHEMA.md wins**.

If `SCHEMA.md` does not exist at the vault root, stop and tell the user the vault is not initialized. Suggest they run `/kos`.

---

## The Most Important Rule

**Answer ONLY from the wiki. Do not fabricate.**

If the wiki does not contain the information needed to answer the question, say so explicitly. Do not fall back on training data. Do not infer beyond what's in the pages. Do not paraphrase plausible-sounding answers from general knowledge.

When the wiki is silent on a topic:

> "Your wiki doesn't have information on this. The closest pages I found were [[page-1]] and [[page-2]], but neither addresses your question directly. Want me to web-search for it instead, or would you like to ingest a source on this topic first?"

This is the load-bearing rule of `/kos-query`. Violating it makes the wiki useless — the user can't tell which answers came from their own captured knowledge versus the LLM's general knowledge.

---

## Classify the Query

Before searching, identify the query type — different types need different search strategies:

- **Factual lookup** — "What does my wiki say about X?" → search by topic
- **Time-scoped** — "What was I working on in March?" → filter by date in book/source frontmatter
- **Status-scoped** — "What questions are still open?" → filter `wiki/questions/` by `status: open`
- **Comparison** — "How do X and Y differ in my notes?" → read both topics, synthesize
- **Exploration** — "What have I been thinking about?" → broader scan, narrative answer
- **Source-tracing** — "Where did I read about X?" → return source pages with context
- **Archive lookup** — "What's in envelope 7?" → search `wiki/books/_archived/` by `envelope-number` or `archived-on`

If the query type is ambiguous, ask the user before searching.

---

## Search Strategy

### 1. Start with the index

Read `wiki/index.md`. Scan all section headers for entries matching the query:
`## Books`, `## Archived Books`, `## Sources`, `## Entities`, `## Concepts`, `## Synthesis`, `## Questions (open)`

The index is the cheapest source of structured signal. For time-scoped or archive queries, `## Archived Books` is often where the answer lives.

### 2. Use qmd if available

```bash
command -v qmd   # check if installed
qmd search "query terms" --path wiki/
```

Use for wikis larger than ~100 pages where index-scanning becomes inefficient.

### 3. Fall back to grep

```bash
grep -rli "query terms" wiki/ | xargs -I{} sh -c 'echo "$(grep -ic "query terms" {}) {}"' | sort -rn
```

Read the top 5–10 most relevant pages.

### 4. Read identified pages

Follow `[[wikilinks]]` **one hop** only — do not follow links transitively. That explodes quickly in a well-linked wiki.

**Search bounds:**
- Start with up to 5 directly relevant pages
- If unanswered, expand to up to 10 more
- Beyond ~20 pages, stop and ask the user whether to keep searching, narrow the question, or proceed with a partial answer

### 5. Apply directory-specific strategies

| Query type | Primary directories | Filter on |
|------------|--------------------|-----------| 
| Factual lookup | `entities/`, `concepts/`, `synthesis/`, `sources/` | topic match |
| Time-scoped | `books/` (incl. `_archived/`), `sources/` | `date-start`, `date-end`, `created` |
| Status-scoped | `questions/` | `status: open` |
| Comparison | `entities/`, `concepts/` | both topics |
| Exploration | `synthesis/`, `index.md` | broad |
| Source-tracing | `sources/` | mention of topic |
| Archive lookup | `books/_archived/` | `envelope-number`, `archived-on` |

**Book pages live in two locations.** Always scan recursively:

```bash
find wiki/books -type f -name '*.md'
grep -rn "search terms" wiki/books/
```

For time-scoped queries, older ranges are more likely in `_archived/` — don't filter it out.

### 6. Last resort: read raw sources

Only if wiki pages don't contain the answer. If raw content answers the question but isn't in the wiki, tell the user — they may want to re-ingest the source.

---

## Synthesize the Answer

### Format by query type

- **Factual lookup** → direct answer with citations
- **Time-scoped** → chronological list or narrative
- **Status-scoped** → bulleted list grouped by category
- **Comparison** → table or structured side-by-side
- **Exploration** → narrative connecting linked concepts
- **Source-tracing** → bulleted list of sources with one-line context

### Citations

Cite wiki pages using `[[wikilink]]` syntax with **kebab-case page names** matching actual filenames per SCHEMA.md Section 6.1.

**Correct:**
> According to [[karpathy-llm-wiki]], the key insight was X. This relates to [[zettelkasten]], which [[niklas-luhmann]] developed.

**Incorrect** (these break wikilinks lint will flag):
> According to [[Karpathy LLM Wiki]] or [[Source - Karpathy's Article]]...

Every factual claim should link to the wiki page it came from. If you can't cite a page for it, it probably came from training data — see "The Most Important Rule."

### Preserve external URLs

If a cited source contains a bit.ly slug or external URL, include it when relevant:

> [[fl-vol-001-page-007]] notes this, with reference to [<F13LdN0t3>](https://bit.ly/F13LdN0t3).

### Cite archived books with physical location

When citing from an archived book, include the envelope number so the user can find the physical book:

> Your earliest notes on this topic are in [[fl-vol-001-page-007]] (archived in envelope 7), where you wrote that...

### Acknowledge gaps

> "Your wiki has detailed notes on the historical context (see [[zettelkasten]]) but doesn't cover modern digital implementations. Want me to web-search for those, or treat this as a question to ingest?"

---

## Offer to Save Valuable Answers

If the answer represents new analysis worth keeping — a non-trivial comparison, a synthesis across sources, a connection the wiki didn't already make explicit — offer to save it:

> "This synthesizes [[page-a]], [[page-b]], and [[page-c]] in a way the wiki doesn't capture yet. Want me to save it as a synthesis page?"

If the user agrees:

### 1. Create the synthesis page

Filename: kebab-case description (`note-taking-systems-compared.md`).

> Read `./templates/frontmatter-templates.md` for the complete synthesis frontmatter block.

Body: the answer text, with all wikilink citations preserved.

### 2. Update wiki/index.md

Add an entry under `## Synthesis` with the page name and a one-line description (under 120 characters). Update the `_Last updated:_` timestamp.

### 3. Cross-link from cited pages (optional, recommended)

Add a wikilink to the new synthesis from the source/concept/entity pages it draws from. Prevents the synthesis from being orphaned (which lint flags).

---

## Always Log the Query

Every operation appends to `wiki/log.md` per SCHEMA.md Section 6.1 rule 3 — including queries that don't save anything.

> Read `./references/ingest-log-examples.md` for the query log entry format.

Field guidance:
- **Question** — the user's actual question, quoted
- **Pages read** — wikilinks to pages consulted, with a count
- **Answered from wiki** — `yes`, `partial`, or `no` (so lint and future queries can see knowledge gaps)
- **Synthesis saved** — wikilink to the new synthesis page, or omit if none
- **Notes** — gaps, contradictions, unresolved slugs encountered

---

## Conventions

- **Wiki first, raw last.** Only read raw sources if wiki summaries are insufficient.
- **Cite everything.** Untraced claims hide the line between captured knowledge and fabrication.
- **Don't fabricate.** Say "the wiki doesn't have this" when it doesn't.
- **One-hop wikilink traversal only.**
- **Always log the query**, even when nothing is saved.
- **Wikilinks are kebab-case** matching real filenames.
- **`raw/` is read-only.** Never write to it.

---

## Related Skills

- `/kos-ingest` — process new sources (use when raw content answers a question the wiki missed)
- `/kos-lint` — health-check the wiki for issues
