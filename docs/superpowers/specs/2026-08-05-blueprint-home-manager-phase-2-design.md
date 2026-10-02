# Blueprint Home Manager Phase 2 Design Specification

- **Date**: 2026-08-05
- **Branch**: `refactor/blueprint` (implementation may use a feature branch)
- **Depends on**: [Blueprint simplify (Phase 1)](./2026-08-05-blueprint-simplify-design.md)
- **Docs**: [Blueprint folder structure — users](https://numtide.github.io/blueprint/main/getting-started/folder_structure/)

## 1. Overview

Phase 1 delivered Blueprint-native NixOS hosts and modules. Home Manager is only present as a flake input and a minimal `homeModules.mr-nix` (`username` + `stateVersion`). Blueprint never wires HM because there are no `hosts/*/users/` entries and no flake `homeConfigurations`.

**Phase 2 goal:** enable Blueprint Home Manager for the interactive account `mr-nix` on both hosts with shared home modules, and remove the unused `bose-game` system user. **Wire-up only** — do not migrate shell, packages, or desktop config into HM yet.

### 1.1 Decisions

| Topic            | Choice                                                                                           |
| ---------------- | ------------------------------------------------------------------------------------------------ |
| Users            | `mr-nix` only (delete `bose-game`)                                                               |
| Hosts            | `home-lab` + `test-bed` both get `users/mr-nix.nix`                                              |
| Content depth    | Wire-up only (no shell/`home.packages` migration)                                                |
| Module shape     | `modules/home/common.nix` + `modules/home/mr-nix.nix`                                            |
| Integration      | Blueprint thin stubs (`Approach 1`) — no hand-rolled `home-manager.users` unless check forces it |
| Account boundary | NixOS `users.users.mr-nix` stays in `vars/mr-nix-user.nix`; HM is separate                       |

### 1.2 Success criteria

- `hosts/home-lab/users/mr-nix.nix` and `hosts/test-bed/users/mr-nix.nix` exist
- `modules/home/common.nix` and updated `modules/home/mr-nix.nix` export as `homeModules`
- No `bose-game` NixOS user, allowlist entry, or home/user module under `nix/`
- Blueprint wires HM into the NixOS hosts that define users
- Flake exposes HM-related outputs (e.g. `homeConfigurations` / user@host names per Blueprint)
- `just check` (`nix flake check`) passes
- No Phase 2b shell migration; not merged to `main` as part of this workstream

### 1.3 Non-goals (Phase 2b / later)

- Move `shell/` (zsh, zimfw, aliases, bat, zoxide, …) into Home Manager
- Large `home.packages` / desktop / dotfile content
- Manual non-Blueprint HM wiring as the primary path
- New interactive accounts beyond `mr-nix`

---

## 2. Target layout

```text
nix/
  modules/home/
    common.nix          # NEW — shared HM defaults (e.g. stateVersion)
    mr-nix.nix          # UPDATE — mr-nix-only attrs; no duplication of common
  hosts/
    home-lab/
      configuration.nix # REMOVE bose-game user + allowlist entry
      users/
        mr-nix.nix      # NEW — imports flake.modules.home.common + mr-nix
    test-bed/
      users/
        mr-nix.nix      # NEW — same pattern
```

No `modules/home/bose-game.nix`. No `hosts/*/users/bose-game.nix`.

---

## 3. Module shapes

### 3.1 `modules/home/common.nix`

Blueprint may wrap with `{ flake, inputs, ... }` if needed; body is standard HM:

```nix
_: {
  home.stateVersion = "26.05";
}
```

Single source for `stateVersion` used by all HM users in this phase.

### 3.2 `modules/home/mr-nix.nix`

```nix
_: {
  home.username = "mr-nix";
}
```

Do **not** redeclare `stateVersion` if `common` already sets it. Username may be redundant if Blueprint sets it from the path; keep if evaluation or docs clarity benefits, drop if Blueprint already provides it cleanly (confirm during implement).

### 3.3 Host stubs

```nix
# hosts/home-lab/users/mr-nix.nix
# hosts/test-bed/users/mr-nix.nix
{ flake, ... }: {
  imports = [
    flake.modules.home.common
    flake.modules.home.mr-nix
  ];
}
```

File form (`users/<name>.nix`) — not directory form — per Approach 1.

Host `configuration.nix` files do **not** list these stubs: Blueprint discovers them under `hosts/<host>/users/`.

---

## 4. Delete `bose-game`

In `nix/hosts/home-lab/configuration.nix`:

1. Remove `"bose-game"` from `nix.settings.allowed-users` (keep `@wheel`; `mr-nix` remains allowed via `modules/nixos/vars/mr-nix-user.nix`).
2. Remove the entire `users.users.bose-game = { ... };` block (including its SSH key).

Grep `nix/` for remaining `bose-game` (except historical docs under `docs/` / logs) and clear stragglers if any.

**Deploy note:** that interactive login is retired; operators use `mr-nix` (and any remaining service/system users).

---

## 5. Blueprint / home-manager expectations

- Flake already has `home-manager` input in `flake.nix`.
- Defining `hosts/<host>/users/<user>.nix` should:
  - Import home-manager into the NixOS configuration for that host
  - Produce standalone home config outputs (naming is Blueprint-defined; verify with `nix flake show` / attr names during implement)
- Prefer not setting `home-manager.users…` manually in `configuration.nix` unless check fails without it.

NixOS login identity for `mr-nix` remains `modules/nixos/vars/mr-nix-user.nix` (groups, shell, authorized keys). HM Phase 2 does not move those fields.

---

## 6. Implementation order

1. Add `modules/home/common.nix`; adjust `mr-nix.nix` for shared `stateVersion`
2. Add both `users/mr-nix.nix` stubs
3. Delete `bose-game` from home-lab configuration; grep cleanup
4. Run `just check`; smoke-eval `homeModules` and any `homeConfigurations` attrs
5. Commit with Conventional Commits + AI co-authored trailer as required by the project
6. Implementation plan (separate step after this design is reviewed) may split further tasks

---

## 7. Verification

| Check                    | Expectation                           |
| ------------------------ | ------------------------------------- |
| `just check`             | Pass                                  |
| `homeModules` attrNames  | Includes at least `common`, `mr-nix`  |
| Hosts with users         | `home-lab`, `test-bed` still evaluate |
| `bose-game` under `nix/` | No live config (docs/logs exempt)     |
| No shell HM move         | `shell/` still NixOS modules          |

Optional:

```bash
nix eval .#homeModules --apply 'x: builtins.attrNames x'
nix flake show  # inspect homeConfigurations if listed
```

---

## 8. Risks and mitigations

| Risk                                              | Mitigation                                                              |
| ------------------------------------------------- | ----------------------------------------------------------------------- |
| Blueprint user discovery naming differs from docs | Implement against current Blueprint + flake; fix names if attrs missing |
| Double-defined `home.username` / `stateVersion`   | Prefer common for version; username only where needed                   |
| `_module` / wrap issues on home modules           | Use same `{ flake, ... }` style as other shared modules if required     |
| Deleting `bose-game` breaks assumed deploy paths  | Document in commit; use `mr-nix`                                        |
| Circular flake / module eval                      | Keep stubs thin; no heavy imports in user files                         |

---

## 9. Relationship to Phase 1

Phase 1: Blueprint-native NixOS, `flake.lib` barrels, rclone module, domain helpers, vars under `modules/nixos`.  
Phase 2: Home Manager discovery only + remove unused user.  
Phase 2b (not this doc): migrate user environment from NixOS `shell/` into HM.

---

## 10. Spec self-review notes

- No open TBD on scope: wire-up, mr-nix only, delete bose-game, Approach 1 thin stubs.
- Consistency: host matrix and module tree reject bose-game throughout.
- Scope is one implementation plan sized for a small change set.
