# AGENTS Instructions

Project-specific guidance for AI agents working on nix-config.

## MANDATORY: Action Logging

> **This is non-negotiable. Log before you start, log as you work, log when you finish.**

Every AI session MUST produce a log entry in `.agents/logs/YYYY-MM-DD.md`. This is not optional documentation — it is a **required action**, executed by the agent itself, not left to the human.

### Procedure

**Step 1 — Before touching any file:**

```bash
# Get today's filename
date '+%Y-%m-%d'   # e.g. 2026-03-16
```

- If `.agents/logs/YYYY-MM-DD.md` does not exist → create it with the header:
  ```markdown
  # AI Work Log - YYYY-MM-DD
  ```
- If it already exists → append to it (do NOT overwrite)

**Step 2 — Open your entry immediately:**

Append a new entry header with the current ISO timestamp and the user's prompt:

```markdown
## HH:MM:SS+TZ

### Prompt

> <exact user request, verbatim or faithfully paraphrased>

### Model

<model name and version> via <editor/tool> (e.g. Claude Sonnet 4.6 via opencode)
```

**Step 3 — Log each action as you perform it:**

After every meaningful action, append to the `### Actions` section. Do not batch everything at the end — if the session is interrupted, the log must still reflect what was done.

**Step 4 — Close the entry when done:**

Append the `### Outcome` section:

```markdown
### Outcome

<✅ / ⚠️ / ❌> <one-line summary of what was achieved or what failed>
```

---

### Log Format (AI-authored)

```markdown
## 2026-03-16T20:15:00+11:00

### Prompt

> Add tool-runner skill with Bun/Node fallback chains

### Model

Claude Sonnet 4.6 via opencode

### Actions

- Created `.agents/skills/tool-runner/SKILL.md` — main skill documentation with fallback patterns
- Created `.agents/skills/tool-runner/assets/tool-runner.sh` — standalone bash script for tool selection
- Created `.agents/skills/tool-runner/assets/validate-tools.sh` — validation script for tool availability
- Modified `AGENTS.md` — registered skill in Project Skills table
- Decision: used `command -v` over `which` for POSIX compliance across Linux/macOS/Windows

### Outcome

✅ Skill created and committed, all pre-commit hooks passed
```

---

### What Counts as a Loggable Action

**Always log:**

- Every file **created** — name, purpose, approximate scope
- Every file **modified** — name, what changed and why
- Every **decision** made — especially when choosing between alternatives
- Every **command run** with a non-trivial outcome (tool installs, test runs, linter results)
- Anything **rejected or changed** from the original approach, and the reason

**Do NOT log:**

- Trivial auto-fixes by pre-commit hooks (formatting, whitespace)
- Reading files for context (unless the read revealed something decision-relevant)
- Intermediate tool calls that produced no output or change

---

### Additional Materials

Place any other relevant documents (prompts, examples, references, generated docs) in the `.agents/` folder.

---

## MANDATORY: AI Co-authored-by Trailer

> **Every commit made with AI assistance MUST include a `Co-authored-by` trailer. No exceptions.**

**Format:**

```txt
Co-authored-by: <Model Name> via <Tool> <noreply@provider-domain>
```

**Provider noreply addresses:**

| Provider                | noreply address         |
| ----------------------- | ----------------------- |
| Anthropic (Claude)      | `noreply@anthropic.com` |
| OpenAI (GPT / o-series) | `noreply@openai.com`    |
| Google (Gemini)         | `noreply@google.com`    |
| Microsoft (Copilot)     | `noreply@microsoft.com` |
| Mistral                 | `noreply@mistral.ai`    |
| Meta (Llama)            | `noreply@meta.com`      |
| xAI (Grok)              | `noreply@x.ai`          |

**Examples:**

```txt
feat(precommit): add spell checking to commit messages

Co-authored-by: Claude Sonnet 4.6 via opencode <noreply@anthropic.com>
```

```txt
fix(cspell): resolve configuration issue

Co-authored-by: GPT-4o via Cursor <noreply@openai.com>
```

**Rules:**

- Use the **exact model name and version** you are running as (e.g. `Claude Sonnet 4.6`, not just `Claude`)
- Use the **tool name** as it is commonly known (e.g. `opencode`, `Cursor`, `Copilot`, `Zed`)
- If the model version is unknown, use the model family name (e.g. `Claude Sonnet`)
- One trailer per AI model involved
- **Never omit this trailer** when the commit was AI-assisted — this is how git history stays honest

## Project Context

- **Project Type**: Project generated from copier-mr-minimal
- **Key Technologies**: pre-commit hooks, MegaLinter, prek
- **Purpose**: Provides a standardized starting point for new projects with quality checks

## General Guidelines

### Communication

- Explain what you're doing and why before making changes
- Ask for clarification when requirements are ambiguous
- Provide context for decisions, especially when multiple approaches exist

### Code Quality

- Follow existing code style and conventions in the project
- Run linters and formatters before committing changes
- Ensure all changes pass pre-commit hooks

### File Operations

- Always check if a file exists before attempting to modify it
- Use appropriate tools to search for files rather than guessing paths
- Preserve file formatting and structure unless explicitly asked to change it

## AI Usage and Transparency

**IMPORTANT**: This project maintains full transparency about AI assistance.

### AI Assistance Guidelines

**AI can help with**:

- Boilerplate code and scaffolding
- Documentation and comments
- Test cases and test data
- Refactoring suggestions
- Bug fixes and debugging
- Code review and optimization suggestions
- Research and best practices

**Human must**:

- Review all AI-generated code thoroughly
- Test all functionality comprehensively
- Make final decisions on architecture and approach
- Approve all changes before committing
- Understand the code (never commit code you don't understand)

**Always**:

- Validate AI suggestions against project architecture (if such a document is present)
- Follow best coding practices and idioms
- Ensure code passes all tests and linters
- Document every action in `.agents/logs/` as described above

**Never**:

- Skip testing because "AI wrote it"
- Forget to write the log entry
- Rely solely on AI for architectural decisions

## Dev Environment Tips

- Use `--help` or `help` subcommand to get help on a command. It can even reveal hints on how to proceed ahead or optimize the number of steps.
- Check tool documentation before asking the user for configuration details

## Linting and Formatting

### MegaLinter

- Configuration is in `.mega-linter.yml`
- Run locally with: `bunx mega-linter-runner`
- Check reports in `megalinter-reports/` directory
- Not all linters need to pass - some are informational

### CSpell (Spell Checking)

- Configuration is in `.cspell.json`
- Add project-specific words to the `words` array
- Don't disable spell checking without good reason
- Both file content and commit messages are spell-checked

### treefmt

- Run `treefmt -vv` before every commit to format all supported file types (markdown, JSON, YAML, etc.)
- Must be run manually — it is not a pre-commit hook

## Commit Messages

### Format

- Follow Conventional Commits format: `<type>(<scope>): <description>` as given here - <https://www.conventionalcommits.org/en/v1.0.0/>
- Valid types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`
- For valid scopes, refer to the `scopes` array in `cog.toml` — it is the source of truth.

### Examples

```txt
feat(precommit): add spell checking to commit messages
fix(cspell): resolve configuration issue
docs: update AGENTS.md with guidelines
chore(cspell): add technical terms to dictionary
```

## Troubleshooting

### Common Issues

**Pre-commit hooks failing on commit:**

- Read the error message — it usually points directly to the fix
- Try to fix the issue and retry the commit; do not skip hooks
- Fix formatting issues first (treefmt, whitespace)
- Then address spell checking and linting

**Spell check failures:**

- Add legitimate technical terms to `.cspell.json` `words` array
- Use proper capitalization for proper nouns
- Don't add obvious typos to the dictionary

**Template syntax errors:**

- Ensure template syntax is valid before committing
- Check for missing closing tags or brackets
- Test template rendering if applicable

### Getting Help

- Review existing configuration files for examples

## Best Practices

### Before Making Changes

1. Understand the current state of the project
2. Check if similar functionality already exists
3. Review relevant configuration files
4. Consider impact on users who will use this template

### When Adding Dependencies

- Prefer tools that don't require heavy installation
- Document installation steps clearly
- Consider cross-platform compatibility
- Update relevant configuration files

### Testing Changes

- Verify the project structure is correct
- Test on a clean environment if possible
- Ensure documentation is updated

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
