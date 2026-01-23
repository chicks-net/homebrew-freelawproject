# project justfile

import? '.just/compliance.just'
import? '.just/gh-process.just'
import? '.just/pr-hook.just'
import? '.just/shellcheck.just'
import? '.just/cue-verify.just'

# list recipes (default works without naming it)
[group('info')]
list:
	just --list

# install x-ray formula from source and test it
[group('brew test')]
test-x-ray:
	#!/usr/bin/env bash
	set -euxo pipefail

	# Tap this repository if not already tapped
	brew tap chicks-net/freelawproject 2>/dev/null || true

	# Copy formula to tap directory (or confirm it exists)
	TAP_DIR="$(brew --repository)/Library/Taps/chicks-net/homebrew-freelawproject"
	mkdir -p "$TAP_DIR/Formula"
	if [ ! -f "$TAP_DIR/Formula/x-ray.rb" ]; then
		cp Formula/x-ray.rb "$TAP_DIR/Formula/"
	elif ! cmp -s Formula/x-ray.rb "$TAP_DIR/Formula/x-ray.rb"; then
		# File exists but differs - overwrite it
		cp -f Formula/x-ray.rb "$TAP_DIR/Formula/"
	fi
	# If file exists and is identical, do nothing (success)

	# Install from source (allow binary wheels for Python packages)
	brew install x-ray

	# Verify the tool exists
	which x-ray

	# Test that the executable wrapper was created
	test -x "$(brew --prefix)/bin/x-ray"

	# Run brew tests
	brew test x-ray
	brew audit --strict x-ray
	brew style x-ray

# uninstall x-ray formula
[group('brew test')]
uninstall-x-ray:
	#!/usr/bin/env bash
	set -euxo pipefail
	brew uninstall x-ray 2>/dev/null || echo "x-ray not installed"

# update Python resources for x-ray formula
[group('brew maintenance')]
update-x-ray-resources:
	#!/usr/bin/env bash
	set -euxo pipefail

	echo "Updating Python resources for x-ray formula..."
	brew update-python-resources Formula/x-ray.rb
	echo "{{GREEN}}Resources updated! Review Formula/x-ray.rb for changes{{NORMAL}}"
