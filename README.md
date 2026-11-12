# FUN - Script de Mantenimiento y Salud para Linux Mint

Herramienta automatizada en Bash diseñada para facilitar el mantenimiento preventivo, la actualización de paquetes, la limpieza del sistema y la monitorización de salud en Linux Mint.

![Vista previa de fun](screenshots/preview.jpeg)

## ✨ Características de la Versión 1.1
- **Actualización Completa con Nala:** Optimiza la gestión de paquetes, repositorios y el Kernel del sistema.
- **Autopurge y Limpieza:** Elimina paquetes huérfanos y limpia la caché para liberar espacio valioso.
- **Mantenimiento Flatpak:** Actualiza aplicaciones en entorno aislado y elimina dependencias huérfanas de forma automática.
- **Actualización de Cinnamon Spices:** Mantiene al día los applets, desklets y extensiones del entorno de escritorio.
- **📊 Resumen de Salud y Estado del Sistema:** Al finalizar, muestra un reporte claro que incluye:
  - Fecha actual y tiempo activo del sistema (*uptime*).
  - Estado del espacio en disco de la partición raíz (`/`).
  - Porcentaje de uso de la memoria RAM.
  - **Temperatura actual del procesador (CPU)** (mediante `lm-sensors`).
- **Aviso de Reinicio:** Detecta automáticamente si el sistema o el Kernel requieren reinicio crítico.

## 🚀 Instalación Fácil

1. Descarga el archivo `instalar-fun.sh` desde este repositorio.
2. Haz **doble clic** sobre el archivo descargado y selecciona **"Ejecutar en terminal"** (o "Ejecutar").

¡Y listo! El instalador se encargará de configurar todo automáticamente. A partir de ese momento, solo tendrás que abrir cualquier terminal y escribir la palabra **`fun`** para hacer el mantenimiento de tu equipo.

---
*(Nota para usuarios avanzados: También puedes clonar el repositorio o ejecutar el script directamente desde la terminal si lo prefieres).*
