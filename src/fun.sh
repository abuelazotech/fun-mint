#!/usr/bin/env bash
VERDE='[1;92m'; AZUL_CLARO='[1;96m'; AMARILLO='[1;93m'; NC='[0m'

verificar_conexion() {
    local inicio=$(date +%s)
    ping -c 1 -W 3 archive.ubuntu.com >/dev/null 2>&1
    local fin=$(date +%s)
    local duracion=$((fin - inicio))
    if [ $duracion -ge 10 ]; then
        echo -e "${AMARILLO}⚠️ La conexión a Internet parece inestable. Algunas tareas pueden tardar más de lo habitual.${NC}"
    elif [ $duracion -ge 3 ]; then
        echo -e "${AMARILLO}⏳ Intentando conectar con los servidores... La conexión está lenta, pero FUN sigue trabajando.${NC}"
    fi
}

echo -e "${AZUL_CLARO}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${AZUL_CLARO}║              🚀 INICIANDO MANTENIMIENTO FUN v2 🚀            ║${NC}"
echo -e "${AZUL_CLARO}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "${AMARILLO}🔐 FUN necesita permisos de administrador.${NC}"
echo -e "${AMARILLO}   Escribe tu contraseña y presiona ENTER.${NC}"
sudo -v || { echo -e "${AMARILLO}No se concedieron permisos.${NC}"; read -p "Presiona ENTER..."; exit 1; }

echo -e "${VERDE}✅ Permiso concedido.${NC}"
echo -e "${AZUL_CLARO}🔎 ¿QUÉ ESTÁ HACIENDO FUN?${NC}"
echo -e "   1/7  Actualizando sistema"
echo -e "   2/7  Eliminando huérfanos"
echo -e "   3/7  Limpiando caché"
echo -e "   4/7  Gestionando Flatpak"
echo -e "   5/7  Actualizando Spices"
echo -e "   6/7  Limpiando .deb viejos"
echo -e "   7/7  Generando reporte"
echo -e "${AMARILLO}⏳ La duración depende de tu conexión a Internet.${NC}"

if ! command -v nala &> /dev/null; then
    sudo apt update && sudo apt install nala -y
fi

DISCO_INICIAL_MB=$(df -m / | awk 'NR==2 {print $4}')

echo -e "${VERDE}[1/7] Actualizando con Nala...${NC}"
verificar_conexion
sudo nala update && sudo nala upgrade -y

echo -e "${VERDE}[2/7] Eliminando huérfanos...${NC}"
sudo nala autoremove -y

echo -e "${VERDE}[3/7] Limpiando caché...${NC}"
sudo nala clean; sudo journalctl --vacuum-time=7d >/dev/null 2>&1

echo -e "${VERDE}[4/7] Gestionando Flatpak...${NC}"
verificar_conexion
if command -v flatpak &> /dev/null; then
    flatpak update -y >/dev/null 2>&1
    flatpak uninstall --unused -y >/dev/null 2>&1
fi

echo -e "${VERDE}[5/7] Actualizando Spices...${NC}"
verificar_conexion
if command -v cinnamon-spice-updater &> /dev/null; then
    cinnamon-spice-updater --update-all >/dev/null 2>&1
fi

echo -e "${VERDE}[6/7] Limpiando .deb viejos...${NC}"
find "$HOME/Downloads" -maxdepth 1 -name "*.deb" -type f -mtime +7 -delete 2>/dev/null
rm -rf ~/.cache/thumbnails/* 2>/dev/null

DISCO_FINAL_MB=$(df -m / | awk 'NR==2 {print $4}')
ESPACIO_RECUPERADO_MB=$((DISCO_FINAL_MB - DISCO_INICIAL_MB))
[ $ESPACIO_RECUPERADO_MB -lt 0 ] && ESPACIO_RECUPERADO_MB=0

echo -e "${VERDE}[7/7] Reporte de Salud...${NC}"
echo -e "${AZUL_CLARO}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${AZUL_CLARO}║           📊 RESUMEN DE MANTENIMIENTO 📊                    ║${NC}"
echo -e "${AZUL_CLARO}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${AZUL_CLARO}║${NC} 💾 Espacio Recuperado: ${VERDE}$ESPACIO_RECUPERADO_MB MB${NC}"
echo -e "${AZUL_CLARO}╚══════════════════════════════════════════════════════════════╝${NC}"
read -p 'Presiona ENTER para cerrar...'
