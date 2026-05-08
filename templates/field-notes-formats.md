# Field Notes Formats

> Referenced by SCHEMA.md. The LLM reads this file before ingesting any FL or FS source.
> Defines the structured capture formats for Field Log and Field Study memo books.

---

## Field Log Entry Format {#field-log}

Field Log pages use a structured entry header. Each page contains **one or two entries** — never more. A single entry may also span multiple pages when the content is long.

### Entry Header Format

```
[DAY]  [TEMP]°  [TIME]  [DATE M/D/YY]
────────────────────────────────────────
[free-form journal text]
```

| Field | Format | Example |
|-------|--------|---------|
| `DAY` | Three-letter abbreviation | `SUN` `MON` `TUE` `WED` `THU` `FRI` `SAT` |
| `TEMP` | Integer + degree symbol, Fahrenheit | `59°` |
| `TIME` | 12-hour clock with am/pm | `10:45am` |
| `DATE` | `M/D/YY` | `5/3/26` |

A horizontal rule separates the header from the journal text and separates consecutive entries on the same page.

### Multi-Page Entries

When a single entry's journal text continues onto the next physical page, the continuation page has **no header** — it begins mid-sentence. The LLM MUST carry the most recent header's metadata forward as the canonical date, time, temperature, and day for the continuation content.

### Two-Entry Pages

When two entries appear on one page, each has its own header and horizontal rule. The LLM MUST extract both entries independently and store them as separate structured records within the source page.

### Extracted Fields per Entry

Used in `wiki/sources/` frontmatter under `entries:`:

```yaml
entries:
  - date: YYYY-MM-DD       # M/D/YY converted to ISO 8601
    day: Sunday            # full day name, not abbreviation
    temp: 59               # integer, Fahrenheit
    time: "10:45am"        # string, preserve am/pm
    summary: ""            # brief LLM summary of this entry's content
```

A page with two entries produces **one source page** with **two items** in `entries:`. A continuation page (no header) inherits the previous page's entry metadata.

---

## Field Study Page Format {#field-study}

Field Study pages are structured knowledge documents, not chronological logs. They document a single subject in depth across one or more pages. There are no date stamps in the handwriting — the ingestion timestamp in frontmatter serves as the record of when the content entered the wiki.

### Required Skeleton

Every Field Study source page MUST include these sections in this order. Create them even if the raw source has no content for a section yet — leave the body empty and note it as unpopulated:

```markdown
## Origins
When, where, and how the subject began. Key historical context.

## Key Figures
People, organizations, or movements central to the subject.

## Core Principles
The fundamental ideas, rules, or frameworks that define the subject.

## Open Questions
What the user still wants to learn or investigate about this subject.
```

### Subject-Specific Sections

After the required skeleton, the LLM MAY add additional sections that fit the subject's unique structure. These are not templated — the LLM derives them from the raw content.

- Must appear **after** `## Core Principles` and **before** `## Open Questions`
- Examples: Stoicism → `## Virtues`, `## Practices`; A.I. → `## Architectures`, `## Key Papers`

### Multi-Page Studies

A single Field Study subject may span many pages in the physical book. The LLM MUST accumulate content across all ingested pages for the same subject into the corresponding `wiki/sources/` page — it is a **living document**, not a one-time snapshot. Each ingest from the same FS volume appends and updates; it does not create a new source page per physical page.
