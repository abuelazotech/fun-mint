#!/usr/bin/env bash
# ==============================================================================
# Nombre: FUN v2 - Constructor del paquete .deb
# Autor: El Abuelazo Tech
# Versión: 2.0.0
# ==============================================================================

PACKAGE_NAME="fun"
VERSION="2.0.0"
DEB_FILE="${PACKAGE_NAME}_${VERSION}_amd64.deb"
BUILD_DIR="fun-builder"

echo "🧹 1. Limpiando construcciones anteriores..."
rm -rf "$BUILD_DIR" "$DEB_FILE"

echo "📁 2. Creando estructura de directorios Debian..."
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/local/bin"
mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$BUILD_DIR/usr/share/applications"

echo "📦 3. Copiando archivos a sus ubicaciones..."
# Script principal
cp src/fun.sh "$BUILD_DIR/usr/local/bin/fun"
chmod 755 "$BUILD_DIR/usr/local/bin/fun"

# Icono
cp assets/fun.png "$BUILD_DIR/usr/share/icons/hicolor/256x256/apps/fun.png"

# Archivo .desktop
cp packaging/fun.desktop "$BUILD_DIR/usr/share/applications/fun.desktop"

# Archivo de control
cp packaging/control "$BUILD_DIR/DEBIAN/control"

echo "🔨 4. Construyendo paquete .deb..."
dpkg-deb --build "$BUILD_DIR" "$DEB_FILE"

echo "🧹 5. Limpiando archivos temporales..."
rm -rf "$BUILD_DIR"

echo "✅ ¡Éxito! Paquete generado: $DEB_FILE"
