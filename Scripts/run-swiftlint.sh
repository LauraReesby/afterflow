#!/usr/bin/env bash
set -euo pipefail

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "error: SwiftLint is not installed. Install via 'brew install swiftlint'" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"

if [ ! -f "$REPO_ROOT/.swiftlint.yml" ]; then
  echo "error: .swiftlint.yml not found at repo root" >&2
  exit 1
fi

# Run from the repo root without --config so SwiftLint discovers the root
# configuration AND the nested test-target overrides.
cd "$REPO_ROOT"
swiftlint lint --no-cache "$@"
