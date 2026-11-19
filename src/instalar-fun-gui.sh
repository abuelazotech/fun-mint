#!/usr/bin/env bash
# ==============================================================================
# Nombre: FUN v1.2.0 - Instalador gráfico
# Autor: El Abuelazo Tech
# Versión: 1.2.0
# ==============================================================================

set -Eeuo pipefail

VERSION="1.2.0"
DEB_VERSION="1.2.0-1"
DEB_NAME="fun_${DEB_VERSION}_amd64.deb"
DEB_URL="https://github.com/abuelazotech/fun-mint/releases/download/${DEB_VERSION}/${DEB_NAME}"
DEB_SHA256="b3b7706dc67abb2b3282d5e51a14266db0a34997de8dae2c8b933a0d6f635e86"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname -- "$SCRIPT_DIR")"
DEB_LOCAL="$PROJECT_DIR/$DEB_NAME"
DEB_FILE="$DEB_LOCAL"

if ! command -v zenity >/dev/null 2>&1; then
    echo "Se necesita zenity para mostrar la interfaz gráfica. Usa src/instalar-fun.sh en la terminal." >&2
    exit 1
fi

if ! command -v pkexec >/dev/null 2>&1; then
    zenity --error --title="FUN" --text="No se encontró pkexec. Usa el instalador de terminal (src/instalar-fun.sh)."
    exit 1
fi

if [[ -f "$DEB_LOCAL" ]]; then
    DEB_ORIGEN="paquete local"
else
    DEB_FILE="${TMPDIR:-/tmp}/$DEB_NAME"
    DEB_ORIGEN="GitHub"
    if ! zenity --info --title="Instalar FUN v$VERSION" \
        --text="No encontré el paquete en la carpeta.\n\nLo descargaré desde GitHub e instalaré la versión $VERSION." \
        --ok-label="Continuar" --cancel-label="Cancelar" 2>/dev/null; then
        exit 0
    fi
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --connect-timeout 10 -o "$DEB_FILE" "$DEB_URL" || {
            zenity --error --title="FUN" --text="No se pudo descargar el paquete. Revisa tu conexión."
            exit 1; }
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$DEB_FILE" "$DEB_URL" || {
            zenity --error --title="FUN" --text="No se pudo descargar el paquete. Revisa tu conexión."
            exit 1; }
    else
        zenity --error --title="FUN" --text="Se necesita curl o wget para descargar el paquete."
        exit 1
    fi
fi

SHA_DESCARGA=$(sha256sum "$DEB_FILE" | awk '{print $1}')
if [[ "$SHA_DESCARGA" != "$DEB_SHA256" ]]; then
    zenity --error --title="FUN" --text="❌ La suma SHA256 no coincide. No se instalará nada.\n\nDescarga el paquete desde https://github.com/abuelazotech/fun-mint/releases"
    exit 1
fi

INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' fun 2>/dev/null || true)

ACCION=""
MENSAJE=""
ETIQUETA=""

if [ -z "$INSTALLED_VERSION" ]; then
    ACCION="instalar"
    MENSAJE="FUN no está instalado.\n\nSe instalará la versión $DEB_VERSION ($DEB_ORIGEN)."
    ETIQUETA="Instalar"
elif dpkg --compare-versions "$INSTALLED_VERSION" lt "$DEB_VERSION"; then
    ACCION="actualizar"
    MENSAJE="Tienes FUN $INSTALLED_VERSION instalado.\n\nSe actualizará a $DEB_VERSION. Las copias antiguas se limpiarán automáticamente."
    ETIQUETA="Actualizar"
elif dpkg --compare-versions "$INSTALLED_VERSION" eq "$DEB_VERSION"; then
    ACCION="reinstalar"
    MENSAJE="Ya tienes FUN $DEB_VERSION instalado.\n\n¿Quieres reinstalarlo?"
    ETIQUETA="Reinstalar"
else
    ACCION="reinstalar"
    MENSAJE="Tienes FUN $INSTALLED_VERSION (más reciente que $DEB_VERSION).\n\n¿Quieres reinstalar $DEB_VERSION de todos modos?"
    ETIQUETA="Reinstalar de todos modos"
fi

if zenity --question --title="Instalar FUN v$VERSION" \
    --text="$MENSAJE" --ok-label="$ETIQUETA" --cancel-label="Cancelar"; then

    if [ "$ACCION" = "reinstalar" ]; then
        if pkexec /bin/sh -c '/usr/bin/dpkg -i "$1" && /usr/bin/apt -f install -y' sh "$DEB_FILE"; then
            OPERACION="Reinstalación completada."
            RESULTADO=1
        else
            RESULTADO=0
        fi
    else
        if pkexec /usr/bin/apt install -y --allow-downgrades "$DEB_FILE"; then
            if [ "$ACCION" = "actualizar" ]; then
                OPERACION="Actualización completada."
            else
                OPERACION="Instalación completada."
            fi
            RESULTADO=1
        else
            RESULTADO=0
        fi
    fi

    if (( RESULTADO )); then
        zenity --info --title="FUN" --text="✅ $OPERACION\n\nBusca «FUN - El Abuelazo Tech» en el menú de aplicaciones o escribe <b>fun</b> en la terminal."
    else
        zenity --error --title="FUN" --text="❌ No se pudo completar la operación.\nRevisa la ventana de permisos o los mensajes en pantalla."
    fi
fi
