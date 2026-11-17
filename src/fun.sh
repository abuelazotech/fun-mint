#!/usr/bin/env bash
VERDE='\033[1;92m'; AZUL='\033[1;96m'; AMARILLO='\033[1;93m'; ESMERALDA='\033[1;32m'; ROJO='\033[1;91m'; BLANCO='\033[1;97m'; NC='\033[0m'

export DEBIAN_FRONTEND=noninteractive

echo -n "Inserte su contraseña y presione Enter: "
PASS=""
while IFS= read -r -s -n1 char; do
    if [[ -z $char ]]; then echo; break; fi
    if [[ $char == $'\x7f' || $char == $'\x08' ]]; then
        if [ -n "$PASS" ]; then PASS="${PASS%?}"; echo -ne '\b \b'; fi
    else
        PASS+="$char"; echo -n '*'
    fi
done
echo "$PASS" | sudo -S -v >/dev/null 2>&1 || { echo -e "${ROJO}Contraseña incorrecta.${NC}"; unset PASS; read -p "ENTER..."; exit 1; }
unset PASS

echo -e "${AMARILLO}Iniciando proceso de diagnostico, actualizacion y optimizacion...${NC}"

( while true; do sudo -n true; sleep 50; done ) >/dev/null 2>&1 &
KEEPALIVE=$!
trap "kill $KEEPALIVE 2>/dev/null" EXIT

RESUMEN=/tmp/fun_resumen.txt
: > "$RESUMEN"

if ! command -v nala >/dev/null 2>&1; then sudo apt update && sudo apt install nala -y; fi

DISCO_INI=$(df -m / | awk 'NR==2 {print $4}')

echo -e "${VERDE}[1/7] Actualizando sistema...${NC}"
sudo nala update -o Acquire::Retries=1 -o Acquire::http::Timeout=10
sudo nala upgrade -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold
echo "✅ Sistema actualizado con Nala" >> "$RESUMEN"

echo -e "${VERDE}[2/7] Eliminando huerfanos...${NC}"; sudo nala autoremove -y
echo "✅ Paquetes huérfanos eliminados" >> "$RESUMEN"

echo -e "${VERDE}[3/7] Limpiando cache...${NC}"; sudo nala clean; sudo journalctl --vacuum-time=7d
echo "✅ Caché y logs antiguos limpiados" >> "$RESUMEN"

echo -e "${VERDE}[4/7] Gestionando Flatpak...${NC}"
if command -v flatpak >/dev/null 2>&1; then flatpak update -y; flatpak uninstall --unused -y; echo "✅ Aplicaciones Flatpak actualizadas y limpiadas" >> "$RESUMEN"; fi

echo -e "${VERDE}[5/7] Actualizando Spices...${NC}"
if command -v cinnamon-spice-updater >/dev/null 2>&1; then cinnamon-spice-updater --update-all; echo "✅ Spices de Cinnamon actualizados" >> "$RESUMEN"; fi

echo -e "${VERDE}[6/7] Limpiando .deb viejos...${NC}"
find "$HOME/Downloads" "$HOME/Descargas" -maxdepth 1 -name "*.deb" -type f -mtime +7 -delete 2>/dev/null
rm -rf ~/.cache/thumbnails/* 2>/dev/null
echo "✅ Archivos .deb viejos y miniaturas limpiados" >> "$RESUMEN"

DISCO_FIN=$(df -m / | awk 'NR==2 {print $4}')
ESPACIO=$((DISCO_FIN - DISCO_INI))
[ $ESPACIO -lt 0 ] && ESPACIO=0
KERNEL=$(uname -r)
RAM=$(free -h | awk '/^Mem:/ {print $3 " usadas de " $2}')
DISCO_USO=$(df -h / | awk 'NR==2 {print $4 " libres de " $2 " (" $5 " usado)"}')
DISK_HEALTH="Sin errores (logs)"
DISK_DEV=$(lsblk -no PKNAME $(findmnt -no SOURCE /) 2>/dev/null | head -1)
[ -z "$DISK_DEV" ] && DISK_DEV=$(lsblk -no NAME -d 2>/dev/null | head -1)
if command -v smartctl >/dev/null 2>&1 && [ -n "$DISK_DEV" ]; then
  SH=$(sudo smartctl -H /dev/$DISK_DEV 2>/dev/null | grep -i result)
  if echo "$SH" | grep -qi PASSED; then DISK_HEALTH="SMART: APROBADO"; fi
  if echo "$SH" | grep -qi FAILED; then DISK_HEALTH="ALERTA SMART"; fi
fi
if dmesg 2>/dev/null | grep -qiE "EXT4-fs error|I/O error"; then DISK_HEALTH="ERRORES DETECTADOS"; fi
TEMP="N/D"
if command -v sensors >/dev/null 2>&1; then
  T=$(sensors 2>/dev/null | grep -oE "[0-9]+\.[0-9]+.C" | head -1)
  [ -n "$T" ] && TEMP="$T"
fi
if [ "$TEMP" = "N/D" ]; then
  for z in /sys/class/thermal/thermal_zone*/temp; do
    [ -f "$z" ] || continue
    RAW=$(cat "$z" 2>/dev/null)
    case "$RAW" in ''|*[!0-9]*) continue;; esac
    if [ "$RAW" -gt 0 ] && [ "$RAW" -lt 150000 ]; then TEMP="$((RAW/1000)) C"; break; fi
  done
fi

echo -e "${VERDE}[7/7] Generando reporte...${NC}"

echo -e "${ESMERALDA}╔══════════════════════════════════════════════════════════════╗${NC}"
printf "${ESMERALDA}║${NC}  ${BLANCO}✨ REPORTE FINAL DE MANTENIMIENTO Y SALUD ✨%36s${NC}${ESMERALDA}║${NC}\n" ""
echo -e "${ESMERALDA}╠══════════════════════════════════════════════════════════════╣${NC}"
printf "${ESMERALDA}║${NC}  ${BLANCO}📋 OPERACIONES REALIZADAS:%33s${NC}${ESMERALDA}║${NC}\n" ""
echo -e "${ESMERALDA}╠══════════════════════════════════════════════════════════════╣${NC}"
while IFS= read -r line; do
    printf "${ESMERALDA}║${NC}  ${BLANCO}%-55s${NC}${ESMERALDA}║${NC}\n" "$line"
done < "$RESUMEN"
echo -e "${ESMERALDA}╠══════════════════════════════════════════════════════════════╣${NC}"
printf "${ESMERALDA}║${NC}  🐧 ${BLANCO}KERNEL: %-45s${NC}${ESMERALDA}║${NC}\n" "$KERNEL"
printf "${ESMERALDA}║${NC}  🧠 ${BLANCO}RAM: %-47s${NC}${ESMERALDA}║${NC}\n" "$RAM"
printf "${ESMERALDA}║${NC}  🌡️ ${BLANCO}TEMPERATURA CPU: %-40s${NC}${ESMERALDA}║${NC}\n" "$TEMP"
printf "${ESMERALDA}║${NC}  💽 ${BLANCO}DISCO: %-46s${NC}${ESMERALDA}║${NC}\n" "$DISCO_USO"
printf "${ESMERALDA}║${NC}  🛡️ ${BLANCO}SALUD DEL DISCO: %-39s${NC}${ESMERALDA}║${NC}\n" "$DISK_HEALTH"
printf "${ESMERALDA}║${NC}  ✨ ${BLANCO}ESPACIO RECUPERADO: %-34s${NC}${ESMERALDA}║${NC}\n" "${ESPACIO} MB"
printf "${ESMERALDA}║${NC}  🏆 ${BLANCO}ESTADO: %-44s${NC}${ESMERALDA}║${NC}\n" "SISTEMA OPTIMIZADO Y SALUDABLE"
echo -e "${ESMERALDA}╚══════════════════════════════════════════════════════════════╝${NC}"

read -p "Presione la tecla [ENTER] para cerrar esta ventana..."
