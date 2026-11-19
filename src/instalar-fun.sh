#!/usr/bin/env bash
# ==============================================================================
# Nombre: FUN v1.2.0 - Instalador (terminal)
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

VERDE=$(tput setaf 2 2>/dev/null || true); [ -z "$VERDE" ] && VERDE='\033[1;92m'
AZUL_CLARO=$(tput setaf 14 2>/dev/null || true); [ -z "$AZUL_CLARO" ] && AZUL_CLARO='\033[1;96m'
AMARILLO=$(tput setaf 11 2>/dev/null || true); [ -z "$AMARILLO" ] && AMARILLO='\033[1;93m'
ROJO=$(tput setaf 1 2>/dev/null || true); [ -z "$ROJO" ] && ROJO='\033[1;91m'
NC=$(tput sgr0 2>/dev/null || true); [ -z "$NC" ] && NC='\033[0m'

MODO="install"
SIMULAR=0

usage() {
    echo "Instalador de FUN v$VERSION (paquete $DEB_VERSION)"
    echo "Uso: instalar-fun.sh [--reinstall|--uninstall|--dry-run|--version|--help]"
    echo "  --reinstall  Instala de nuevo aunque ya estés en la misma versión"
    echo "  --uninstall  Desinstala FUN del sistema"
    echo "  --dry-run    Muestra qué haría sin descargar ni modificar nada"
    echo "  --version    Muestra la versión del instalador"
    echo "  --help       Muestra esta ayuda"
}

for argumento in "$@"; do
    case "$argumento" in
        --reinstall) MODO="reinstall" ;;
        --uninstall) MODO="uninstall" ;;
        --dry-run) SIMULAR=1 ;;
        -V|--version) echo "Instalador FUN v$VERSION"; exit 0 ;;
        -h|--help) usage; exit 0 ;;
        *) echo -e "${ROJO}Opción desconocida: $argumento${NC}" >&2; usage >&2; exit 2 ;;
    esac
done

INSTALADO=$(dpkg-query -W -f='${Version}' fun 2>/dev/null || true)
APT_CMD=(apt install -y --allow-downgrades)
if [[ "$MODO" = "reinstall" ]] || [[ "$INSTALADO" = "$DEB_VERSION" ]]; then
    APT_CMD+=(--reinstall)
fi
APT_CMD+=("$DEB_FILE")

if (( SIMULAR )); then
    echo -e "${AMARILLO}🔍 SIMULACIÓN: no se descargará ni modificará nada.${NC}"
    if [[ "$MODO" = "uninstall" ]]; then
        echo "Versión instalada: ${INSTALADO:-ninguna}"
        echo "Acción: apt remove -y fun"
    else
        echo "Paquete: $DEB_NAME"
        echo "Origen local: $DEB_LOCAL"
        echo "Si no existe, se descarga de: $DEB_URL"
        echo "Suma esperada: $DEB_SHA256"
        echo "Acción: ${APT_CMD[*]}"
    fi
    exit 0
fi

if [[ $EUID -ne 0 ]]; then
    echo -e "${AMARILLO}🔐 Se pedirá tu contraseña una sola vez.${NC}"
    sudo -v || { echo -e "${ROJO}No se obtuvieron permisos de administrador.${NC}" >&2; exit 1; }
fi

if [[ "$MODO" = "uninstall" ]]; then
    if [[ -z "$INSTALADO" ]]; then
        echo -e "${AMARILLO}FUN no está instalado. Nada que desinstalar.${NC}"
        exit 0
    fi
    if command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
        zenity --question --title="Desinstalar FUN" \
            --text="¿Quieres desinstalar FUN $INSTALADO?" \
            --ok-label="Desinstalar" --cancel-label="Cancelar" 2>/dev/null || exit 0
    elif [[ -t 0 ]]; then
        read -r -p "¿Desinstalar FUN $INSTALADO? Escribe s para confirmar: " CONFIRMAR || true
        [[ "${CONFIRMAR:-}" =~ ^[sS]$ ]] || exit 0
    fi
    echo -e "${AZUL_CLARO}🗑️  Desinstalando FUN $INSTALADO...${NC}"
    if (( EUID == 0 )); then
        apt remove -y fun
    else
        sudo apt remove -y fun
    fi
    echo -e "${VERDE}✅ FUN se desinstaló. Tus reportes del Escritorio se conservan.${NC}"
    if command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
        zenity --info --title="FUN" --text="✅ FUN se desinstaló correctamente." 2>/dev/null || true
    fi
    if [[ -t 0 ]]; then
        read -r -p "Presiona Enter para salir..." || true
    fi
    exit 0
fi

if [[ -f "$DEB_LOCAL" ]]; then
    echo -e "${VERDE}📦 Usando el paquete local: $DEB_LOCAL${NC}"
else
    DEB_FILE="${TMPDIR:-/tmp}/$DEB_NAME"
    APT_CMD[-1]="$DEB_FILE"
    echo -e "${AZUL_CLARO}⬇️  Descargando $DEB_NAME desde GitHub...${NC}"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --connect-timeout 10 -o "$DEB_FILE" "$DEB_URL" || {
            echo -e "${ROJO}No se pudo descargar el paquete.${NC}" >&2; exit 1; }
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$DEB_FILE" "$DEB_URL" || {
            echo -e "${ROJO}No se pudo descargar el paquete.${NC}" >&2; exit 1; }
    else
        echo -e "${ROJO}Se necesita curl o wget para descargar el paquete.${NC}" >&2
        exit 1
    fi
fi

SHA_DESCARGA=$(sha256sum "$DEB_FILE" | awk '{print $1}')
if [[ "$SHA_DESCARGA" != "$DEB_SHA256" ]]; then
    echo -e "${ROJO}❌ La suma SHA256 no coincide. No se instalará nada.${NC}" >&2
    echo "Descarga el paquete manualmente desde https://github.com/abuelazotech/fun-mint/releases" >&2
    exit 1
fi
echo -e "${VERDE}✅ Paquete verificado (SHA256 correcto).${NC}"

if [[ " ${APT_CMD[*]} " == *" --reinstall "* ]]; then
    echo -e "${AZUL_CLARO}⚙️  Reinstando FUN v$VERSION...${NC}"
else
    echo -e "${AZUL_CLARO}⚙️  Instalando FUN v$VERSION...${NC}"
fi
if (( EUID == 0 )); then
    "${APT_CMD[@]}"
else
    sudo "${APT_CMD[@]}"
fi

echo ""
echo -e "${VERDE}✅ FUN v$VERSION quedó instalado.${NC}"
echo -e "${AZUL_CLARO}   Ejecuta: fun${NC}"
echo -e "${AZUL_CLARO}   Ayuda:   fun --help${NC}"
echo -e "${AZUL_CLARO}   Prueba:  fun --dry-run${NC}"
echo -e "${AZUL_CLARO}   Si no aparece la captura en el Gestor de Software: sudo appstreamcli refresh --force${NC}"

if command -v zenity >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    zenity --info --title="FUN v$VERSION" \
        --text="✅ Instalación completada.\n\nBusca «FUN - El Abuelazo Tech» en el menú o escribe <b>fun</b> en la terminal." 2>/dev/null || true
fi
if [[ -t 0 ]]; then
    read -r -p "Presiona Enter para salir..." || true
fi
