# Out-of-Scope Findings Backlog

> **These items were flagged by `/agentic-review` as out of scope for the branch
> on which they were found.** They may be stale, may already have been fixed by other
> means, may no longer apply after refactors, or may simply have been judged not worth
> addressing. Verify each entry against the current code before acting on it. Entries
> are removed only when explicitly addressed — no automatic cleanup.

---

## `ff4e6912` — Honcho API ordering does not await successful schema migration

- **File (at first sighting):** `nix/modules/nixos/container-services/honcho-memory/default.nix:51`
- **Symbol:** `&lt;file-scope>`
- **Bug class:** Concurrency
- **Description:**
  After/Requires wait for migration container startup, but its generated unit uses Type=notify and sdnotify=conmon, which reports readiness before Alembic completes. No completion barrier protects API/deriver database access.
  During a fresh boot or schema update, API startup/schema checks or deriver queries can reach an incomplete schema; a migration failure does not block initial startup.
- **Suggested fix:**
  Use a foreground migration command in a dedicated Type=oneshot unit that propagates its exit status, with RemainAfterExit=true; order and require the API after that successful completion.
- **Confidence:** High
- **Found by:** Concurrency & State (`GPT-6 via Codex`)
- **First seen:** 2026-10-02 on branch `mihir/feat/chezmoi-home-manager` at `6fbab0f`
- **Last seen:** 2026-10-02 on branch `mihir/feat/chezmoi-home-manager` at `6fbab0f`
- **Severity:** Important
