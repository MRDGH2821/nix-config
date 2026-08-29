# Blueprint Home Manager Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire Blueprint Home Manager for `mr-nix` on `home-lab` and `test-bed`, introduce shared `homeModules.common`, and remove the unused `bose-game` system user — without migrating shell or packages into HM.

**Architecture:** Blueprint discovers `nix/hosts/<host>/users/<user>.nix`. Thin stubs import `flake.modules.home.common` and `flake.modules.home.mr-nix`. NixOS login for `mr-nix` stays in `modules/nixos/vars/mr-nix-user.nix`. No hand-rolled `home-manager.users` unless evaluation requires it.

**Tech Stack:** Nix, Flakes, Numtide Blueprint, Home Manager, NixOS.

**Spec:** [docs/superpowers/specs/2026-08-05-blueprint-home-manager-phase-2-design.md](../specs/2026-08-05-blueprint-home-manager-phase-2-design.md)

## Global Constraints

- Wire-up only: **no** migration of `shell/` or large `home.packages` into HM.
- Users: **`mr-nix` only** — delete all live `bose-game` NixOS config under `nix/`.
- Hosts: both `home-lab` and `test-bed` get `users/mr-nix.nix`.
- Prefer Blueprint discovery; do not list user files in host `configuration.nix`.
- NixOS account fields (groups, shell package, SSH keys) stay in NixOS modules/vars.
- Commits: Conventional Commits; AI-assisted commits include `Co-authored-by: Composer via Cursor <noreply@cursor.com>`.
- Do **not** merge to `main`.
- Success requires `just check` (`nix flake check`) to pass.

## File map

| Path                                                    | Role                                        |
| ------------------------------------------------------- | ------------------------------------------- |
| Create: `nix/modules/home/common.nix`                   | Shared `home.stateVersion`                  |
| Modify: `nix/modules/home/mr-nix.nix`                   | Username only (no duplicate stateVersion)   |
| Create: `nix/hosts/home-lab/users/mr-nix.nix`           | HM stub imports common + mr-nix             |
| Create: `nix/hosts/test-bed/users/mr-nix.nix`           | Same stub                                   |
| Modify: `nix/hosts/home-lab/configuration.nix`          | Remove bose-game user + allowlist           |
| Do not change: `nix/modules/nixos/vars/mr-nix-user.nix` | System user (unless check proves otherwise) |
| Do not change: `nix/modules/nixos/shell/**`             | Still NixOS                                 |

---

### Task 1: Shared home modules

**Files:**

- Create: `nix/modules/home/common.nix`
- Modify: `nix/modules/home/mr-nix.nix`

**Interfaces:**

- Produces: `flake.modules.home.common` / `homeModules.common`
- Produces: `flake.modules.home.mr-nix` / `homeModules.mr-nix` (existing attr kept)
- `common`: `home.stateVersion = "26.05"`
- `mr-nix`: `home.username = "mr-nix"` only

- [ ] **Step 1: Create `nix/modules/home/common.nix`**

```nix
_: {
  home.stateVersion = "26.05";
}
```

If `nix flake check` later fails wrapping (missing `flake` arg), change to `{flake, ...}: { home.stateVersion = "26.05"; }` without using unused `flake`.

- [ ] **Step 2: Rewrite `nix/modules/home/mr-nix.nix`**

Replace entire file with:

```nix
_: {
  home.username = "mr-nix";
}
```

(If Blueprint already injects username from the path and check complains about conflict, remove `home.username` and leave this file as `_:{ }` with a comment, or delete user-only module and import only `common` from stubs — prefer keep `username` unless forced.)

- [ ] **Step 3: Smoke-eval homeModules**

```bash
nix eval .#homeModules --apply 'x: builtins.attrNames x'
```

Expected: list includes `common` and `mr-nix`.

- [ ] **Step 4: Commit**

```bash
git add nix/modules/home/common.nix nix/modules/home/mr-nix.nix
git commit -m "$(cat <<'EOF'
feat(hosts): add shared homeModules common and trim mr-nix

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

(If `hosts` is not a valid cog scope for home modules, use `feat: add shared homeModules common and trim mr-nix` or scope listed in `cog.toml`.)

---

### Task 2: Blueprint user stubs on both hosts

**Files:**

- Create: `nix/hosts/home-lab/users/mr-nix.nix`
- Create: `nix/hosts/test-bed/users/mr-nix.nix`

**Interfaces:**

- Consumes: `flake.modules.home.common`, `flake.modules.home.mr-nix`
- Produces: Blueprint user configs (expect names like `mr-nix@home-lab` / `mr-nix@test-bed` under `homeConfigurations` if Blueprint exports that)

- [ ] **Step 1: Create both stub files** (identical body):

```nix
{flake, ...}: {
  imports = [
    flake.modules.home.common
    flake.modules.home.mr-nix
  ];
}
```

- [ ] **Step 2: Smoke-eval hosts still exist**

```bash
nix eval .#nixosConfigurations.home-lab.config.networking.hostName
nix eval .#nixosConfigurations.test-bed.config.networking.hostName
```

Expected: `"home-lab"` and `"test-bed"`.

- [ ] **Step 3: Inspect HM flake outputs**

```bash
nix eval .#homeConfigurations --apply 'x: builtins.attrNames x' 2>&1 || true
nix flake show 2>&1 | head -80
```

Expected: some user@host (or Blueprint-equivalent) entries, **or** document which attr Blueprint uses if name differs. If check fails requiring home directory / stateVersion, fix in Task 1 modules (not by hand-writing HM in configuration.nix unless last resort).

- [ ] **Step 4: Commit**

```bash
git add nix/hosts/home-lab/users/mr-nix.nix nix/hosts/test-bed/users/mr-nix.nix
git commit -m "$(cat <<'EOF'
feat(hosts): add Blueprint mr-nix Home Manager users

Wire home-lab and test-bed users via hosts/*/users stubs.

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

---

### Task 3: Delete `bose-game` from home-lab

**Files:**

- Modify: `nix/hosts/home-lab/configuration.nix`
- Grep: `nix/` for `bose-game`

**Interfaces:**

- Removes: `nix.settings.allowed-users` entry `"bose-game"`
- Removes: entire `users.users.bose-game` attrset
- Keeps: `allowed-users` with `"@wheel"`; `mr-nix` still from vars

- [ ] **Step 1: Edit `configuration.nix`**

Remove lines that allow and define `bose-game`. Resulting relevant fragments:

```nix
  nix.settings.allowed-users = [
    "@wheel"
  ];
  # ... no users.users.bose-game ...
```

Delete the whole block:

```nix
  users.users.bose-game = {
    extraGroups = [ ... ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [ ... ];
  };
```

- [ ] **Step 2: Grep live nix**

```bash
rg -n 'bose-game' nix/ || true
```

Expected: no matches under `nix/` (docs/logs outside `nix/` may still mention it).

- [ ] **Step 3: Eval host still builds conceptually**

```bash
nix eval .#nixosConfigurations.home-lab.config.users.users --apply 'u: builtins.hasAttr "bose-game" u'
```

Expected: `false`.

```bash
nix eval .#nixosConfigurations.home-lab.config.users.users.mr-nix.isNormalUser
```

Expected: `true` (from vars).

- [ ] **Step 4: Commit**

```bash
git add nix/hosts/home-lab/configuration.nix
git commit -m "$(cat <<'EOF'
fix(hosts/home-lab): remove unused bose-game system user

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

---

### Task 4: Full check and hygiene

**Files:** only residual fixes if needed

- [ ] **Step 1: Run full check**

```bash
just check
```

Expected: exit 0. If host closures rebuild slowly, allow completion; formatting/pre-commit and host checks must pass.

- [ ] **Step 2: Confirm constraints**

```bash
rg -n 'bose-game' nix/ || true
rg -n 'home-manager\.users' nix/hosts || true
test -d nix/modules/nixos/shell && echo "shell still nixos"
```

Expected: no `bose-game`; no manual `home-manager.users` in hosts (unless forced and documented); shell tree still present.

- [ ] **Step 3: Commit residual fixes if any**

Only if Step 1–2 required more edits; otherwise no empty commit.

```bash
git commit -m "$(cat <<'EOF'
fix(hosts): complete Phase 2 Home Manager wire-up

Co-authored-by: Composer via Cursor <noreply@cursor.com>
EOF
)"
```

---

## Spec coverage checklist

| Spec requirement                 | Task                           |
| -------------------------------- | ------------------------------ |
| `common.nix` + trim `mr-nix.nix` | Task 1                         |
| users stubs on both hosts        | Task 2                         |
| Blueprint HM discovery           | Task 2                         |
| Delete bose-game                 | Task 3                         |
| just check                       | Task 4                         |
| No shell migration               | All tasks (do not edit shell/) |
| No main merge                    | Process                        |

## Phase 2b reminder (not this plan)

Migrate NixOS `shell/` into Home Manager for `mr-nix` later.
