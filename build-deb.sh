#!/bin/bash

set -e  # Stop on error

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

# === Step 3: Create control file ===
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

# === Step 4: Create postinst script ===
cat <<'EOF' > "$DEBIAN_DIR/postinst"
#!/bin/bash
set -e

# Create runtime directories in case they were stripped by packaging
mkdir -p /etc/wireguard-rotator/logs
mkdir -p /etc/wireguard-rotator/state
mkdir -p /etc/wireguard-rotator/wg-configs/broken_configs

exit 0
EOF

chmod 755 "$DEBIAN_DIR/postinst"

# === Step 5: Copy your project files ===
echo "Copying project files..."
cp rotate-vpn.sh "$BIN_DIR/"
cp config.json "$INSTALL_DIR/"
# (we no longer need to create empty folders here — postinst handles it)

# === Step 6: Set file permissions ===
chmod 755 "$BIN_DIR/rotate-vpn.sh"

# === Step 7: Build the .deb ===
DEB_FILE="$OUT_DIR/${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"
echo "Building package..."
dpkg-deb --build "$BUILD_DIR" "$DEB_FILE"

echo "✅ Done! Package created: $DEB_FILE"
