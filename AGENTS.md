# AGENTS Instructions

Project-specific guidance for AI agents working on nix-config.

**Important**: See `.ai/AGENTS_GLOBAL.md` for general guidelines, AI transparency requirements, and work logging policies.

This repository is a NixOS homelab configuration using Nix flakes. The primary focus is on:

- Nix module organization and syntax
- Flake validation and dependency management
- Container service configurations and orchestration
- System and service module organization

**Note**: This is configuration management, not traditional software development. No unit tests or builds in the traditional sense—validation is via `nix flake check`.

## Quick Start

1. Run `just check` to validate the flake before making changes
2. All tools available automatically via `direnv`
3. Zed is the primary editor (extensions auto-installed)

## Build/Deploy/Check Commands

**Always start with**: `just check`

- `just check` - Validate flake syntax and dependencies
- `just deploy` - Deploy to local system (runs check first)
- `just debug` - Deploy locally with verbose trace output
- `just home-lab` - Deploy to remote home-lab host
- `just home-lab-debug` - Remote deploy with verbose output
- `just up` - Update all flake inputs to latest versions
- `just upp i=<input-name>` - Update specific input (e.g., `just upp i=nixpkgs`)
- `just history` - View Nix profile history
- `just clean` - Remove generations older than 7 days
- `just gc` - Garbage collect unused Nix store entries
- `just repl` - Open Nix REPL for experimentation

Available Zed tasks: `compose2nix` (generate podman-compose.nix), `sops` (edit encrypted files)

## Code Style Guidelines

### Formatting & Indentation

- **Formatter**: Alejandra (primary, via `.zed/settings.json`)
- 2-space indentation throughout
- Consistent attribute alignment
- Opening braces on same line: `{` not newline

### Naming Conventions

- **Functions**: camelCase with `mk` prefix for "makers" (e.g., `mkSubdomain`, `mkUrl`, `mkDomain`)
- **Variables/Attributes**: kebab-case or camelCase (e.g., `baseDomain`, `hostName`, `networking.primaryDns`)
- **File names**: kebab-case with `.nix` extension (e.g., `postgresql.nix`, `ssh.nix`, `homepage-dashboard.nix`)

### Imports & Dependencies

- List all imports at the top of modules
- Use relative paths for local imports: `./related-module.nix`
- Reference `config`, `pkgs`, `lib` via module parameters
- Access custom library functions from `nix/mylib/` (auto-imported via flake)
- Import library functions in `let` bindings: `let dmb = config.mylib; in`

### Type Definitions & Options

Use `lib.mkOption` with explicit types for module options:

```nix
myOption = lib.mkOption {
  type = lib.types.str;                    # Required: specify type
  default = "value";                        # Provide sensible defaults
  description = "Clear description here.";  # Always document
};
```

Common types: `str`, `int`, `bool`, `path`, `port`, `attrs`, `listOf`, `nullOr`

### Error Handling & Validation

- Use `assert` statements with descriptive messages
- Example: `assert config.networking.baseDomain != null; "baseDomain must be set";`
- Validate dependent configurations early in module
- Provide helpful context for validation failures
- Document required configuration values in descriptions

## Formatting & Linting Workflow

### Pre-Commit Hooks (Automatic on Commit)

Defined in `.pre-commit-config.yaml`:

- **ggshield**: Detects secrets (API keys, tokens, credentials)
- **conventional-pre-commit**: Validates commit message format
- **cspell**: Spell checking on file contents and commit messages
- **check-merge-conflict**: Prevents merge conflict markers

### Prettier + MegaLinter

- **Prettier** (`.prettierrc.json`): Formats JSON, YAML, TOML, Markdown (2-space indentation)
- **MegaLinter** (`.mega-linter.yml`): Runs on PR/push to `main`, multi-language linting with auto-fixes

### Workflow

1. Edit Nix files (Alejandra auto-formats on save in Zed)
2. Run `just check` to validate flake
3. Commit changes (pre-commit hooks run automatically)
4. If hooks fail: Fix issues, stage, and commit again
5. Push to trigger MegaLinter comprehensive checks

## Commit Message Format

Use Conventional Commits: `<type>(<scope>): <description>`

### Valid Types

`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`

### Valid Scopes

acme, authentik, caddy, cog, cspell, devshell, disko, domain, features, flake, git, homepage-dashboard, hosts, hosts/home-lab, hosts/test-bed, justfile, megalinter, nginx, nix-cmds, packages, pangolin, peertube, pgadmin, pre-commit, radicale, rclone, scalpel, secrets, services, shell, sops, variables, vscode, zed

### Examples

- `feat(services): add navidrome service configuration`
- `fix(hosts/home-lab): correct networking settings`
- `docs: update deployment instructions`
- `chore(cspell): add technical terms to dictionary`
- `ci(megalinter): update linter configuration`

Note: Scope can be omitted for documentation-only changes: `docs: update README`

## Editor Configuration

### Zed (Primary Editor)

**Auto-Installed Extensions** (`.zed/settings.json`):
- `cspell`, `nix`, `just`, `deno`, `markdownlint`

**Nix Formatter**: Primary `alejandra` (fallbacks: `nil`, `nixd`)

**Custom Tasks** (`.zed/tasks.json`):
- `compose2nix` - Convert docker-compose.yml to podman-compose.nix
- `sops` - Edit encrypted SOPS files

### VSCode (Secondary Reference)

Configuration in `.vscode/` for cross-editor support (Zed recommended)

## File Structure & Key Locations

### Nix Modules (`nix/`)
- `nix/hosts/home-lab/` - Primary homelab configuration
- `nix/hosts/test-bed/` - Test environment
- `nix/modules/services/` - NixOS service configurations
- `nix/modules/container-services/` - Podman/Docker definitions
- `nix/modules/features/` - Feature toggles (SSH, git, direnv, etc.)
- `nix/modules/shell/` - Shell setup (zsh, zimfw, aliases)
- `nix/mylib/` - Custom library functions

### Root Configuration
- `flake.nix` - Flake definition and inputs
- `justfile` - Management commands
- `.pre-commit-config.yaml` - Pre-commit hooks
- `.cspell.json` - Spell checking configuration
- `.prettierrc.json` - Prettier formatting
- `.mega-linter.yml` - MegaLinter configuration

### Documentation
- `.ai/AGENTS_GLOBAL.md` - Global agent guidelines
- `.ai/logs/` - AI work logs (create daily files as needed)
