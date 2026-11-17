#!/usr/bin/env bash
# ==============================================================================
# Nombre: FUN v2 - Instalador
# Autor: El Abuelazo Tech
# Versión: 2.0.0 (Instalador simple y directo)
# ==============================================================================

# Verificar que se ejecuta como root
if [ "$EUID" -ne 0 ]; then
    echo "Este script debe ejecutarse con sudo"
    exit 1
fi

echo "Instalando FUN v2..."

# Copiar el script principal
cp src/fun.sh /usr/local/bin/fun
chmod +x /usr/local/bin/fun

# Copiar el icono
cp assets/fun.png /usr/share/icons/hicolor/256x256/apps/fun.png

# Copiar el archivo .desktop
cp packaging/fun.desktop /usr/share/applications/fun.desktop

# Actualizar caché de iconos
gtk-update-icon-cache /usr/share/icons/hicolor/

echo "✅ Instalación completada con éxito"
echo "Busca FUN en el menú de inicio"
