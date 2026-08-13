#!/usr/bin/env bash
# Install Linux desktop build dependencies for GetMeBack (Flutter).
# Run once with sudo: sudo ./scripts/install-linux-deps.sh

set -euo pipefail

echo "Installing Flutter Linux desktop dependencies..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  libblkid-dev \
  liblzma-dev \
  libstdc++-12-dev

echo "Done. Verify with: flutter doctor -v"
