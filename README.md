# Script de Mantenimiento FUN (Full Upgrade Nala)

Herramienta ligera para **Linux Mint** (y distribuciones basadas en Ubuntu/Debian) que automatiza en un solo comando el mantenimiento integral de tu sistema operativo.

## ¿Qué hace la función `fun`?

Ejecuta un flujo optimizado de 6 pasos:
1. **Nala Upgrade Full:** Actualiza repositorios y paquetes del sistema (incluyendo kernels retenidos).
2. **Nala Autopurge:** Elimina dependencias huérfanas o innecesarias.
3. **Nala Clean:** Limpia el caché de paquetes descargados para ahorrar espacio.
4. **Flatpak Update:** Actualiza tus aplicaciones Flatpak y elimina residuos no utilizados.
5. **Cinnamon Spices:** Actualiza tus complementos de escritorio (Desklets, Applets, Extensiones).
6. **Notificación de reinicio:** Te avisa si se ha actualizado el kernel y se requiere reiniciar.

## Modo de instalación

1. Clona o descarga este repositorio.
2. Abre una terminal en la carpeta descargada y otorga permisos de ejecución:
   ```bash
   chmod +x instalar-fun.sh

    Ejecuta el instalador:
    Bash

    ./instalar-fun.sh

    Carga la configuración o abre una nueva terminal:
    Bash

    source ~/.bashrc

¡Listo! Para usarlo en cualquier momento, simplemente escribe en tu terminal:
Bash

fun
