#!/usr/bin/env bash
#
# update-x-ray.sh - Update the x-ray Homebrew formula to a new version
#
# Usage:
#   ./scripts/update-x-ray.sh [VERSION]
#
# If VERSION is not provided, fetches the latest release from GitHub.
#
# This script:
# 1. Detects the current version in Formula/x-ray.rb
# 2. Fetches the specified version (or latest) from GitHub
# 3. Downloads the tarball and calculates SHA256
# 4. Updates the formula file with new version and SHA256
# 5. Runs brew update-python-resources to refresh dependencies
# 6. Shows a diff of the changes

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Repository information
readonly UPSTREAM_REPO="freelawproject/x-ray"
readonly FORMULA_FILE="Formula/x-ray.rb"

# Helper functions
error() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}INFO: $*${NC}"
}

success() {
    echo -e "${GREEN}SUCCESS: $*${NC}"
}

warning() {
    echo -e "${YELLOW}WARNING: $*${NC}"
}

# Check if required commands are available
check_dependencies() {
    local missing=()

    for cmd in curl jq brew; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required commands: ${missing[*]}"
    fi
}

# Get current version from formula
get_current_version() {
    if [ ! -f "$FORMULA_FILE" ]; then
        error "Formula file not found: $FORMULA_FILE"
    fi

    local version
    version=$(grep -E '^\s+url\s+"https://github.com/freelawproject/x-ray/archive/refs/tags/v' "$FORMULA_FILE" | \
              sed -E 's/.*\/v([0-9]+\.[0-9]+\.[0-9]+)\.tar\.gz".*/\1/')

    if [ -z "$version" ]; then
        error "Could not extract current version from $FORMULA_FILE"
    fi

    echo "$version"
}

# Get latest release version from GitHub API
get_latest_version() {
    info "Fetching latest release from GitHub API..."

    local response
    response=$(curl -s -H "Accept: application/vnd.github.v3+json" \
                    "https://api.github.com/repos/$UPSTREAM_REPO/releases/latest")

    if [ -z "$response" ]; then
        error "Failed to fetch latest release from GitHub API"
    fi

    local version
    version=$(echo "$response" | jq -r '.tag_name' | sed 's/^v//')

    if [ -z "$version" ] || [ "$version" = "null" ]; then
        error "Could not parse version from GitHub API response"
    fi

    echo "$version"
}

# Download tarball and calculate SHA256
get_tarball_sha256() {
    local version=$1
    local url="https://github.com/$UPSTREAM_REPO/archive/refs/tags/v${version}.tar.gz"

    info "Downloading tarball from: $url"

    local sha256
    sha256=$(curl -sL "$url" | shasum -a 256 | cut -d' ' -f1)

    if [ -z "$sha256" ]; then
        error "Failed to calculate SHA256 for tarball"
    fi

    echo "$sha256"
}

# Update formula file with new version and SHA256
update_formula() {
    local new_version=$1
    local new_sha256=$2

    info "Updating formula file: $FORMULA_FILE"

    # Create backup
    cp "$FORMULA_FILE" "${FORMULA_FILE}.backup"

    # Update version in URL (using -E for portable extended regex)
    sed -E -i.tmp "s|url \"https://github.com/freelawproject/x-ray/archive/refs/tags/v[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz\"|url \"https://github.com/freelawproject/x-ray/archive/refs/tags/v${new_version}.tar.gz\"|" "$FORMULA_FILE"

    # Update SHA256 (only the tarball sha256, not resource sha256s)
    sed -E -i.tmp "/url \"https:\/\/github\.com\/freelawproject\/x-ray\/archive\/refs\/tags\/v[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz\"/,+1 s/sha256 \"[a-f0-9]{64}\"/sha256 \"${new_sha256}\"/" "$FORMULA_FILE"

    # Remove temporary file created by sed
    rm -f "${FORMULA_FILE}.tmp"

    success "Formula file updated"
}

# Update Python resources using brew
update_python_resources() {
    info "Updating Python resources..."

    # Check if we're in a Homebrew environment
    if ! brew --version &> /dev/null; then
        warning "Homebrew not found, skipping Python resource update"
        return
    fi

    # Run brew update-python-resources
    if brew update-python-resources "$FORMULA_FILE"; then
        success "Python resources updated"
    else
        warning "Failed to update Python resources (you may need to run this manually)"
    fi
}

# Show diff of changes
show_diff() {
    info "Changes made to formula:"
    echo
    git diff "$FORMULA_FILE" || true
    echo
}

# Main function
main() {
    local target_version=""

    # Parse arguments
    if [ $# -gt 0 ]; then
        target_version=$1
        # Remove leading 'v' if present
        target_version=${target_version#v}
    fi

    # Check dependencies
    check_dependencies

    # Get current version
    local current_version
    current_version=$(get_current_version)
    info "Current version: $current_version"

    # Determine target version
    if [ -z "$target_version" ]; then
        target_version=$(get_latest_version)
        info "Latest version: $target_version"
    else
        info "Target version: $target_version"
    fi

    # Check if update is needed
    if [ "$current_version" = "$target_version" ]; then
        success "Formula is already at version $current_version"
        exit 0
    fi

    info "Updating from v$current_version to v$target_version"
    echo

    # Get SHA256 for new version
    local new_sha256
    new_sha256=$(get_tarball_sha256 "$target_version")
    info "SHA256: $new_sha256"
    echo

    # Update formula
    update_formula "$target_version" "$new_sha256"

    # Update Python resources
    update_python_resources
    echo

    # Show diff
    show_diff

    # Success message
    success "Formula updated to v$target_version"
    echo
    info "Next steps:"
    echo "  1. Review the changes: git diff $FORMULA_FILE"
    echo "  2. Test the formula: just test-x-ray"
    echo "  3. Commit the changes: git add $FORMULA_FILE && git commit"
    echo
}

# Run main function
main "$@"
