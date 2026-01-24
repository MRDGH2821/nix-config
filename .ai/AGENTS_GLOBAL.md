# AGENTS Instructions

This file provides guidance for AI coding assistants working with this project.

## Project Context

- **Project Type**: Template repository for minimal project setup
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

### AI-Assisted Work Documentation

**IMPORTANT**: This project maintains full transparency about AI assistance through work logs.

**All AI-assisted work must be documented** in `.ai/logs/YYYY-MM-DD.md` files:

- **Naming format**: `YYYY-MM-DD.md` (e.g., `2024-12-15.md`)
- **Multiple sessions per day**: Append to the existing log file with timestamps
- **Generate timestamps**: Use `date --iso-8601=seconds` or `date '+%Y-%m-%d %H:%M:%S'`

**Each log entry must include**:

1. **Timestamp** - When the work was performed
2. **Request/Prompt** - What initiated the work (user request or task description)
3. **AI Model** - Model name and version (e.g., Claude Sonnet 4.5, GPT-4, etc.)
4. **Provider** - AI provider (e.g., Anthropic, OpenAI)
5. **Work Performed** - Detailed description of what was done
6. **Files Changed** - List of files created/modified with line counts
7. **Nature of Assistance** - Type of help (code generation, documentation, refactoring, debugging, etc.)
8. **Human Involvement** - What decisions were made by humans, how output was reviewed/tested/modified, what was rejected or changed
9. **Testing Status** - Whether code was tested, compilation status, test results

**Example log entry format**:

```markdown
## 2024-12-15 14:30:22+00:00

### Request

User asked to implement GitHub profile fetcher with rate limiting

### AI Model

**Model**: Claude Sonnet 4.5
**Provider**: Anthropic
**Code Editor**: Zed
**Method of Access**: GitHub Copilot

### Work Performed

- Implemented GitHubFetcher struct with async trait
- Added rate limiting using governor crate
- Created comprehensive error handling
- Added unit tests and integration tests

### Files Changed

- `src/social/github.rs` (created, ~250 lines)
- `tests/integration/github_tests.rs` (created, ~80 lines)
- `Cargo.toml` (modified, added governor dependency)

### Nature of Assistance

- Code generation for fetcher implementation
- Test case generation
- Error handling patterns

### Human Involvement

- Reviewed all generated code for correctness
- Modified rate limiting to be more conservative (5 req/min instead of 10)
- Added additional error cases not covered by AI
- Tested with real GitHub API
- Approved final implementation after modifications

### Testing Status

- ✅ Compiled successfully
- ✅ All 12 unit tests passing
- ✅ Integration tests passing with mock API
- ⏳ Manual testing with real API pending
```

**Additional Materials**: Place any other relevant documents (prompts, examples, references, generated docs) in the `.ai` folder

**Commit Message Format**: Reference the work log in commit messages:

```commit
feat(social): implement GitHub profile fetcher

AI-assisted implementation reviewed and tested.
See .ai/logs/2024-12-15.md for details.
```

## AI Usage and Transparency

**IMPORTANT**: This project maintains full transparency about AI assistance.

### Documentation Requirements

All AI-assisted work must be documented as described in the "AI-Assisted Work Documentation" section above. Every AI session requires creating or updating the daily log file in `.ai/logs/YYYY-MM-DD.md`.

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
- Document the AI assistance in `.ai/logs/`
- Include human review notes in the log

**Never**:

- Commit AI-generated code without review
- Use AI-generated code you don't understand
- Skip testing because "AI wrote it"
- Forget to document AI usage
- Rely solely on AI for architectural decisions

## Dev Environment Tips

- Use `--help` or `help` subcommand to get help on a command. It can even reveal hints on how to proceed ahead or optimize the number of steps.
- Check tool documentation before asking the user for configuration details

## Pre-commit Hooks (prek)

### Installation

- Install with `uv tool install prek` and run checks via `prek --all-files`
- Enable the hooks with `prek install --install-hooks` so they run automatically on each commit

### Working with Hooks

- If a pre-commit hook fails, read the error message carefully - it often suggests the fix
- Run `prek --all-files` before committing to catch issues early
- Some hooks auto-fix issues (like formatters); others require manual intervention

## Linting and Formatting

### MegaLinter

- Configuration is in `.mega-linter.yml`
- Run locally with: `npx mega-linter-runner --flavor documentation`
- Check reports in `megalinter-reports/` directory
- Not all linters need to pass - some are informational

### CSpell (Spell Checking)

- Configuration is in `.cspell.json`
- Add project-specific words to the `words` array
- Don't disable spell checking without good reason
- Both file content and commit messages are spell-checked

### Prettier

- Configuration is in `.prettierrc.json`
- Formats markdown, JSON, YAML files
- Auto-fixes on pre-commit

## Commit Messages

### Format

- Follow Conventional Commits format: `<type>(<scope>): <description>` as given here - <https://www.conventionalcommits.org/en/v1.0.0/>
- Valid types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`
- Valid scopes: `zed`, `vscode`, `cspell`, `megalinter`, `precommit`
- For additional scopes, refer `conventional-pre-commit` hook in `.pre-commit-config.yaml`. It has additional scopes and is the source of truth.

### Examples

```commit
feat(precommit): add spell checking to commit messages
fix(cspell): resolve configuration issue
docs: update AGENTS.md with guidelines
chore(cspell): add technical terms to dictionary
```

## Troubleshooting

### Common Issues

**Pre-commit hooks failing on commit:**

- Run `prek --all-files` to see all issues at once
- Fix formatting issues first (Prettier, whitespace)
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

- Most tools support `--help` flag for detailed usage
- Check tool documentation before modifying configurations
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

- Run all pre-commit hooks: `prek --all-files`
- Verify the project structure is correct
- Test on a clean environment if possible
- Ensure documentation is updated
