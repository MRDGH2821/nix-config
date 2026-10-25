# Isolated Homelab Testing Implementation Plan

> **For agentic workers:** Use executing-plans or subagent-driven-development. Keep production deployment untouched; record implementation and verification in `.agents/logs/2026-10-25.md`.

**Goal:** Provide a safe local VM of the real homelab and repeatable NixOS integration tests, without production credentials, data, or outbound access.

**Architecture:** Reuse the existing home-lab host/service modules. A test-only NixOS module supplies disposable credentials, data, local certificates, offline container images, and isolation. The interactive VM and automated test consume that same module. Automated tests use a separate client guest rather than treating localhost responses as proof of routing/firewall behavior.

**Tech Stack:** Existing pinned nixpkgs, QEMU/KVM, sops-nix, Podman, `pkgs.testers.runNixOSTest`, Blueprint checks, just.

**Spec:** User-approved recommendation in this conversation and the selected coverage: “Core workflows plus full-stack startup.” Boot all safely testable services; deeply test PostgreSQL, Forgejo, proxy/authentication, container migration ordering, and persistence. Other apps receive startup/health coverage, not claims of full application correctness. User-directed exception: Linkwarden and OmniRoute remain configured in the sandbox but have no automated unit or endpoint assertions.

## Global Constraints

- Never run deploy/provision commands, SSH to production, copy production keys/databases, or use real API credentials.
- Production `home-lab` toplevel remains unchanged by sandbox overrides. Exception approved after VM reproduction: correct the shared PostgreSQL/pgvector version mismatch and Honcho extension initialization, without deployment or application superuser privileges.
- Use `homelab.test` and test-only users/secrets. Fixtures are deliberately public and never reusable production credentials.
- Restrict guest egress and host forwarding to loopback; no production directory or device passthrough.
- Preload OCI images from fixed-output Nix fetches; do not permit guest image pulls as an isolation workaround.
- Keep runners, cloud mounts, Hermes/paid AI calls, public ACME, and externally enrolled networking inactive unless backed by a local fixture. Document their exclusions.
- Disabled production apps stay disabled. Do not silently remove enabled services to turn failures green.
- Do not alter production firewall policy, database authentication, or application behavior merely to obtain green test results. Report genuine defects separately.
- No commits without user approval. Preserve unrelated work.

## Review Focus

1. A VM must not contact production even when a service restarts or credentials accidentally become available.
2. Secrets/templates must resolve to test fixtures; production host SSH keys and recipients must not be needed.
3. Offline container startup must not silently pull mutable tags or skip migration execution.
4. A test-only proxy route must be identified as a fixture, not proof of production database-held Pangolin routes or SSO enrollment.
5. Reboot/activation and backup restoration must verify actual persisted values, not only service activity; these checks do not imply database downgrade safety.

## Task 1: Shared safe sandbox

**Files:** Create `nix/tests/home-lab/sandbox.nix` and required fixture files beneath `nix/tests/home-lab/`; modify `nix/hosts/home-lab/modules/vm.nix` only to consume the sandbox and apply VM-specific settings.

**Interfaces:** `sandbox.nix` is an ordinary NixOS module usable both by `virtualisation.vmVariant.imports` and a NixOS test node. It preserves real service modules, supplies test SOPS data, substitutes external dependencies, and preloads container images.

- [ ] Capture the current production toplevel derivation and evaluate safety properties of the unmodified VM, observing the missing isolation.
- [ ] Add test-only credentials and certificates; preserve service ownership and template semantics. Never inspect decrypted production secret contents.
- [ ] Import the shared sandbox into the existing home-lab VM variant. Configure restricted networking, loopback forwarding, disposable storage, and local test names.
- [ ] Fetch/preload every enabled OCI image with a pinned digest and Nix hash. Ensure the foreground Honcho migration command uses the preloaded image.
- [ ] Evaluate production and sandbox settings. Sandbox-only edits must preserve the production derivation; the explicitly approved PostgreSQL/Honcho correction is tracked separately.

## Task 2: Native integration test

**Files:** Create `nix/checks/home-lab-integration.nix`; use helpers beneath `nix/tests/home-lab/` only where needed.

**Consumes:** Shared sandbox module and existing real home-lab configuration modules, with Blueprint `flake`/`inputs` arguments supplied explicitly.

**Produces:** `checks.x86_64-linux.home-lab-integration` and its interactive test driver. Other supported systems must not be assigned an incompatible x86_64 VM derivation.

- [ ] Define server and client guests. Reuse the real host/service configuration plus sandbox, not a hand-written replacement stack.
- [ ] Assert egress isolation and client access to intended public endpoints. Test firewall behavior against the actual configured policy; flag an exposed database rather than misrepresenting it as private.
- [ ] Check enabled application units and meaningful health endpoints with bounded waits; keep external-integration exclusions explicit.
- [ ] Create a disposable Forgejo user/repository, exercise authenticated and unauthorized requests through a test-only proxy route, and verify persisted application data.
- [ ] Exercise real PostgreSQL queries and backup/restore into a disposable database. Verify the restored value.
- [ ] Verify successful Honcho migration before dependent API/deriver readiness, and failure propagation when a migration actually fails.
- [ ] Reboot the server and verify persisted data and recovered endpoints. Exercise candidate activation inside the guest without touching host system profiles.
- [ ] Run the integration test and inspect failures. Correct harness defects; report production defects without disabling their assertions.

## Task 3: Commands, documentation, and verification

**Files:** Modify `justfile` and `README.md`; append required action logs. Fix only spelling entries needed for the existing baseline check, preserving unrelated configuration.

**Interfaces:** Add `just home-lab-build` for a build-only production closure and `just home-lab-test` for the integration check; retain `home-lab-vm` and `home-lab-vm-run` with safe sandbox behavior. No test recipe depends on deploy/provision recipes or `TARGET_HOST`.

- [ ] Add the build/test recipes and document local endpoints, deliberately public test credentials, storage lifecycle, and precise coverage/exclusions.
- [ ] Document an old-to-candidate upgrade rehearsal using an explicitly selected known-good revision and disposable VM state. Do not pretend a same-version reboot tests historical schema migrations.
- [ ] Run the real VM/integration path, formatting checks, and targeted Nix validation after edits settle. Record actual results and missing prerequisites.
- [ ] Obtain an independent review focused on isolation, fixture leakage, real behavior assertions, and production invariance; fix consequential findings.
- [ ] Finish with commands the user can run, observed test results, and hardware/external-integration/production-data coverage limits.
