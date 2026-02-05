# Scripts Directory

This directory contains automation scripts for maintaining the Homebrew tap.

## update-x-ray.sh

A bash script that automates updating the x-ray Homebrew formula to a new version.

### Purpose

The script handles the complete update process for the x-ray formula:

1. Detects the current version in `Formula/x-ray.rb`
2. Fetches the specified version (or latest) from GitHub
3. Downloads the tarball and calculates SHA256 hash
4. Updates the formula file with new version URL and SHA256
5. Runs `brew update-python-resources` to refresh Python dependencies
6. Shows a diff of all changes made

### Usage

**Update to latest version:**

```bash
./scripts/update-x-ray.sh
```

**Update to specific version:**

```bash
./scripts/update-x-ray.sh 0.3.6
```

Or with 'v' prefix:

```bash
./scripts/update-x-ray.sh v0.3.6
```

**Via just recipes (recommended):**

```bash
# Update to latest
just autoupdate-x-ray

# Update to specific version
just update-x-ray-to 0.3.6
```

### How It Works

The script performs these steps:

1. **Dependency Check** - Verifies required commands are available (`curl`, `jq`, `brew`)
2. **Version Detection** - Extracts current version from formula file using grep/sed
3. **Target Version** - Either uses provided version argument or fetches latest from GitHub API
4. **Comparison** - Exits early if formula is already at target version
5. **Tarball Download** - Downloads tarball from GitHub and pipes to `shasum -a 256`
6. **Formula Update** - Uses `sed` to update URL and SHA256 in formula file (creates backup first)
7. **Python Resources** - Runs `brew update-python-resources` to update dependency hashes
8. **Diff Display** - Shows `git diff` of changes for review

### Requirements

- `curl` - For downloading tarballs and calling GitHub API
- `jq` - For parsing JSON responses from GitHub API
- `brew` - For running `update-python-resources`
- `bash` - Version 4.0 or later (uses `set -euo pipefail`)

### Error Handling

The script uses `set -euo pipefail` for strict error handling:

- Exits immediately if any command fails
- Exits if undefined variables are referenced
- Propagates errors through pipes

All errors are displayed with color-coded output (red for errors, blue for info, green for success).

### Safety Features

- **Backup** - Creates `Formula/x-ray.rb.backup` before making changes
- **Validation** - Checks that version can be extracted from formula
- **Early Exit** - Skips update if already at target version
- **Clear Output** - Shows diff and next steps after completion

### Failure Recovery

If the script fails:

1. Check the error message for specific issues
2. Restore from backup if needed: `cp Formula/x-ray.rb.backup Formula/x-ray.rb`
3. Verify dependencies are installed: `which curl jq brew`
4. Check GitHub API availability: `curl -I https://api.github.com`
5. Try manual update via Homebrew: `brew bump-formula-pr --url=... --sha256=...`

### Extending for Other Formulas

To adapt this script for other formulas:

1. Update `UPSTREAM_REPO` variable with new repository
2. Update `FORMULA_FILE` variable with new formula path
3. Adjust URL pattern in `update_formula()` if needed
4. Modify resource update command if not using Python

The script is designed to be formula-agnostic where possible, but assumes:

- Formula file is Ruby-based Homebrew formula
- URL follows GitHub archive pattern: `https://github.com/ORG/REPO/archive/refs/tags/vVERSION.tar.gz`
- SHA256 is on line immediately after URL
- Formula uses Python virtualenv with resources

## GitHub Actions Integration

The `update-x-ray.sh` script is called by the `.github/workflows/x-ray-autoupdate.yml` workflow:

- Workflow runs twice daily (6 AM and 6 PM UTC) via cron schedule
- Can be triggered manually via `workflow_dispatch` with optional version input
- Creates pull requests automatically when updates are detected
- Creates GitHub issues if automation fails

The workflow uses the same update logic as the script but duplicates some steps inline for better workflow visibility and control.

## Testing

Before committing changes to the script:

1. Test with current version (should exit early):

   ```bash
   ./scripts/update-x-ray.sh 0.3.5
   ```

2. Test with known older version (should update):

   ```bash
   ./scripts/update-x-ray.sh 0.3.4
   git diff Formula/x-ray.rb
   git checkout Formula/x-ray.rb  # revert
   ```

3. Test with latest version:

   ```bash
   ./scripts/update-x-ray.sh
   git diff Formula/x-ray.rb
   git checkout Formula/x-ray.rb  # revert
   ```

4. Run shellcheck:

   ```bash
   shellcheck scripts/update-x-ray.sh
   ```

5. Test the just recipes:

   ```bash
   just update-x-ray-to 0.3.4
   git checkout Formula/x-ray.rb  # revert
   ```

## Future Enhancements

Possible improvements for the future:

- **Multi-formula support** - Accept formula name as argument
- **Changelog generation** - Parse release notes from GitHub
- **Validation testing** - Run `brew audit` and `brew test` after update
- **Version constraints** - Skip pre-release versions or allow opting into them
- **Notification** - Send alerts when updates are available
- **Rollback** - Automatic rollback if tests fail
