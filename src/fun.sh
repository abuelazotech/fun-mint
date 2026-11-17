#!/usr/bin/env bash
# ==============================================================================
# Nombre: FUN v2 (Script de Mantenimiento y Salud para Linux Mint)
# Autor: El Abuelazo Tech
# Versión: 2.0.0 (Limpio, rápido y sin lógica de instalación)
# ==============================================================================

VERDE='[1;92m'; AZUL_CLARO='[1;96m'; AMARILLO='[1;93m'; NC='[0m'

echo -e "${AZUL_CLARO}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${AZUL_CLARO}║              🚀 INICIANDO MANTENIMIENTO FUN v2 🚀            ║${NC}"
echo -e "${AZUL_CLARO}╚══════════════════════════════════════════════════════════════╝${NC}"

# 1. Verificar e instalar Nala si no existe
if ! command -v nala &> /dev/null; then
    echo -e "${AMARILLO}[fun] Instalando Nala...${NC}"
    sudo apt update && sudo apt install nala -y
fi

DISCO_INICIAL_MB=$(df -m / | awk 'NR==2 {print $4}')

echo -e "${VERDE}[1/7] Actualizando con Nala...${NC}"
UPDATE_OUTPUT=$(sudo nala update 2>&1)
missing_keys=$(echo "$UPDATE_OUTPUT" | grep -o "NO_PUBKEY [A-Z0-9]*" | awk '{print $2}')

if [ -n "$missing_keys" ]; then
    echo -e "${AMARILLO}🔑 Importando claves de repositorio faltantes...${NC}"
    for key in $missing_keys; do
        sudo gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options timeout=5 --recv-keys "$key" 2>/dev/null
        sudo gpg --export "$key" | sudo tee /etc/apt/trusted.gpg.d/missing_key_$key.gpg > /dev/null 2>&1
    done
    sudo nala update >/dev/null 2>&1
fi

sudo nala upgrade -y

echo -e "${VERDE}[2/7] Eliminando paquetes huérfanos...${NC}"; sudo nala autoremove -y
echo -e "${VERDE}[3/7] Limpiando caché y logs antiguos...${NC}"; sudo nala clean; sudo journalctl --vacuum-time=7d >/dev/null 2>&1

echo -e "${VERDE}[4/7] Gestionando Flatpak...${NC}"
if command -v flatpak &> /dev/null; then
    flatpak update -y >/dev/null 2>&1
    flatpak uninstall --unused -y >/dev/null 2>&1
else
    echo -e "${AMARILLO}[fun] Flatpak no instalado.${NC}"
fi

echo -e "${VERDE}[5/7] Actualizando Cinnamon Spices...${NC}"
if command -v cinnamon-spice-updater &> /dev/null; then
    cinnamon-spice-updater --update-all >/dev/null 2>&1 || echo -e "${AMARILLO}[fun] Sin actualizaciones de Spices.${NC}"
else
    echo -e "${AMARILLO}[fun] Spices no disponible.${NC}"
fi

echo -e "${VERDE}[6/7] Limpiando archivos .deb viejos y miniaturas...${NC}"
find "$HOME/Downloads" "$HOME/Descargas" -maxdepth 1 -name "*.deb" -type f -mtime +7 -delete 2>/dev/null
rm -rf ~/.cache/thumbnails/* 2>/dev/null

DISCO_FINAL_MB=$(df -m / | awk 'NR==2 {print $4}')
ESPACIO_RECUPERADO_MB=$((DISCO_FINAL_MB - DISCO_INICIAL_MB))
if [ $ESPACIO_RECUPERADO_MB -lt 0 ]; then ESPACIO_RECUPERADO_MB=0; fi
[ "$ESPACIO_RECUPERADO_MB" -eq 0 ] && ESPACIO_TXT="0 MB ✅ (sistema ya optimizado)" || ESPACIO_TXT="$ESPACIO_RECUPERADO_MB MB"

echo -e "${VERDE}[7/7] Generando Reporte de Salud...${NC}"
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

echo -e "${AZUL_CLARO}══════════════════════════════════════════════════════════════${NC}"
echo -e "${VERDE}✅ ¡Diagnóstico y optimización completados con éxito!${NC}"
echo -e "${AZUL_CLARO}══════════════════════════════════════════════════════════════${NC}"
read -p $'\nPresiona la tecla [ENTER] para cerrar esta ventana...'
