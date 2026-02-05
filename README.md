# homebrew-freelawproject

![GitHub Issues](https://img.shields.io/github/issues/chicks-net/homebrew-freelawproject)
![GitHub Pull Requests](https://img.shields.io/github/issues-pr/chicks-net/homebrew-freelawproject)
![GitHub License](https://img.shields.io/github/license/chicks-net/homebrew-freelawproject)
![GitHub watchers](https://img.shields.io/github/watchers/chicks-net/homebrew-freelawproject)

Install [software from the Free Law Project](https://github.com/freelawproject) with brew/homebrew

## Status

Please test it out -- feedback is welcomed.

Hopefully this will eventually [get moved into Free Law Project's github org](docs/migration_todos.md).

## Installation

First, tap this repository:

```bash
brew tap chicks-net/freelawproject
```

Then install any of the available formulas below.

## Available Formulas

### x-ray

A Python library and CLI tool for finding bad redactions in PDF documents. Detects when PDFs have inadequate redactions (like black rectangles drawn over text) that don't actually obscure the underlying content.

**Features:**

- Locates rectangles in PDF documents
- Finds text in those locations
- Analyzes whether rectangles are uniformly colored (indicating poor redactions)
- Returns JSON output with bounding boxes and underlying text
- Accepts local files, URLs, or bytes objects

**Installation:**

```bash
brew install x-ray
```

**Usage:**

```bash
# Check a local PDF file
x-ray path/to/document.pdf

# Check a PDF from a URL
x-ray https://example.com/document.pdf
```

**Requirements:**

- Python 3.10 or later
- PyMuPDF for PDF processing

## Automated Updates

The x-ray formula is automatically updated when new versions are released upstream by the Free Law Project. Here's how it works:

**Automatic Detection:**

- A GitHub Actions workflow runs twice daily (6 AM and 6 PM UTC)
- The workflow checks for new releases via the GitHub API
- When a new version is detected, it automatically creates a pull request

**Review and Merge:**

- The automation creates a PR with updated formula, SHA256 hash, and Python dependencies
- All existing tests run automatically on the PR
- A maintainer reviews and merges the PR manually (no auto-merge)

**Manual Updates:**

If you need to update the formula manually or test a specific version:

```bash
# Update to the latest version
just autoupdate-x-ray

# Update to a specific version
just update-x-ray-to 0.3.6
```

After running either command:

1. Review the changes: `git diff Formula/x-ray.rb`
2. Test the formula: `just test-x-ray`
3. Create a PR: `just branch update-x-ray && git add Formula/x-ray.rb && git commit && just pr`

**Troubleshooting:**

If the automation fails, it will create a GitHub issue with error details and recovery steps. You can always fall back to manual updates using the commands above.

## Contributing

- [Code of Conduct](.github/CODE_OF_CONDUCT.md)
- [Contributing Guide](.github/CONTRIBUTING.md) includes a step-by-step guide to our
  [development process](.github/CONTRIBUTING.md#development-process).

## Support & Security

- [Getting Support](.github/SUPPORT.md)
- [Security Policy](.github/SECURITY.md)
