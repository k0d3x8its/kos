# Transcript Formats

> Read by `kos-ingest` before processing any `transcript-youtube`, `transcript-podcast`, or `transcript-meeting` source.

---

## Output Format

Each transcript produces a single source page with this structure:

```markdown
---
frontmatter
---

## Summary
5–7 sentences covering the full content of the transcript.

---

## [MM:SS – MM:SS] Topic Title
3–5 sentence summary of what this segment covers.

### Transcript
Verbatim transcript content for this segment, broken into
readable paragraphs at natural speaking pauses and topic shifts.

---

## [MM:SS – MM:SS] Next Topic Title
3–5 sentence summary.

### Transcript
...

---

## Full Transcript

[00:00] Opening paragraph...

[04:32] Next paragraph...

[14:22] Content before the ad...

[Sponsored segment excluded — 14:45–17:05]

[17:06] Content resumes...
```

---

## Ad Detection

Scan the raw transcript **before structuring**. Flag a block as a sponsored segment if it contains any of the following:

**Trigger phrases:**
- "our sponsor", "brought to you by", "this episode is sponsored by"
- "promo code", "use code", "discount code"
- "go to [URL] and use", "first link in the description"
- "I want to thank our sponsor", "check them out at"

**When triggered:**
1. Identify the start and end timestamp of the ad block
2. Exclude the block entirely from `## Summary`, topic segment summaries, and `### Transcript` sections
3. In `## Full Transcript` only, insert inline: `[Sponsored segment excluded — MM:SS–MM:SS]`
4. If no ads are detected, omit this step — no placeholder or notation needed

**Uncertainty rule:** If a block is ambiguous (host mentions a tool they genuinely use vs. a paid placement), leave it in. Only exclude blocks with clear promotional intent.

**Meeting exception:** Do not run ad detection on `transcript-meeting` sources. Skip this step entirely for meetings.

---

## Paragraph Chunking Rules

Apply when building both the `### Transcript` subsections and the `## Full Transcript` section:

- Break at natural sentence endings and speaking pauses
- Break at topic or thought shifts
- Never break mid-sentence
- Each paragraph in `## Full Transcript` gets the `[MM:SS]` timestamp of its first word, taken from the raw file. For content over 60 minutes, timestamps will exceed `[60:00]` (e.g. `[62:45]`) — this matches KOS Capture's output format exactly.

---

## Segment Boundary Rules

Topic segments (`## [MM:SS – MM:SS] Topic Title`) are **topic-driven, not time-driven**:

- A segment lasts as long as the topic lasts — could be 3 minutes, could be 15
- Determine boundaries by tracking topic shifts in the content, not the clock
- Name each segment with a concise title that describes what was discussed
- Each segment summary is 3–5 sentences of full prose — no bullet points
