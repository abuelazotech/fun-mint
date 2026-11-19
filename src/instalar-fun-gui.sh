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
DEB_SHA256="2b3b09854d1c87b3e3da527b739d6759d71bf5ef54706819d15833674cc9e04d"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname -- "$SCRIPT_DIR")"
DEB_LOCAL="$PROJECT_DIR/$DEB_NAME"
DEB_FILE="$DEB_LOCAL"

MODO="install"
for argumento in "$@"; do
    case "$argumento" in
        --uninstall) MODO="uninstall" ;;
        -h|--help)
            echo "Instalador gráfico de FUN v$VERSION"
            echo "Uso: instalar-fun-gui.sh [--uninstall|--help]"
            echo "  --uninstall  Desinstala FUN del sistema"
            echo "  --help       Muestra esta ayuda"
            exit 0
            ;;
        *) echo "Opción desconocida: $argumento" >&2; exit 2 ;;
    esac
done

if ! command -v zenity >/dev/null 2>&1; then
    echo "Se necesita zenity para mostrar la interfaz gráfica. Usa src/instalar-fun.sh en la terminal." >&2
    exit 1
fi

if ! command -v pkexec >/dev/null 2>&1; then
    zenity --error --title="FUN" --text="No se encontró pkexec. Usa el instalador de terminal (src/instalar-fun.sh)."
    exit 1
fi

INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' fun 2>/dev/null || true)

if [[ "$MODO" = "uninstall" ]]; then
    if [[ -z "$INSTALLED_VERSION" ]]; then
        zenity --info --title="FUN" --text="FUN no está instalado. Nada que desinstalar."
        exit 0
    fi
    if zenity --question --title="Desinstalar FUN" \
        --text="¿Quieres desinstalar FUN $INSTALLED_VERSION?\n\nTus reportes del Escritorio se conservarán." \
        --ok-label="Desinstalar" --cancel-label="Cancelar" 2>/dev/null; then
        if pkexec /usr/bin/apt remove -y fun; then
            zenity --info --title="FUN" --text="✅ FUN se desinstaló correctamente."
        else
            zenity --error --title="FUN" --text="❌ No se pudo desinstalar FUN."
        fi
    fi
    exit 0
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

ACCION=""
MENSAJE=""
ETIQUETA=""

if [ -z "$INSTALLED_VERSION" ]; then
    ACCION="instalar"
    MENSAJE="FUN no está instalado.\n\nSe instalará la versión $DEB_VERSION ($DEB_ORIGEN)."
    ETIQUETA="Instalar"
elif dpkg --compare-versions "$INSTALLED_VERSION" eq "$DEB_VERSION"; then
    ACCION="reinstalar"
    MENSAJE="Ya tienes FUN $DEB_VERSION instalado.\n\nSe reinstalarán los archivos para refrescar el icono y la captura."
    ETIQUETA="Reinstalar"
elif dpkg --compare-versions "$INSTALLED_VERSION" lt "$DEB_VERSION"; then
    ACCION="actualizar"
    MENSAJE="Tienes FUN $INSTALLED_VERSION instalado.\n\nSe actualizará a $DEB_VERSION. Las copias antiguas se limpiarán automáticamente."
    ETIQUETA="Actualizar"
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
        zenity --info --title="FUN" --text="✅ $OPERACION\n\nBusca «FUN - El Abuelazo Tech» en el menú o escribe <b>fun</b> en la terminal.\n\nSi no aparece la captura, ejecuta: sudo appstreamcli refresh --force"
    else
        zenity --error --title="FUN" --text="❌ No se pudo completar la operación.\nRevisa la ventana de permisos o los mensajes en pantalla."
    fi
fi
