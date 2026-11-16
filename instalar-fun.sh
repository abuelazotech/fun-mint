#!/usr/bin/env bash
# ==============================================================================
# Nombre de la Herramienta: FUN (Script de Mantenimiento y Salud para Linux Mint)
# Autor: El Abuelazo Tech
# Versión: 1.1 (Final - Ultrarrápida y corregida)
# ==============================================================================

FUN_BIN_DIR="$HOME/.local/bin"
FUN_TARGET="$FUN_BIN_DIR/fun"

if [ "$(realpath "$0")" != "$(realpath "$FUN_TARGET" 2>/dev/null)" ]; then
    if [ "$EUID" -eq 0 ]; then
        echo -e "\033[1;91m[fun] ERROR: No ejecutes el instalador con sudo.\033[0m"
        exit 1
    fi
    mkdir -p "$FUN_BIN_DIR"
    cp "$0" "$FUN_TARGET"
    chmod +x "$FUN_TARGET"
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
    fi
    if command -v zenity &> /dev/null; then
        zenity --question --title="El Abuelazo Tech - FUN v1.1" \
        --text="<b>¡Instalación completada!</b>\n\n¿Desea abrir la terminal para practicar?" \
        --ok-label="Sí, practicar" --cancel-label="No, gracias" 2>/dev/null
        if [ $? -eq 0 ]; then
            TERMINAL_CMD="echo '===================================================='; echo '  ¡Excelente! Escribe:'; echo '                     fun'; echo '  y presiona ENTER.'; echo '===================================================='; read -p 'Escríbelo aquí: ' RESPUESTA; if [ \"\$RESPUESTA\" = \"fun\" ]; then echo '¡Muy bien! Ejecutando...'; $FUN_TARGET; read -p 'Presiona Enter para salir...'; else echo 'Escribiste: '\$RESPUESTA'. Recuerda: fun'; read -p 'Presiona Enter para salir...'; fi"
            if command -v x-terminal-emulator &> /dev/null; then x-terminal-emulator -e bash -c "$TERMINAL_CMD" &
            elif command -v gnome-terminal &> /dev/null; then gnome-terminal -- bash -c "$TERMINAL_CMD" &
            elif command -v xfce4-terminal &> /dev/null; then xfce4-terminal -x bash -c "$TERMINAL_CMD" & fi
        fi
    fi
    exit 0
fi

VERDE='\033[1;92m'; AZUL_CLARO='\033[1;96m'; AMARILLO='\033[1;93m'; NC='\033[0m'

echo -e "${AZUL_CLARO}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${AZUL_CLARO}║              🚀 INICIANDO MANTENIMIENTO FUN 🚀               ║${NC}"
echo -e "${AZUL_CLARO}╚══════════════════════════════════════════════════════════════╝${NC}"

if ! command -v nala &> /dev/null; then
    echo -e "${AMARILLO}[fun] Instalando Nala...${NC}"; sudo apt update && sudo apt install nala -y
fi

DISCO_INICIAL_MB=$(df -m / | awk 'NR==2 {print $4}')

echo -e "${VERDE}[1/7] Actualizando con Nala...${NC}"
missing_keys=$(sudo nala update 2>&1 | grep -o "NO_PUBKEY [A-Z0-9]*" | awk '{print $2}')
if [ -n "$missing_keys" ]; then
    for key in $missing_keys; do
        sudo gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key" 2>/dev/null
        sudo gpg --export "$key" | sudo tee /etc/apt/trusted.gpg.d/missing_key_$key.gpg > /dev/null 2>&1
    done
fi
sudo nala update && sudo nala upgrade -y

echo -e "${VERDE}[2/7] Eliminando huérfanos...${NC}"; sudo nala autoremove -y
echo -e "${VERDE}[3/7] Limpiando caché y logs...${NC}"; sudo nala clean; sudo journalctl --vacuum-time=7d >/dev/null 2>&1

echo -e "${VERDE}[4/7] Gestionando Flatpak...${NC}"
if command -v flatpak &> /dev/null; then flatpak update -y >/dev/null 2>&1; flatpak uninstall --unused -y >/dev/null 2>&1; else echo -e "${AMARILLO}[fun] Flatpak no instalado.${NC}"; fi

echo -e "${VERDE}[5/7] Actualizando Cinnamon Spices...${NC}"
if command -v cinnamon-spice-updater &> /dev/null; then cinnamon-spice-updater --update-all >/dev/null 2>&1 || echo -e "${AMARILLO}[fun] Sin actualizaciones de Spices.${NC}"; else echo -e "${AMARILLO}[fun] Spices no disponible.${NC}"; fi

echo -e "${VERDE}[6/7] Limpiando .deb viejos y miniaturas...${NC}"
find "$HOME/Downloads" "$HOME/Descargas" -maxdepth 1 -name "*.deb" -type f -mtime +7 -delete 2>/dev/null
rm -rf ~/.cache/thumbnails/* 2>/dev/null

DISCO_FINAL_MB=$(df -m / | awk 'NR==2 {print $4}')
ESPACIO_RECUPERADO_MB=$((DISCO_FINAL_MB - DISCO_INICIAL_MB))
if [ $ESPACIO_RECUPERADO_MB -lt 0 ]; then ESPACIO_RECUPERADO_MB=0; fi
[ "$ESPACIO_RECUPERADO_MB" -eq 0 ] && ESPACIO_TXT="0 MB ✅ (sistema optimizado)" || ESPACIO_TXT="$ESPACIO_RECUPERADO_MB MB"

echo -e "${VERDE}[7/7] Reporte de Salud...${NC}"
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
    disk_health="${AMARILLO}⚠️ Posibles anomalías en el disco.${NC}"; disk_advice="👉 Revisa con LiveUSB: sudo fsck -f /dev/sdX"
else
    disk_health="${VERDE}✅ OK (Sin errores en logs)${NC}"; disk_advice=""
fi

echo -e "\n${AZUL_CLARO}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${AZUL_CLARO}║           📊 RESUMEN AMPLIADO DE MANTENIMIENTO 📊            ║${NC}"
echo -e "${AZUL_CLARO}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${AZUL_CLARO}║${NC} 🔄 Sistema:          ${VERDE}Actualizado con Nala${NC}"
echo -e "${AZUL_CLARO}║${NC} 📦 Flatpak:          ${VERDE}Actualizado y limpio${NC}"
echo -e "${AZUL_CLARO}║${NC} 📦 AppImages:        ${AMARILLO}Formato portátil (manual)${NC}"
echo -e "${AZUL_CLARO}║${NC} 🧹 Limpieza:         ${VERDE}Caché, Journal, Miniaturas y .deb viejos${NC}"
echo -e "${AZUL_CLARO}║${NC} 💾 Espacio Recuperado:${VERDE} $ESPACIO_TXT${NC}"
echo -e "${AZUL_CLARO}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${AZUL_CLARO}║${NC} 🩺 SALUD DEL SISTEMA:${NC}"
echo -e "${AZUL_CLARO}║${NC} 🐧 Kernel:    ${VERDE}$kernel_version${NC}"
echo -e "${AZUL_CLARO}║${NC} 🌡️ CPU:      ${VERDE}$cpu_temp${NC}"
echo -e "${AZUL_CLARO}║${NC} 🧠 RAM:      ${VERDE}$ram_info${NC}"
echo -e "${AZUL_CLARO}║${NC} 💽 Disco:    ${VERDE}$disk_info${NC}"
echo -e "${AZUL_CLARO}║${NC} 🛡️ Estado:   $disk_health${NC}"
[ -n "$disk_advice" ] && echo -e "${AZUL_CLARO}║${NC} ⚠️ Sugerencia: ${AMARILLO}$disk_advice${NC}"
echo -e "${AZUL_CLARO}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "${AZUL_CLARO}\n🚀 [fun] ¡Mantenimiento completado! ($fecha_actual) 🚀${NC}\n"

PENDING_UPDATES=$(nala list --upgradable 2>/dev/null | grep -c "upgradable" || echo 0)
PENDING_UPDATES=$(echo "$PENDING_UPDATES" | tr -cd '0-9'); [ -z "$PENDING_UPDATES" ] && PENDING_UPDATES=0

if [ "$PENDING_UPDATES" -gt 0 ]; then
    if command -v zenity &> /dev/null; then
        if zenity --question --title="El Abuelazo Tech - FUN" \
        --text="Hay actualizaciones pendientes.\n\n¿Abrir el Gestor de Actualizaciones?" \
        --ok-label="Sí, abrir" --cancel-label="No" 2>/dev/null; then
            command -v mintupdate &> /dev/null && mintupdate >/dev/null 2>&1 &
        fi
    fi
fi
