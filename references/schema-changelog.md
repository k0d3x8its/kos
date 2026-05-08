# Schema Version History

> Delegated from SCHEMA.md Section 8. The LLM does not need to read this file during normal operations.
> `/kos-lint` reads this file when checking for schema-version mismatches.

| Version | Date | Changes |
|---------|------|---------|
| 1 | 2026-05 | Initial KOS schema. Defines `raw/` (with `FL/FR/FS-vol-XXX` memo book conventions), `wiki/{sources,books,entities,concepts,synthesis,questions}/`, and `output/`. Establishes bit.ly slug convention. Forked from NicholasSpisak/second-brain but versioned independently. |
| 2 | 2026-05 | Reorganized `raw/` into typed subdirectories: `Field-Logs/`, `Field-Research/`, `Field-Studies/`. Updated all path references and lint rules accordingly. |
| 3 | 2026-05 | Added scanned page filename conventions (bare/sticky/under/flip suffixes, merge rule, orphaned companion detection). |
| 4 | 2026-06 | Added Field Log entry format: structured header with day, temperature, time, and date. Added `entries:` frontmatter for `field-log-page` sources. |
| 5 | 2026-06 | Added Field Study page format: required skeleton (Origins, Key Figures, Core Principles, Open Questions), subject-specific free-form sections, multi-page accumulation rule, and dedicated frontmatter. |
