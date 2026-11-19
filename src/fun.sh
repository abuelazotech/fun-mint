#!/usr/bin/env bash
# ==============================================================================
# Nombre de la Herramienta: FUN (Script de Mantenimiento y Salud para Linux Mint)
# Autor: El Abuelazo Tech
# Versión: 1.2.0
# ==============================================================================

set -Eeuo pipefail

VERDE=$(tput setaf 2 2>/dev/null || true); [ -z "$VERDE" ] && VERDE='\033[1;92m'
AZUL_CLARO=$(tput setaf 14 2>/dev/null || true); [ -z "$AZUL_CLARO" ] && AZUL_CLARO='\033[1;96m'
AMARILLO=$(tput setaf 11 2>/dev/null || true); [ -z "$AMARILLO" ] && AMARILLO='\033[1;93m'
ROJO=$(tput setaf 1 2>/dev/null || true); [ -z "$ROJO" ] && ROJO='\033[1;91m'
NC=$(tput sgr0 2>/dev/null || true); [ -z "$NC" ] && NC='\033[0m'
NEGRITA=$(tput bold 2>/dev/null || true); [ -z "$NEGRITA" ] && NEGRITA='\033[1m'

usage() {
    echo "FUN v1.2.0 - El Abuelazo Tech"
    echo "Uso: fun [--dry-run|--version|--help]"
    echo "  --dry-run   Muestra las acciones previstas sin modificar el sistema"
    echo "  --version   Muestra la versión instalada"
    echo "  --help      Muestra esta ayuda"
    echo ""
    echo "Reporta errores: https://github.com/abuelazotech/fun-mint/issues/new/choose"
}

case "${1:-}" in
    --dry-run)
        echo -e "${AMARILLO}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${AMARILLO}║      🔍 MODO SIMULACIÓN ACTIVADO (NO SE BORRARÁ NADA)        ║${NC}"
        echo -e "${AMARILLO}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo -e "\nEsto es lo que FUN haría si lo ejecutas de verdad:"
        echo -e "1. Sincronizar repositorios e instalar Nala/lm-sensors si faltan."
        echo -e "2. Actualizar el sistema con Nala (sin importar claves GPG automáticamente)."
        echo -e "3. Eliminar dependencias huérfanas."
        echo -e "4. Limpiar caché, logs y miniaturas."
        echo -e "5. Actualizar Flatpak y limpiar residuos."
        echo -e "6. Actualizar Cinnamon Spices."
        echo -e "7. Borrar archivos .deb viejos (+7 días) de Descargas."
        echo -e "8. Mostrar un reporte de salud con el estado real de cada paso."
        echo -e "\n${VERDE}✅ Simulación terminada. El sistema no ha sido modificado.${NC}\n"
        read -r -p "Presiona Enter para salir..." || true
        exit 0
        ;;
    -h|--help) usage; exit 0 ;;
    -V|--version) echo "FUN v1.2.0"; exit 0 ;;
    "") ;;
    *) echo -e "${ROJO}Opción desconocida: $1${NC}" >&2; usage >&2; exit 2 ;;
esac

if (( $# > 1 )); then
    echo -e "${ROJO}Demasiados argumentos.${NC}" >&2
    usage >&2
    exit 2
fi

echo -e "${AZUL_CLARO}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${AZUL_CLARO}║              🚀 INICIANDO MANTENIMIENTO FUN 🚀               ║${NC}"
echo -e "${AZUL_CLARO}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${AMARILLO}🔐 Se te pedirá tu contraseña UNA sola vez para todas las tareas.${NC}"
echo -e "${AMARILLO}   Escríbela cuando aparezca el prompt.${NC}"
echo ""
sudo -v || { echo -e "${ROJO}❌ Contraseña incorrecta o cancelada. Saliendo.${NC}" >&2; exit 1; }
( while true; do sudo -n true; sleep 50; done ) >/dev/null 2>&1 &
KEEPALIVE_PID=$!
trap 'kill "$KEEPALIVE_PID" 2>/dev/null || true' EXIT
echo -e "${VERDE}✅ Contraseña aceptada. Comenzando...${NC}"
echo ""

ESTADO_SISTEMA="${AMARILLO}Pendiente${NC}"
ESTADO_FLATPAK="${AMARILLO}Pendiente${NC}"
ESTADO_SPICES="${AMARILLO}Pendiente${NC}"
ESTADO_LIMPIEZA="${AMARILLO}Pendiente${NC}"
LIMPIEZA_OK=1

DISCO_INICIAL_MB=$(df -m / | awk 'NR==2 {print $4}')

echo -e "${VERDE}[1/7] Iniciando proceso de actualización del sistema...${NC}"
echo -e "${AMARILLO}--------------------------------------------------------------${NC}"
echo -e "${AZUL_CLARO}⏳ Por favor, espera un momento.${NC}"
echo -e "${AMARILLO}💡 NOTA: Esto puede demorar algunos segundos...${NC}"
echo -e "${AZUL_CLARO}   La velocidad depende de tu conexión y de actualizaciones pendientes.${NC}"
echo -e "${AMARILLO}--------------------------------------------------------------${NC}"
echo -e "${VERDE}   Sincronizando repositorios (verás cada repo abajo)...${NC}"
echo ""

LOG_UPDATE="/tmp/fun_apt_update.log"
: > "$LOG_UPDATE"
sudo apt-get update > "$LOG_UPDATE" 2>&1 &
PID_UPDATE=$!
tail -f "$LOG_UPDATE" 2>/dev/null &
TAIL_PID=$!
if wait "$PID_UPDATE"; then
    UPDATE_OK=1
else
    UPDATE_OK=0
fi
kill "$TAIL_PID" 2>/dev/null || true
wait "$TAIL_PID" 2>/dev/null || true
if (( ! UPDATE_OK )); then
    echo -e "${ROJO}❌ Falló la sincronización de repositorios.${NC}" >&2
    tail -n 20 "$LOG_UPDATE" >&2 || true
    exit 1
fi
echo ""
echo -e "${VERDE}   ✅ Repositorios sincronizados.${NC}"

missing_keys=$(grep -o "NO_PUBKEY [A-Z0-9]*" "$LOG_UPDATE" 2>/dev/null | awk '{print $2}' | sort -u || true)
if [ -n "$missing_keys" ]; then
    echo -e "${AMARILLO}   ⚠️ Claves GPG faltantes detectadas (no se importarán automáticamente):${NC}"
    for key in $missing_keys; do echo "      $key"; done
    echo -e "${AMARILLO}   Ajusta esos repositorios con [signed-by=/ruta/a/clave.gpg].${NC}"
fi
rm -f "$LOG_UPDATE"

if ! command -v nala >/dev/null 2>&1; then
    echo -e "${AMARILLO}[fun] Instalando Nala...${NC}"
    if ! sudo apt install -y nala; then
        echo -e "${ROJO}No se pudo instalar Nala. Saliendo.${NC}" >&2
        exit 1
    fi
fi

if ! command -v sensors >/dev/null 2>&1; then
    echo -e "${AMARILLO}[fun] Instalando lm-sensors para leer la temperatura...${NC}"
    if sudo apt install -y lm-sensors >/dev/null 2>&1; then
        sudo sensors-detect --auto >/dev/null 2>&1 || true
    else
        echo -e "${AMARILLO}[fun] No se pudo instalar lm-sensors; se usará /sys/class/thermal.${NC}"
    fi
fi

echo ""
echo -e "${VERDE}   Comprobando si hay paquetes por actualizar...${NC}"
UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || true)
if [ "$UPGRADABLE" -eq 0 ]; then
    ESTADO_SISTEMA="${VERDE}Ya está actualizado${NC}"
    echo -e "${VERDE}   ✅ El sistema ya está actualizado. Saltando descarga.${NC}"
else
    echo -e "${AMARILLO}   Hay $UPGRADABLE paquete(s) por actualizar. Procediendo...${NC}"
    echo -e "${VERDE}   Descargando e instalando actualizaciones...${NC}"
    if sudo nala upgrade -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold; then
        ESTADO_SISTEMA="${VERDE}Actualizado con Nala${NC}"
        echo -e "${VERDE}   ✅ Actualizaciones aplicadas.${NC}"
    else
        ESTADO_SISTEMA="${AMARILLO}⚠️ Actualización incompleta${NC}"
        echo -e "${AMARILLO}   ⚠️ Algunas actualizaciones no se aplicaron. Revisa Nala.${NC}"
    fi
fi

echo -e "${VERDE}[2/7] Eliminando huérfanos...${NC}"
if ! sudo nala autoremove -y; then
    LIMPIEZA_OK=0
    echo -e "${AMARILLO}   ⚠️ No se pudieron eliminar todos los huérfanos.${NC}"
fi

echo -e "${VERDE}[3/7] Limpiando caché y logs...${NC}"
if ! sudo nala clean >/dev/null 2>&1; then LIMPIEZA_OK=0; fi
if ! sudo journalctl --vacuum-time=7d >/dev/null 2>&1; then LIMPIEZA_OK=0; fi

echo -e "${VERDE}[4/7] Gestionando Flatpak...${NC}"
if command -v flatpak >/dev/null 2>&1; then
    if flatpak update -y >/dev/null 2>&1 && flatpak uninstall --unused -y >/dev/null 2>&1; then
        ESTADO_FLATPAK="${VERDE}Actualizado y limpio${NC}"
    else
        ESTADO_FLATPAK="${AMARILLO}⚠️ Actualización incompleta${NC}"
    fi
else
    ESTADO_FLATPAK="${AMARILLO}No instalado${NC}"
fi

echo -e "${VERDE}[5/7] Actualizando Cinnamon Spices...${NC}"
if command -v cinnamon-spice-updater >/dev/null 2>&1; then
    if cinnamon-spice-updater --update-all >/dev/null 2>&1; then
        ESTADO_SPICES="${VERDE}Actualizados${NC}"
    else
        ESTADO_SPICES="${AMARILLO}⚠️ No se completó la actualización${NC}"
    fi
else
    ESTADO_SPICES="${AMARILLO}No disponible${NC}"
fi

echo -e "${VERDE}[6/7] Limpiando .deb viejos y miniaturas...${NC}"
for descargas in "$HOME/Downloads" "$HOME/Descargas"; do
    [ -d "$descargas" ] || continue
    find "$descargas" -maxdepth 1 -name "*.deb" -type f -mtime +7 -delete 2>/dev/null || LIMPIEZA_OK=0
done
rm -rf "$HOME/.cache/thumbnails"/* 2>/dev/null || LIMPIEZA_OK=0
if (( LIMPIEZA_OK )); then
    ESTADO_LIMPIEZA="${VERDE}Caché, logs, miniaturas y .deb${NC}"
else
    ESTADO_LIMPIEZA="${AMARILLO}⚠️ Limpieza parcial${NC}"
fi

DISCO_FINAL_MB=$(df -m / | awk 'NR==2 {print $4}')
ESPACIO_RECUPERADO_MB=$((DISCO_FINAL_MB - DISCO_INICIAL_MB))
if [ "$ESPACIO_RECUPERADO_MB" -gt 0 ]; then
    ESPACIO_TXT="$ESPACIO_RECUPERADO_MB MB"
else
    ESPACIO_TXT="0 MB (sin ganancia neta)"
fi

echo -e "${VERDE}[7/7] Reporte de Salud...${NC}"
kernel_version=$(uname -r)
ram_info=$(free -h | awk '/^Mem:/ {print $7 " libres (de " $2 ")"}')
disk_info=$(df -h / | awk 'NR==2 {print $4 " disponibles (" $5 " usado de " $2 ")"}')
fecha_actual=$(date +"%d/%m/%Y - %I:%M %p")

cpu_temp=$(sensors 2>/dev/null | grep -m 1 -oE '[+-]?[0-9]+(\.[0-9]+)?[[:space:]]*°?C' | tr -d ' ' || true)
if [ -z "$cpu_temp" ] && [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || true)
    [[ "$temp_raw" =~ ^[0-9]+$ ]] && cpu_temp="$(( temp_raw / 1000 )) °C"
fi
[ -z "$cpu_temp" ] && cpu_temp="No disponible"

DISK_LOG=$(timeout 2s sudo dmesg 2>/dev/null || true)
if grep -qiE "EXT4-fs error|I/O error" <<< "$DISK_LOG"; then
    disk_health="${AMARILLO}⚠️ Posibles anomalías en el disco.${NC}"
    disk_advice="👉 Revisa con LiveUSB: sudo fsck -f /dev/sdX"
else
    disk_health="${VERDE}✅ OK (sin errores en logs recientes)${NC}"
    disk_advice=""
fi

echo -e "\n${AZUL_CLARO}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${AZUL_CLARO}║           📊 RESUMEN AMPLIADO DE MANTENIMIENTO 📊            ║${NC}"
echo -e "${AZUL_CLARO}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${AZUL_CLARO}║${NC} 🔄 Sistema:          $ESTADO_SISTEMA"
echo -e "${AZUL_CLARO}║${NC} 📦 Flatpak:          $ESTADO_FLATPAK"
echo -e "${AZUL_CLARO}║${NC} 📦 AppImages:        ${AMARILLO}Formato portátil (manual)${NC}"
echo -e "${AZUL_CLARO}║${NC} 🧹 Limpieza:         $ESTADO_LIMPIEZA"
echo -e "${AZUL_CLARO}║${NC} 🧹 Spices:           $ESTADO_SPICES"
echo -e "${AZUL_CLARO}║${NC} 💾 Espacio neto:     ${VERDE} $ESPACIO_TXT${NC}"
echo -e "${AZUL_CLARO}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${AZUL_CLARO}║${NC} 🩺 SALUD DEL SISTEMA:${NC}"
echo -e "${AZUL_CLARO}║${NC} 🐧 Kernel:    ${VERDE}$kernel_version${NC}"
echo -e "${AZUL_CLARO}║${NC} 🌡️ CPU:      ${VERDE}$cpu_temp${NC}"
echo -e "${AZUL_CLARO}║${NC} 🧠 RAM:      ${VERDE}$ram_info${NC}"
echo -e "${AZUL_CLARO}║${NC} 💽 Disco:    ${VERDE}$disk_info${NC}"
echo -e "${AZUL_CLARO}║${NC} 🛡️ Estado:   $disk_health${NC}"
if [ -n "$disk_advice" ]; then echo -e "${AZUL_CLARO}║${NC} ⚠️ Sugerencia: ${AMARILLO}$disk_advice${NC}"; fi
echo -e "${AZUL_CLARO}╚══════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${AZUL_CLARO}════════════════════════════════════════════════════════════════${NC}"
echo -e "${AZUL_CLARO}                                                                ${NC}"
echo -e "${NEGRITA}${AMARILLO}        ✅   ¡MANTENIMIENTO COMPLETADO CON ÉXITO!   ✅${NC}"
echo -e "${AZUL_CLARO}                                                                ${NC}"
echo -e "${AZUL_CLARO}              🚀  El Abuelazo Tech - FUN v1.2.0                  ${NC}"
echo -e "${AZUL_CLARO}                                                                ${NC}"
echo -e "${AZUL_CLARO}              📅  $fecha_actual                        ${NC}"
echo -e "${AZUL_CLARO}                                                                ${NC}"
echo -e "${AZUL_CLARO}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${AMARILLO}¿Deseas guardar un reporte de este mantenimiento en el Escritorio?${NC}"
read -r -p "Escribe 's' para Sí, o pulsa Enter para omitir: " GUARDAR_REPORTE || true
if [[ "${GUARDAR_REPORTE:-}" =~ ^[sS]$ ]]; then
    DIRECTORIO_REPORTE="$HOME/Escritorio"
    [ -d "$DIRECTORIO_REPORTE" ] || DIRECTORIO_REPORTE="$HOME/Desktop"
    mkdir -p "$DIRECTORIO_REPORTE" 2>/dev/null || true
    REPORTE="$DIRECTORIO_REPORTE/Reporte_FUN_$(date +%Y%m%d_%H%M).txt"
    if {
        echo "=================================================="
        echo "      REPORTE DE SALUD - FUN (El Abuelazo Tech)   "
        echo "=================================================="
        echo "Fecha: $fecha_actual"
        echo "Versión: 1.2.0"
        echo "Sistema: $(echo "$ESTADO_SISTEMA" | sed 's/\x1b\[[0-9;]*m//g')"
        echo "Flatpak: $(echo "$ESTADO_FLATPAK" | sed 's/\x1b\[[0-9;]*m//g')"
        echo "Limpieza: $(echo "$ESTADO_LIMPIEZA" | sed 's/\x1b\[[0-9;]*m//g')"
        echo "Spices: $(echo "$ESTADO_SPICES" | sed 's/\x1b\[[0-9;]*m//g')"
        echo "Kernel: $kernel_version"
        echo "Temperatura CPU: $cpu_temp"
        echo "Memoria RAM: $ram_info"
        echo "Disco: $disk_info"
        echo "Espacio neto: $ESPACIO_TXT"
        echo "Estado del disco: $(echo "$disk_health" | sed 's/\x1b\[[0-9;]*m//g')"
        echo "=================================================="
    } > "$REPORTE" 2>/dev/null; then
        echo -e "${VERDE}📄 Reporte guardado en: $REPORTE${NC}"
    else
        echo -e "${AMARILLO}⚠️ No se pudo guardar el reporte.${NC}"
    fi
else
    echo -e "${AZUL_CLARO}📄 Reporte no guardado.${NC}"
fi

PENDING_UPDATES=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || true)
if [ "$PENDING_UPDATES" -gt 0 ]; then
    if command -v zenity >/dev/null 2>&1; then
        if zenity --question --title="El Abuelazo Tech - FUN" \
        --text="Hay $PENDING_UPDATES actualizaciones pendientes.\n\n¿Quieres abrir el Gestor de Actualizaciones ahora?" \
        --ok-label="Sí, abrir" --cancel-label="No, luego" 2>/dev/null; then
            if command -v mintupdate >/dev/null 2>&1; then
                mintupdate >/dev/null 2>&1 &
            fi
        fi
    else
        echo -e "${AMARILLO}Hay $PENDING_UPDATES actualizaciones pendientes. Abre el Gestor de Actualizaciones cuando quieras.${NC}"
    fi
fi

echo -e "${VERDE}🏁 Diagnóstico finalizado con FUN v1.2.0 - El Abuelazo Tech${NC}"
echo ""

read -r -p "Presiona Enter para salir..." || true
