#!/usr/bin/env bash
#
# update-x-ray-resources.sh - regenerate Python resources in Formula/x-ray.rb
#
# `brew update-python-resources` resolves its formula argument by NAME
# from the local tap; current Homebrew no longer accepts file paths (they
# fail with "No available formula with the name ..."). This script stages
# the working-tree formula into the tap, runs the update by name, and
# copies the result back, so it works both when the tap is this checkout
# (Homebrew's setup-homebrew action symlinks it to the workspace on CI)
# and when the tap is a separate clone (a normal dev machine).
#
# The formula's `pypi_packages` stanza supplies the PyPI package name
# and the package exclusions (PyMuPDF is provided by the brew `pymupdf`
# formula dependency, not as a pip resource).
#
# Flags passed to brew:
#   --install-dependencies          install python@3.15 when missing (the
#                                   resolver runs pip with it)
#   --ignore-main-package-cooldown  allow resolving a just-released
#                                   x-ray; its dependencies still respect
#                                   the cooldown (third-party taps only)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
readonly FORMULA_FILE="Formula/x-ray.rb"
readonly TAP_NAME="chicks-net/freelawproject"

cd "$REPO_ROOT"

if [ ! -f "$FORMULA_FILE" ]; then
	echo "ERROR: $FORMULA_FILE not found - run from the repo root" >&2
	exit 1
fi

# `brew --repository <tap>` prints the tap's real directory, which
# carries the homebrew- prefix (Library/Taps/chicks-net/homebrew-freelawproject)
# even though the tap name is chicks-net/freelawproject - do not build
# this path by hand.
TAP_DIR="$(brew --repository "${TAP_NAME}")"

# setup-homebrew symlinks the tap to the workspace when this repository
# is itself a tap (owner/homebrew-*), and staging would fail with
# "cp: ... are the same file". Update in place when the tap is the
# workspace; only stage a copy when the tap is a separate directory.
if [ "$(readlink -f "$TAP_DIR")" = "$(readlink -f "$PWD")" ]; then
	TAP_IS_WORKSPACE="true"
else
	TAP_IS_WORKSPACE="false"
	mkdir -p "$TAP_DIR/Formula"
	# This leaves the tap clone dirty, same as the test-x-ray recipes.
	cp "$FORMULA_FILE" "$TAP_DIR/Formula/x-ray.rb"
fi

brew update-python-resources \
	--install-dependencies \
	--ignore-main-package-cooldown \
	"${TAP_NAME}/x-ray"

# Sync the updated formula back to the workspace unless the tap already
# is the workspace.
if [ "$TAP_IS_WORKSPACE" = "false" ]; then
	cp "$TAP_DIR/Formula/x-ray.rb" "$FORMULA_FILE"
fi
