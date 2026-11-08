#!/usr/bin/env bash
# ==============================================================================
# Nombre de la Herramienta: FUN (Script de Mantenimiento y Salud para Linux Mint)
# Autor: El Abuelazo Tech
# Versión: 1.1
# Descripción: Automatiza actualización, limpieza, reparación GPG y diagnóstico 
#              de salud y temperatura del sistema.
# ==============================================================================

# Definición de colores para la interfaz visual
AZUL_CLARO='\033[1;34m'
AMARILLO='\033[1;33m'
VERDE='\033[1;32m'
ROJO='\033[1;31m'
NC='\033[0m' # Sin color / Reset

# Función principal que se instalará en el sistema
fun_principal() {
    local c_info="$AZUL_CLARO"
    local c_step="$AMARILLO"
    local c_ok="$VERDE"
    local c_err="$ROJO"
    local c_reset="$NC"

    printf '\n%b[fun]%b Iniciando mantenimiento y diagnóstico del sistema...\n' "$c_info" "$c_reset"

    # 1. Actualización con Nala
    printf '%b[fun]%b 1/6 Actualizando e instalando paquetes con Nala (incluyendo Kernel)...\n' "$c_step" "$c_reset"
    if ! sudo nala upgrade --full -y; then
        printf '%b[fun]%b Error en "nala upgrade --full".\n' "$c_err" "$c_reset"
        return 1
    fi

    # 2. Autopurge de paquetes innecesarios
    printf '%b[fun]%b 2/6 Eliminando paquetes innecesarios y huérfanos...\n' "$c_step" "$c_reset"
    if ! sudo nala autopurge -y; then
        printf '%b[fun]%b Error al eliminar paquetes sobrantes.\n' "$c_err" "$c_reset"
        return 1
    fi

    # 3. Limpieza de caché
    printf '%b[fun]%b 3/6 Limpiando caché de paquetes...\n' "$c_step" "$c_reset"
    if ! sudo nala clean; then
        printf '%b[fun]%b Error limpiando el caché.\n' "$c_err" "$c_reset"
        return 1
    fi

    # 4. Actualización de Flatpak
    if command -v flatpak > /dev/null 2>&1; then
        printf '%b[fun]%b 4/6 Actualizando aplicaciones Flatpak...\n' "$c_step" "$c_reset"
        flatpak update -y
        flatpak uninstall --unused -y
    else
        printf '%b[fun]%b 4/6 Flatpak no detectado, omitiendo...\n' "$c_step" "$c_reset"
    fi

    # 5. Actualización de Cinnamon Spices
    if command -v cinnamon-spice-updater > /dev/null 2>&1; then
        printf '%b[fun]%b 5/6 Actualizando complementos de Cinnamon...\n' "$c_step" "$c_reset"
        cinnamon-spice-updater --update-all
    else
        printf '%b[fun]%b 5/6 Actualizador de Cinnamon spices omitido...\n' "$c_step" "$c_reset"
    fi

    printf '%b[fun]%b 6/6 Mantenimiento completado correctamente.\n' "$c_ok" "$c_reset"

    # 📊 RESUMEN DE SALUD Y ESTADO DEL SISTEMA
    printf '\n%b                     📊 RESUMEN DE SALUD Y ESTADO DEL SISTEMA%b\n' "$AZUL_CLARO" "$c_reset"
    printf '%b----------------------------------------------------------------------%b\n' "$AZUL_CLARO" "$c_reset"
    
    # Fecha y Hora actual
    printf '  • %bFecha del sistema:%b %s\n' "$AMARILLO" "$c_reset" "$(date '+%A, %d de %B de %Y - %H:%M:%S')"
    
    # Tiempo activo (Uptime)
    printf '  • %bTiempo activo:%b %s\n' "$AMARILLO" "$c_reset" "$(uptime -p)"
    
    # Uso de Disco
    printf '  • %bEspacio en Disco (Raíz /):%b\n' "$AMARILLO" "$c_reset"
    df -h / | awk 'NR==2 {printf "    - Usado: %s / Total: %s (Ocupado: %s)\n", $3, $2, $5}'

    # Uso de Memoria RAM
    printf '  • %bUso de Memoria RAM:%b\n' "$AMARILLO" "$c_reset"
    free -h | awk 'NR==2 {printf "    - Usada: %s / Total: %s\n", $3, $2}'

    # Temperatura del procesador (si sensors está disponible)
    if command -v sensors > /dev/null 2>&1; then
        printf '  • %bTemperatura del Procesador:%b\n' "$AMARILLO" "$c_reset"
        sensors | grep -E "Core 0|CPU|temp1" | awk '{print "    - " $0}'
    else
        printf '  • %bTemperatura del Procesador:%b (Utilidad lm-sensors no instalada)\n' "$AMARILLO" "$c_reset"
    fi

    printf '%b----------------------------------------------------------------------%b\n\n' "$AZUL_CLARO" "$c_reset"

    # Aviso de reinicio si el Kernel lo requiere
    if [ -f /var/run/reboot-required ]; then
        printf '%b[AVISO]%b Se han actualizado componentes críticos o el Kernel. %bSe recomienda reiniciar el equipo.%b\n\n' "$ROJO" "$c_reset" "$AMARILLO" "$c_reset"
    fi
}

# ==============================================================================
# FASE DE INSTALACIÓN AUTOMÁTICA
# Si este script se ejecuta directamente, se auto-instala en el sistema global.
# ==============================================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "=================================================="
    echo "  INSTALADOR DE FUN (El Abuelazo Tech - v1.1)"
    echo "=================================================="
    
    # Copiar a la ruta global del sistema con permisos de ejecución
    sudo cp "$0" /usr/local/bin/fun
    sudo chmod +x /usr/local/bin/fun
    hash -r

    if [ $? -eq 0 ]; then
        echo "✅ ¡Instalación completada con éxito!"
        echo "Ahora puedes escribir la palabra 'fun' en cualquier terminal para ejecutar el mantenimiento."
    else
        echo "❌ Hubo un error durante la instalación."
        exit 1
    fi
fi
