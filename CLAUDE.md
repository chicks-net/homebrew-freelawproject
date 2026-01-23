# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a Homebrew tap that provides formulas for installing Free Law Project software. Currently includes:

- **x-ray** - A Python CLI tool for detecting bad redactions in PDF documents (finds text underneath black rectangles that don't actually obscure content)

## Development Workflow

This repo uses `just` (command runner) for all development tasks. The workflow is entirely command-line based using `just` and the GitHub CLI (`gh`).

### Standard development cycle

1. `just branch <name>` - Create a new feature branch (format: `$USER/YYYY-MM-DD-<name>`)
2. Make changes and commit (last commit message becomes PR title)
3. `just pr` - Create PR, push changes, and watch checks (waits 8s for GitHub API)
4. `just merge` - Squash merge PR, delete branch, return to main, and pull latest
5. `just sync` - Return to main branch and pull latest (escape hatch)

### Homebrew formula testing

- `just test-x-ray` - Install x-ray formula from source, run brew tests, audit, and style checks
- `just uninstall-x-ray` - Uninstall the x-ray formula
- `just update-x-ray-resources` - Update Python resource dependencies for the x-ray formula using `brew update-python-resources`

### Additional commands

- `just` or `just list` - Show all available recipes
- `just prweb` - Open current PR in browser
- `just release <version>` - Create a GitHub release with auto-generated notes
- `just compliance_check` - Run custom repo compliance checks
- `just shellcheck` - Run shellcheck on all bash scripts in just recipes
- `just cue-verify` - Validate `.repo.toml` structure and flag configuration against CUE schema

## Homebrew Formula Architecture

### x-ray formula (`Formula/x-ray.rb`)

The x-ray formula is a Python-based Homebrew formula that:

- Depends on `python@3.14` and `pymupdf` (PyMuPDF for PDF processing)
- Uses Homebrew's `virtualenv_create` to create an isolated Python environment
- Installs Python dependencies as `resource` blocks (certifi, charset-normalizer, idna, requests, urllib3)
- Creates a wrapper script at `bin/x-ray` that:
  - Points to the virtualenv's `xray` executable
  - Sets `PYTHONPATH` to include Homebrew's PyMuPDF installation
  - Allows the tool to use Homebrew's pre-built PyMuPDF instead of building from source

### Key formula concepts

- **Resources** - Python package dependencies are declared as `resource` blocks with URLs and SHA256 hashes
- **Virtualenv** - The formula creates an isolated Python environment to avoid conflicts
- **write_env_script** - Creates a wrapper that sets environment variables before running the tool
- **test block** - Verifies the installation by checking the executable exists and can import modules

## Testing Formulas Locally

The `just test-x-ray` recipe:

1. Taps this repository to `$(brew --repository)/Library/Taps/chicks-net/homebrew-freelawproject`
2. Copies `Formula/x-ray.rb` to the tap directory (overwrites if different)
3. Runs `brew install x-ray` to install from source
4. Verifies the executable exists at `$(brew --prefix)/bin/x-ray`
5. Runs `brew test x-ray` to execute the formula's test block
6. Runs `brew audit --strict x-ray` to check for formula issues
7. Runs `brew style x-ray` to check Ruby style compliance

## Repository Configuration

### .repo.toml structure

The `.repo.toml` file configures repository metadata and feature flags:

- `[about]` - Description and license
- `[urls]` - Git SSH and web URLs (currently points to template-repo, should be updated)
- `[flags]` - Feature flags for AI integrations (claude, claude-review, copilot-review)

### CUE validation

The `just cue-verify` recipe validates `.repo.toml` in two stages:

1. **Structure validation** - Uses CUE schema in `docs/repo-toml.cue` to validate TOML structure and types
2. **Flag verification** - Checks that enabled feature flags match actual repository configuration:
   - If `claude` flag is true, requires `.github/workflows/claude.yml` and `claude-code-review.yml`
   - If `claude-review` flag is true, requires `claude-code-review.yml` and `.just/gh-process.just`
   - If `copilot-review` flag is true, verifies org has GitHub Copilot via API

## Modular justfile Structure

The main `justfile` imports five modules:

- `.just/compliance.just` - Custom compliance checks for GitHub community standards
- `.just/gh-process.just` - Git/GitHub workflow automation (PR lifecycle)
- `.just/pr-hook.just` - Optional pre-PR hooks for project-specific automation
- `.just/shellcheck.just` - Shellcheck linting for bash scripts in just recipes
- `.just/cue-verify.just` - CUE validation for `.repo.toml`

## GitHub Actions

Five workflows run on PRs and pushes to main:

- **markdownlint** - Enforces markdown standards using `markdownlint-cli2`
- **checkov** - Security scanning for GitHub Actions workflows
- **actionlint** - Lints GitHub Actions workflow files
- **auto-assign** - Automatically assigns issues/PRs to `chicks-net`
- **cue-verify** - Validates `.repo.toml` structure and flags

## Important Implementation Notes

- The x-ray formula uses `write_env_script` to create a wrapper that sets `PYTHONPATH` to include Homebrew's PyMuPDF installation
- Python resources must be updated manually using `just update-x-ray-resources` when dependencies change
- The formula depends on `python@3.14` specifically (not just any Python 3)
- The test recipe copies the formula to the tap directory before installing to test from the working copy
- All git commands in `.just/gh-process.just` use standard git (no aliases required)
- PR checks poll every 5 seconds for faster feedback
