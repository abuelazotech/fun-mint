#!/usr/bin/env bash
# ==============================================================================
# Nombre de la Herramienta: FUN (Script de Mantenimiento y Salud para Linux Mint)
# Autor: El Abuelazo Tech
# Descripción: Automatiza actualización, limpieza y diagnóstico de salud del sistema.
# ==============================================================================

FUN_BIN_DIR="$HOME/.local/bin"
FUN_TARGET="$FUN_BIN_DIR/fun"

# ------------------------------------------------------------------------------
# FASE DE INSTALACIÓN (Solo se ejecuta al abrir 'instalar-fun.sh')
# ------------------------------------------------------------------------------
if [ "$(realpath "$0")" != "$(realpath "$FUN_TARGET" 2>/dev/null)" ]; then
    mkdir -p "$FUN_BIN_DIR"
    cp "$0" "$FUN_TARGET"
    chmod +x "$FUN_TARGET"

    if [[ ":$PATH:" != *":$FUN_BIN_DIR:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi

    # Ventana emergente gráfica de confirmación
    if command -v zenity &> /dev/null; then
        zenity --info \
               --title="El Abuelazo Tech - FUN" \
               --text="<b>¡Instalación completada con éxito!</b>\n\nPresione <b>Aceptar</b> para abrir la terminal. Luego escriba <b>fun</b> y presione Enter para iniciar el mantenimiento." \
               --width=380 2>/dev/null
    fi

    # Abre la terminal predeterminada del sistema para que el usuario pruebe de inmediato
    if command -v x-terminal-emulator &> /dev/null; then
        x-terminal-emulator &
    elif command -v gnome-terminal &> /dev/null; then
        gnome-terminal &
    elif command -v xfce4-terminal &> /dev/null; then
        xfce4-terminal &
    fi

    exit 0
fi

# ------------------------------------------------------------------------------
# FASE DE EJECUCIÓN DEL MANTENIMIENTO (Al escribir 'fun' en la terminal)
# ------------------------------------------------------------------------------

# Colores brillantes de alto contraste (Optimizados para legibilidad)
VERDE='\033[1;92m'    # Verde brillante/esmeralda
AZUL_CLARO='\033[1;96m' # Cian brillante (muy legible)
AMARILLO='\033[1;93m'  # Amarillo brillante
NC='\033[0m'          # Sin color

echo -e "${AZUL_CLARO}[fun] Iniciando mantenimiento del sistema...${NC}"

# 1/6 Actualización e instalación con Nala (incluyendo reparación automática GPG)
echo -e "${VERDE}[fun] 1/6 Actualizando e instalando paquetes con Nala (incluyendo Kernel)...${NC}"
missing_keys=$(sudo apt update 2>&1 | grep -o "NO_PUBKEY [A-Z0-9]*" | awk '{print $2}')
if [ -n "$missing_keys" ]; then
    echo -e "${AMARILLO}[fun] Detectadas claves GPG ausentes. Importando automáticamente...${NC}"
    for key in $missing_keys; do
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key" 2>/dev/null || \
        sudo gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key" 2>/dev/null
    done
fi
sudo nala update && sudo nala upgrade -y

# 2/6 Eliminación de paquetes innecesarios
echo -e "${VERDE}[fun] 2/6 Eliminando paquetes innecesarios...${NC}"
sudo nala autoremove -y

# 3/6 Limpieza de caché de paquetes y registros antiguos de journal
echo -e "${VERDE}[fun] 3/6 Limpiando caché de paquetes y logs antiguos...${NC}"
sudo nala clean
sudo journalctl --vacuum-time=7d >/dev/null 2>&1

# 4/6 Actualización y limpieza de Flatpaks
echo -e "${VERDE}[fun] 4/6 Actualizando aplicaciones Flatpak y limpiando huérfanos...${NC}"
flatpak update -y
flatpak uninstall --unused -y

# 5/6 Actualización de complementos de Cinnamon (Spices)
echo -e "${VERDE}[fun] 5/6 Actualizando complementos de Cinnamon...${NC}"
if command -v cinnamon-spice-updater &> /dev/null; then
    cinnamon-spice-updater --upgrade || echo "No hay actualizaciones de Spices pendientes."
else
    echo "El actualizador de Cinnamon Spices no está disponible en este entorno."
fi

# 6/6 Limpieza de caché de miniaturas del usuario
echo -e "${VERDE}[fun] 6/6 Limpiando caché temporal de miniaturas...${NC}"
rm -rf ~/.cache/thumbnails/* 2>/dev/null

# 7/7 Reporte de Salud del Sistema y Diagnóstico
echo -e "${VERDE}[fun] 7/7 Generando Reporte de Salud del Sistema...${NC}"

kernel_version=$(uname -r)
ram_info=$(free -h | awk '/^Mem:/ {print $7 " libres (de " $2 ")"}')
disk_info=$(df -h / | awk 'NR==2 {print $4 " disponibles (" $5 " usado de " $2 ")"}')
fecha_actual=$(date +"%d/%m/%Y - %I:%M %p")

cpu_temp="No disponible"
if command -v sensors &> /dev/null; then
    cpu_temp=$(sensors 2>/dev/null | awk '/Tctl|Package id 0|Core 0/ {print $3; exit}')
    [ -z "$cpu_temp" ] && cpu_temp=$(sensors 2>/dev/null | grep -m 1 "°C" | awk '{print $2}')
fi
if [ "$cpu_temp" = "No disponible" ] && [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    temp_raw=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    [[ "$temp_raw" =~ ^[0-9]+$ ]] && cpu_temp="$(( temp_raw / 1000 )) °C"
fi

if dmesg | grep -i -E "EXT4-fs error|I/O error" &> /dev/null; then
    disk_health="${AMARILLO}⚠️ ATENCIÓN: Se detectaron posibles anomalías en el disco en los logs.${NC}"
    disk_advice="\n 👉 Sugerencia: Revisa el sistema con un LiveUSB usando 'sudo fsck -f /dev/sdX'"
else
    disk_health="${VERDE}OK (Sin errores críticos detectados en logs)${NC}"
    disk_advice=""
fi

echo -e "${AZUL_CLARO}============================================================${NC}"
echo -e "${AZUL_CLARO}            📊 RESUMEN DE SALUD Y ESTADO DEL SISTEMA${NC}"
echo -e "${AZUL_CLARO}============================================================${NC}"
echo -e " 🐧 Kernel activo:        ${VERDE}$kernel_version${NC}"
echo -e " 🌡️ Temperatura CPU:      ${VERDE}$cpu_temp${NC}"
echo -e " 🧠 Memoria RAM libre:    ${VERDE}$ram_info${NC}"
echo -e " 💽 Disco Principal (/): ${VERDE}$disk_info${NC}"
echo -e " 🛡️ Estado del Disco:     $disk_health"
[ -n "$disk_advice" ] && echo -e "$disk_advice"
echo -e "${AZUL_CLARO}============================================================${NC}"

# Mensaje final altamente visible y resaltado en azul eléctrico con negrita
echo -e "\n${AZUL_CLARO}\033[1m🚀 [fun] ¡Mantenimiento y diagnóstico completados correctamente! ($fecha_actual) 🚀${NC}\n"
