#!/bin/bash
# ==============================================================================
# Instalador de la función 'fun' (Full Upgrade Nala) para Linux Mint & derivados
# ==============================================================================

GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo -e "${BLUE}[Instalador FUN]${RESET} Verificando dependencias..."

# 1. Asegurar que Nala esté instalado
if ! command -v nala >/dev/null 2>&1; then
    echo -e "${YELLOW}[Instalador FUN]${RESET} Instalando 'nala' para descargas más rápidas..."
    sudo apt update && sudo apt install nala -y
fi

# 2. Archivo de configuración de la terminal
SHELL_CONFIG="$HOME/.bashrc"
if [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
fi

# 3. Evitar duplicar la función si ya existe
if grep -q "fun ()" "$SHELL_CONFIG"; then
    echo -e "${YELLOW}[Instalador FUN]${RESET} La función 'fun' ya está instalada en $SHELL_CONFIG."
    echo -e "Si deseas actualizarla, elimina la versión antigua de tu archivo de configuración."
    exit 0
fi

# 4. Inyectar la función 'fun' en el archivo de configuración
echo -e "${BLUE}[Instalador FUN]${RESET} Agregando la función 'fun' a $SHELL_CONFIG..."

cat << 'EOF' >> "$SHELL_CONFIG"

# --- Función FUN (Full Upgrade Nala y componentes) ---
fun () 
{ 
    local c_info c_step c_ok c_err c_reset;
    c_info='\033[1;34m';
    c_step='\033[1;33m';
    c_ok='\033[1;32m';
    c_err='\033[1;31m';
    c_reset='\033[0m';

    printf '\n%b[fun]%b Iniciando mantenimiento del sistema...\n' "$c_info" "$c_reset";

    printf '%b[fun]%b 1/6 Actualizando e instalando paquetes con Nala (incluyendo Kernel)...\n' "$c_step" "$c_reset";
    if ! sudo nala upgrade --full -y; then
        printf '%b[fun]%b Error en "nala upgrade --full".\n' "$c_err" "$c_reset";
        return 1;
    fi;

    printf '%b[fun]%b 2/6 Eliminando paquetes innecesarios...\n' "$c_step" "$c_reset";
    if ! sudo nala autopurge -y; then
        printf '%b[fun]%b Error al eliminar paquetes sobrantes.\n' "$c_err" "$c_reset";
        return 1;
    fi;

    printf '%b[fun]%b 3/6 Limpiando caché de paquetes...\n' "$c_step" "$c_reset";
    if ! sudo nala clean; then
        printf '%b[fun]%b Error limpiando el caché.\n' "$c_err" "$c_reset";
        return 1;
    fi;

    if command -v flatpak >/dev/null 2>&1; then
        printf '%b[fun]%b 4/6 Actualizando aplicaciones Flatpak...\n' "$c_step" "$c_reset";
        flatpak update -y
        flatpak uninstall --unused -y
    else
        printf '%b[fun]%b 4/6 Flatpak no detectado, omitiendo...\n' "$c_step" "$c_reset";
    fi;

    if command -v cinnamon-spice-updater >/dev/null 2>&1; then
        printf '%b[fun]%b 5/6 Actualizando complementos de Cinnamon...\n' "$c_step" "$c_reset";
        cinnamon-spice-updater --update-all
    else
        printf '%b[fun]%b 5/6 Actualizador de Cinnamon spices omitido...\n' "$c_step" "$c_reset";
    fi;

    printf '%b[fun]%b 6/6 Mantenimiento completado correctamente.\n' "$c_ok" "$c_reset";

    if [ -f /var/run/reboot-required ]; then
        printf '\n%b[AVISO]%b Se han actualizado componentes del sistema o el kernel. %bSe recomienda reiniciar el equipo.%b\n\n' "$c_err" "$c_reset" "$c_step" "$c_reset";
    fi
}
# ----------------------------------------------
EOF

echo -e "${GREEN}[¡ÉXITO!]${RESET} Instalación completada."
echo -e "Para empezar a usarla inmediatamente, abre una nueva terminal o ejecuta: ${BLUE}source $SHELL_CONFIG${RESET}"
echo -e "Luego, solo escribe ${GREEN}fun${RESET} para mantener tu Linux Mint al día."
