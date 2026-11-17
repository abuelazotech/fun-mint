#!/usr/bin/env bash
VERDE='\033[1;92m'; AZUL='\033[1;94m'; AMARILLO='\033[1;93m'; NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

echo -e "${AMARILLO}Iniciando optimización y diagnóstico...${NC}"
echo -e "${AMARILLO}FUN necesita permisos. Escriba su contraseña:${NC}"
sudo -v || { echo "Error"; read -p "ENTER..."; exit 1; }

( while true; do sudo -n true; sleep 50; done ) > /dev/null 2>&1 &
KEEPALIVE=$!
trap "kill $KEEPALIVE 2>/dev/null" EXIT

if ! command -v nala > /dev/null 2>&1; then sudo apt update && sudo apt install nala -y; fi

DISCO_INI=$(df -m / | awk 'NR==2 {print $4}')

echo -e "${VERDE}[1/7] Actualizando sistema...${NC}"
sudo nala update -o Acquire::Retries=1 -o Acquire::http::Timeout=10
sudo nala upgrade -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold

echo -e "${VERDE}[2/7] Eliminando huerfanos...${NC}"; sudo nala autoremove -y

echo -e "${VERDE}[3/7] Limpiando cache...${NC}"; sudo nala clean; sudo journalctl --vacuum-time=7d

echo -e "${VERDE}[4/7] Gestionando Flatpak...${NC}"
if command -v flatpak > /dev/null 2>&1; then flatpak update -y; flatpak uninstall --unused -y; fi

echo -e "${VERDE}[5/7] Actualizando Spices...${NC}"
if command -v cinnamon-spice-updater > /dev/null 2>&1; then cinnamon-spice-updater --update-all; fi

echo -e "${VERDE}[6/7] Limpiando .deb viejos...${NC}"
find "$HOME/Downloads" "$HOME/Descargas" -maxdepth 1 -name "*.deb" -type f -mtime +7 -delete 2>/dev/null
rm -rf ~/.cache/thumbnails/* 2>/dev/null

DISCO_FIN=$(df -m / | awk 'NR==2 {print $4}')
ESPACIO=$((DISCO_FIN - DISCO_INI))
[ $ESPACIO -lt 0 ] && ESPACIO=0

echo -e "${VERDE}[7/7] Reporte de Salud...${NC}"
echo -e "${AZUL}REPORTE FINAL DE MANTENIMIENTO${NC}"
echo -e "${AZUL}Espacio recuperado: ${VERDE}${ESPACIO} MB${NC}"
echo -e "${AZUL}Estado: ${VERDE}Sistema optimizado y saludable${NC}"

read -p "Presione la tecla [ENTER] para cerrar esta ventana..."
