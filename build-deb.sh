#!/bin/bash

set -e  # Stop if any command fails

# === Step 1: Define Variables ===
PACKAGE_NAME="wireguard-rotator"
VERSION="1.1"
ARCH="all"
BUILD_DIR="build"
OUT_DIR="out"
DEBIAN_DIR="$BUILD_DIR/DEBIAN"
INSTALL_DIR="$BUILD_DIR/etc/$PACKAGE_NAME"
BIN_DIR="$BUILD_DIR/usr/local/bin"

# === Step 2: Clean old builds ===
echo "Cleaning old builds..."
rm -rf "$BUILD_DIR" "$OUT_DIR"
mkdir -p "$DEBIAN_DIR" "$INSTALL_DIR" "$BIN_DIR" "$OUT_DIR"

# === Step 3: Create control file (package metadata) ===
cat <<EOF > "$DEBIAN_DIR/control"
Package: $PACKAGE_NAME
Version: $VERSION
Section: base
Priority: optional
Architecture: $ARCH
Depends: wireguard, jq, curl, resolvconf
Maintainer: You <you@example.com>
Description: WireGuard ProtonVPN auto-rotator with ntfy notifications and config.json support.
EOF

# === Step 4: Copy your files ===
echo "Copying project files..."
cp rotate-vpn.sh "$BIN_DIR/"
cp config.json "$INSTALL_DIR/"
mkdir -p "$INSTALL_DIR/wg-configs/broken_configs"
mkdir -p "$INSTALL_DIR/logs"
mkdir -p "$INSTALL_DIR/state"

# === Step 5: Set permissions ===
chmod 755 "$BIN_DIR/rotate-vpn.sh"

# === Step 6: Build the .deb package ===
DEB_FILE="$OUT_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo "Building package..."
dpkg-deb --build "$BUILD_DIR" "$DEB_FILE"

echo "✅ Done! Package created: $DEB_FILE"
