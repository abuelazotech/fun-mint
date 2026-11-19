#!/usr/bin/env bash
# ==============================================================================
# Nombre: FUN v2 - Constructor del paquete .deb
# Autor: El Abuelazo Tech
# Versión: 1.2.0
# ==============================================================================

set -Eeuo pipefail

FECHA_PAQUETE=$(awk '/^ -- / {print $6, $7, $8, $9, $10; exit}' packaging/changelog)
export SOURCE_DATE_EPOCH=$(date -u -d "$FECHA_PAQUETE" +%s)

PACKAGE_NAME="fun"
VERSION="1.2.0-1"
DEB_FILE="${PACKAGE_NAME}_${VERSION}_amd64.deb"
BUILD_DIR="fun-builder"

echo "🧹 1. Limpiando construcciones anteriores..."
rm -rf "$BUILD_DIR" "$DEB_FILE"

echo "📁 2. Creando estructura de directorios Debian..."
install -d -m 755 "$BUILD_DIR/DEBIAN"
install -d -m 755 "$BUILD_DIR/usr/bin"
install -d -m 755 "$BUILD_DIR/usr/share/applications"
install -d -m 755 "$BUILD_DIR/usr/share/doc/fun"
install -d -m 755 "$BUILD_DIR/usr/share/icons/hicolor/256x256/apps"
install -d -m 755 "$BUILD_DIR/usr/share/icons/hicolor/1024x1024/apps"

echo "📦 3. Copiando archivos a sus ubicaciones..."
install -m 755 src/fun.sh "$BUILD_DIR/usr/bin/fun"
install -m 644 assets/fun-256.png "$BUILD_DIR/usr/share/icons/hicolor/256x256/apps/fun.png"
install -m 644 assets/fun.png "$BUILD_DIR/usr/share/icons/hicolor/1024x1024/apps/fun.png"
install -m 644 packaging/fun.desktop "$BUILD_DIR/usr/share/applications/fun.desktop"
install -m 644 packaging/control "$BUILD_DIR/DEBIAN/control"
install -m 755 packaging/postinst "$BUILD_DIR/DEBIAN/postinst"
install -m 644 packaging/copyright "$BUILD_DIR/usr/share/doc/fun/copyright"
gzip -9 -n -c packaging/changelog > "$BUILD_DIR/usr/share/doc/fun/changelog.gz"
chmod 644 "$BUILD_DIR/usr/share/doc/fun/changelog.gz"

echo "🔨 4. Construyendo paquete .deb..."
dpkg-deb --build --root-owner-group "$BUILD_DIR" "$DEB_FILE"

echo "🧹 5. Limpiando archivos temporales..."
rm -rf "$BUILD_DIR"

echo "✅ Paquete listo: $DEB_FILE"
sha256sum "$DEB_FILE"
