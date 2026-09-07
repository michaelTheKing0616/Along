# Build Ledger Archive

`docs/BUILD_LEDGER.md` is the **append-only** build history for the Along project. The Orchestrator is the only role permitted to write new entries (spec §2.2, §2.4).

## Why this file exists

The ledger has grown to thousands of lines covering every phase from bootstrap through Phase 12. It must remain append-only so git history and session resumes stay trustworthy — but it is too large to copy into archive files or duplicate in task deliverables.

**Use this document to understand how to read, search, and optionally archive superseded material — not as a second ledger.**

## Reading the live ledger

1. Open `docs/BUILD_LEDGER.md`.
2. Newest entries are at the **bottom** (reverse chronological within the file).
3. Before issuing or resuming a task, read the **last 10–15 entries** (Orchestrator rule in spec §2.2).
4. Search by task ID (`P12-E-01`), phase gate, or keyword:
   ```bash
   rg "P12-E-01" docs/BUILD_LEDGER.md
   rg "Phase 9" docs/BUILD_LEDGER.md
   ```

## What belongs in the ledger vs elsewhere

| Artifact | Location | Who writes |
|---|---|---|
| Task pass/fail, reviewer verdict, escalations | `docs/BUILD_LEDGER.md` | Orchestrator only |
| Task evidence (commands run, test output, dry-runs) | `docs/reports/p*-*.md` | Worker |
| Architecture decisions | `docs/adr/` | Worker + human approval |
| Operational procedures | `docs/runbooks/` | Phase owner Worker |

Workers **do not** append to `BUILD_LEDGER.md` unless the task explicitly says otherwise (this task does not).

## Archiving superseded planning notes (optional)

When pre-implementation planning text is fully superseded by code + blueprint + ADRs, you may trim **duplicate narrative** from auxiliary docs — never from `BUILD_LEDGER.md` itself.

Suggested approach:

1. Confirm the planning note is captured in an ADR, blueprint section, or a ledger entry.
2. Move the obsolete doc to `docs/archive/<YYYY-MM>-<short-name>.md` with a one-line header:
   ```markdown
   > **Superseded** by `<path-to-authoritative-doc>`. Kept for history only.
   ```
3. Leave a stub link at the old path if external links exist, or update the stub in blueprint `00_README.md`.
4. Record the archival decision in the next Orchestrator ledger entry (one line — not the full archived text).

Do **not** bulk-export the ledger into this archive file. If long-term cold storage is needed, use git tags on commits that close a phase gate (`git log --oneline -- docs/BUILD_LEDGER.md`).

## Related

- `docs/ALONG_BUILD_SPEC.md` §2.2–§2.4 — ledger format and Orchestrator duties
- `docs/blueprint/00_README.md` — blueprint index
- `docs/reports/` — per-task evidence and dry-run records
