#!/usr/bin/env bash
# Package the Linux release bundle into a tarball for distribution.
# Run after: flutter build linux --release

set -euo pipefail

BUNDLE_DIR="build/linux/x64/release/bundle"
OUTPUT="dist/getmeback-linux-x64.tar.gz"

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: $BUNDLE_DIR not found. Run 'flutter build linux --release' first."
  exit 1
fi

mkdir -p dist
tar -czf "$OUTPUT" -C "$BUNDLE_DIR" .
echo "Created $OUTPUT"
echo "Extract and run: tar -xzf $OUTPUT -C ~/getmeback && ~/getmeback/getmeback"
