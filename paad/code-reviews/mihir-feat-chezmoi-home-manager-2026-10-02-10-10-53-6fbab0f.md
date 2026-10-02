# Agentic Code Review: mihir/feat/chezmoi-home-manager

- **Date:** 2026-10-02 10:10:53 +1000
- **Branch:** mihir/feat/chezmoi-home-manager -> main
- **Commit:** 6fbab0fd4a4c6eed67d7759a889a9f9bafb0c64d
- **Files changed:** 194 | **Lines changed:** +14858 / -2836
- **Diff size category:** Large

## Executive Summary

Verification retained ten branch findings: one critical terminal-permission bypass, eight important functional/security issues, and one acceptance-check suggestion. A pre-existing Honcho migration ordering bug is recorded separately in the backlog. Flake evaluation fails on invalid test-bed VM options, and `cog check` fails on nine commit-scope errors; no fixes, builds, VM boots or deployments were performed.

## Critical Issues

### [C1] Broad sed auto-approval bypasses terminal execution confirmation

- **File:** `nix/modules/home/zed.nix:156`
- **Bug:** The ^sed\\b always_allow rule accepts GNU sed scripts with the e instruction; allow_unsandboxed=true permits that approved command outside the sandbox.
- **Impact:** Untrusted repository/model context can cause arbitrary shell execution as the user's account without confirmation.
- **Suggested fix:** Remove generic sed auto-approval or allow only explicitly constrained invocations that cannot execute programs.
- **Confidence:** High (94%)
- **Found by:** Security A (`GPT-6 via Codex`)
- **Evidence:** Read current Zed settings; harmless sed -n '1e printf VERIFIER_SED_PROBE' /etc/hostname executed. Zed documentation confirms command-string matching and no sed-specific built-in restriction: https://zed.dev/docs/ai/tool-permissions

## Important Issues

### [I1] Test-bed QEMU settings break base flake evaluation

- **File:** `nix/hosts/test-bed/modules/vm.nix:12`
- **Bug:** QEMU sizing and forwarding options are set in the base configuration, which imports qemu-guest.nix rather than qemu-vm.nix. virtualisation.cores does not exist there.
- **Impact:** Flake evaluation/checking and the advertised graphical preview recipes fail before a VM can build.
- **Suggested fix:** Move sizing and forwarding settings to virtualisation.vmVariant.virtualisation; ensure the ordinary host retains any required filesystem/platform configuration.
- **Confidence:** High (100%)
- **Found by:** Logic & Correctness A, Contract & Integration A (`GPT-6 via Codex`)
- **Evidence:** Current module/configuration read. Supplied offline flake check reproduces missing virtualisation.cores; pinned build-vm.nix loads qemu-vm.nix only in vmVariant.

### [I2] Herdr path matching uses the wrong yq CLI

- **File:** `nix/modules/home/files/bin/herdr-open:25`
- **Bug:** The installed Mike Farah yq-go rejects jq-style --arg; the helper suppresses the error and falls back to matching only the directory basename.
- **Impact:** It creates duplicate workspaces for renamed labels or can focus a different project with the same basename.
- **Suggested fix:** Use installed jq for this JSON path lookup or yq-go strenv with an environment-bound directory; prefer exact path identity over basename fallback.
- **Confidence:** High (100%)
- **Found by:** Logic & Correctness A, Error Handling & Edge Cases A, Contract & Integration A (`GPT-6 via Codex`)
- **Evidence:** Read helper, package/mise declarations and misc-config/ Zed callers. Direct unchanged yq --arg invocation returns unknown flag: --arg. Imported helper is absent from main.

### [I3] CSpell refresh can erase the dictionary on failure or concurrent runs

- **File:** `nix/modules/home/files/bin/cspell-refresh-words:51`
- **Bug:** The helper clears the live config before scanning, suppresses every scanner error with || true, and overwrites the words list without transaction protection. A failed scan publishes []; two overlapping clear/scan/write runs can also publish [].
- **Impact:** Saved project words are lost and editor/pre-commit/CI spelling checks regress while the task reports success.
- **Suggested fix:** Hold a per-config lock; scan an isolated temporary config with an empty words list, validate expected CSpell statuses, and atomically publish only a successfully parsed result. Preserve the original on errors.
- **Confidence:** High (100%)
- **Found by:** Logic & Correctness A, Error Handling & Edge Cases A, Concurrency & State A (`GPT-6 via Codex`)
- **Evidence:** Read the entire clear/scan/write sequence and caller task. Zed's allow_concurrent_runs=false does not serialize CLI processes. Both failure and A-scan/B-clear/A-publish/B-scan/B-publish interleavings are confirmed by code; the combined fix addresses both.

### [I4] Repository updater reports success after failed updates

- **File:** `nix/modules/home/shell/functions.nix:94`
- **Bug:** update-repo does not check git pull or updater exit statuses; after failure it continues mutations and finishes with a successful line command.
- **Impact:** Conflicts, authentication errors or dependency-update failures are hidden, and later updates can run against a repository whose pull failed.
- **Suggested fix:** Return on failed pull and propagate each updater failure before printing completion.
- **Confidence:** High (95%)
- **Found by:** Error Handling & Edge Cases A (`GPT-6 via Codex`)
- **Evidence:** Read function and zsh setup; no ERR_EXIT or equivalent guard is enabled. Function is newly imported versus main.

### [I5] Preview SSH forwarding exposes the public password outside localhost

- **File:** `nix/hosts/test-bed/modules/vm.nix:19`
- **Bug:** The forwarding entry omits host.address, whose pinned QEMU default is empty/all interfaces. SSH password authentication defaults true; the wheel user has the documented initial password preview.
- **Impact:** Once the intended VM boots, hosts able to reach TCP 2224 can log in with the public password and obtain guest root through sudo. This is independent of the current evaluation blocker.
- **Suggested fix:** Set host.address="127.0.0.1" for the forward; alternatively disable SSH password and keyboard-interactive authentication.
- **Confidence:** High (95%)
- **Found by:** Security A (`GPT-6 via Codex`)
- **Evidence:** Read VM, user-system and configuration modules. Pinned qemu-vm.nix:650-653 and :1276 generate hostfwd=tcp::2224-:22; sshd.nix:547-550 defaults PasswordAuthentication=true. No overriding address/authentication policy is supplied.

### [I6] New Conventional Commits workflow fails on checked-out history

- **File:** `.github/workflows/cocogitto.yml:20`
- **Bug:** The workflow runs cog check across full history but configured scopes exclude logs and package, which occur in that history.
- **Impact:** The added CI check fails on this branch regardless of Nix validation.
- **Suggested fix:** Reconcile accepted scopes with the deliberately checked history, including logs/package, or explicitly restrict and repair the checked commit range.
- **Confidence:** High (100%)
- **Found by:** Logic & Correctness B (`GPT-6 via Codex`)
- **Evidence:** Read workflow and cog.toml; unchanged cog check reports nine errors: eight new docs(logs) commits and historical fix(package). New workflow exposes the historical mismatch.

### [I7] Replacement devshell omits tools still used by repository recipes

- **File:** `nix/devshell.nix:15`
- **Bug:** The new shell removes main's nixos-anywhere and yq-go, while just provision/gen-hw-config invoke nixos-anywhere directly and the bump hook invokes bare yq.
- **Impact:** Clean repository environments cannot provision/discover hardware or complete the version bump without undocumented global commands.
- **Suggested fix:** Restore nixos-anywhere and yq-go to the devshell or explicitly supply their executables at the callers.
- **Confidence:** High (99%)
- **Found by:** Logic & Correctness B, Error Handling & Edge Cases B (`GPT-6 via Codex`)
- **Evidence:** Read old main:flake.nix, current devshell, justfile and cog.toml. No shell package provides these executables; formatter-wrapped yq is not exported as a bare PATH command.

### [I8] Fresh home-lab VM lacks an identity for inherited production secrets

- **File:** `nix/hosts/home-lab/modules/vm.nix:4`
- **Bug:** The fresh VM inherits production services and SOPS files but only reads its newly generated SSH host private key. Encrypted recipients are the admin and production-host identities; no matching identity or test-secret override is provisioned.
- **Impact:** SOPS decryption and secret-dependent services fail on first boot, defeating the requested home-lab service-testing path.
- **Suggested fix:** Provide VM-only encrypted test secrets and a matching runtime-provisioned identity, or explicitly disable secret-dependent services and document the limited preview. Keep production private keys out of the store.
- **Confidence:** High (94%)
- **Found by:** Logic & Correctness B, Error Handling & Edge Cases B, Contract & Integration B, Spec Compliance B (`GPT-6 via Codex`)
- **Evidence:** Read VM, host service imports, SOPS configuration and secrets.yaml recipients. Pinned QEMU default shares the Nix store and exchange directories, not production /etc/ssh. Intent explicitly asks to test home-lab services.

## Suggestions

- [S1] `docs/superpowers/plans/2026-08-29-chezmoi-home-manager-migration.md:1213` — Task 7 explicitly keeps the mise mcfly binary, but completed Task 10 expects a grep for every mcfly mention under nix/ to print clean. Fix: Narrow the grep and spec wording to removed shell-history initialization while retaining the intentionally supported mise binary. Confidence: Medium (79%). Found by: Spec Compliance A (`GPT-6 via Codex`).

## Out of Scope

> **Handoff instructions for any agent processing this report:** The findings below are pre-existing bugs that this branch did not cause or worsen. Do **not** assume they should be fixed on this branch, and do **not** assume they should be skipped. Present them to the user **batched by tier**: one ask for all out-of-scope Critical findings, one for all Important, one for Suggestions. For each tier, the user decides which (if any) to address. When you fix an out-of-scope finding, remove its entry from `paad/code-reviews/backlog.md` by ID.

### Out-of-Scope Critical

None found.

### Out-of-Scope Important

### [OOSI1] Honcho API ordering does not await successful schema migration

- **File:** `nix/modules/nixos/container-services/honcho-memory/default.nix:51`
- **Bug:** After/Requires wait for migration container startup, but its generated unit uses Type=notify and sdnotify=conmon, which reports readiness before Alembic completes. No completion barrier protects API/deriver database access.
- **Impact:** During a fresh boot or schema update, API startup/schema checks or deriver queries can reach an incomplete schema; a migration failure does not block initial startup.
- **Suggested fix:** Use a foreground migration command in a dedicated Type=oneshot unit that propagates its exit status, with RemainAfterExit=true; order and require the API after that successful completion.
- **Confidence:** High (90%)
- **Found by:** Concurrency & State B (`GPT-6 via Codex`)
- **Evidence:** Both supplied/current lock pin nixpkgs e8be7818e19ada32105a8af937a6a473b38167ca. Matching source sets sdnotify=conmon, detached Podman and Type=notify. Main has identical ordering: relocation is cosmetic. Honcho v3.1 Dockerfile runs FastAPI directly; startup validates schema but does not run migrations: https://raw.githubusercontent.com/plastic-labs/honcho/v3.1.0/Dockerfile and https://raw.githubusercontent.com/plastic-labs/honcho/v3.1.0/src/main.py
- **Backlog ID:** `ff4e6912`
- **Backlog status:** new (first logged 2026-10-02)

### Out-of-Scope Suggestions

None found.

## Review Metadata

- **Agents dispatched:** all six lenses across both partitions (12 specialist dispatches), followed by one Verifier.
  - Logic & Correctness: A findings (4); B findings (4)
  - Error Handling & Edge Cases: A findings (3); B findings (2)
  - Contract & Integration: A findings (2); B findings (2)
  - Concurrency & State: A findings (1); B findings (1)
  - Security: A findings (2); B findings (0)
  - Spec Compliance: A findings (1); B findings (1)
- **Partitioning:** A reviewed Home Manager modules, fw16/test-bed hosts and ChezMoi migration docs; B reviewed remaining infrastructure, services, tooling and docs. Four-slot concurrency required dispatch waves; live workers were reused for Security B, Spec B and Verifier after the harness reached its thread limit.
- **Scope:** All 194 committed changed paths against main, plus one-level shared SSH keys, service secret/runtime configuration counterparts and the homepage custom-data file. No separate test suite/infrastructure counterpart was found beyond the changed test-bed VM host and flake checks. Adjacent files traced:
  - `nix/hosts/home-lab/bose-game-home-lab.json` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/acme.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/authentik.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/fjr-default.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/glr-an.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/hermes.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/homepage.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/honcho-memory.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/linkwarden.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/omniroute.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/pangolin.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/postgres.yaml` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/rclone.ini` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/searxng.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/hosts/home-lab/secrets/wireless.env` — one-level shared imports, keys, package or validation counterpart.
  - `nix/keys/ssh-keys.nix` — one-level shared imports, keys, package or validation counterpart.
- **Raw findings:** 23
- **Verified findings:** 11 unique (10 in scope, 1 out of scope)
- **Filtered out:** 12 (3 rejected claims, 9 duplicate reports merged)
- **Out-of-scope findings:** 1 (Critical: 0, Important: 1, Suggestion: 0)
- **Out-of-scope additions:** 0
- **Backlog:** 1 new entry added, 0 re-confirmed; 1 total active.
- **Steering files consulted:** AGENTS.md, CLAUDE.md; legacy path references were treated as stale.
- **Intent sources consulted:** Migration/Blueprint plans and specs, branch commit messages and bodies, recorded VM request, and user-supplied [ChezMoi source](https://github.com/MRDGH2821/dotfiles) at `669aacaf0e881d93eda7c54f811a96f285d8b66f`. This October snapshot may postdate the August migration; later source enhancements were not assumed to be missed requirements.
- **Verifier warnings:** none
- **Validation:** `nix flake check --no-build --offline` fails on missing `virtualisation.cores`; `cog check` reports nine invalid scopes. Read-only yq/sed probes confirm their findings. `just` was unavailable outside the devshell; VM runtime behavior was verified statically. Missing git-agecrypt text conversion prevented decrypted secret diffs; ciphertext and recipient metadata were reviewed.

## Rejected Claims

- **Python repository updates call an unprovided executable:** The migration design explicitly lists uv-upx as an out-of-band dependency (section 3.6/packaging and source-parity exclusions). Its absence from Home Manager/mise is intentional, not an unintended packaging regression. Hidden updater failure is separately verified in update-repo.
- **Home-lab removes KeePassXC without wiring its replacement:** Newer caed174 and df64c98 commit bodies explicitly remove KeePassXC from server profiles and reduce them to common. This supersedes the old desktop comment and prior migration design; no unintentional replacement regression is established.
- **Restore Home Manager KeePassXC import:** Same rejected intentional server configuration simplification claim as Logic B #3; current import absence matches the newer explicit commit intent.
