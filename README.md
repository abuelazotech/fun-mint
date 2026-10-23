# 🚀 FUN: Full Update & Upgrade con Nala para Linux Mint

**FUN** es un script automático que instala y configura la función `fun` en tu terminal para realizar el mantenimiento completo de Linux Mint de forma rápida, visual y eficiente.

---

## 🤔 ¿Qué es Nala y por qué lo usamos en lugar de APT?

Si llevas tiempo usando Linux, seguro conoces el comando `sudo apt update && sudo apt upgrade`. **Nala** es simplemente una interfaz mejorada para el mismo gestor de paquetes de Debian/Ubuntu/Mint (`apt`), pero con ventajas impresionantes:

* ⚡ **Descargas paralelas más rápidas:** A diferencia de `apt`, que descarga los paquetes uno por uno, **Nala** descarga múltiples paquetes al mismo tiempo.
* 📊 **Interfaz mucho más clara y ordenada:** Muestra de forma muy visual y legible qué programas se van a instalar, actualizar o borrar, con barras de progreso a color.
* 📜 **Historial de cambios (Undo):** Permite ver el historial de actualizaciones y revertir (*undo*) una instalación si algo falló.

> 💡 **Nota:** La función `fun` instala **Nala** automáticamente si no lo tienes. Sin embargo, si prefieres instalarlo manualmente en tu equipo antes de usar este proyecto, solo abre tu terminal y ejecuta:
> ```bash
> sudo apt update && sudo apt install nala -y
> ```

---

## ✨ ¿Qué hace la función `fun`?

Al escribir `fun` en tu terminal, el sistema realiza automáticamente los siguientes 5 pasos:

1. **`nala upgrade -y`**: Actualiza los índices y paquetes del sistema en paralelo y con una interfaz limpia.
2. **`nala autopurge -y`**: Elimina paquetes obsoletos y borra sus archivos de configuración huérfanos.
3. **`nala clean`**: Limpia la caché de descarga para liberar espacio en disco.
4. **Mantenimiento Flatpak**: Detecta si utilizas Flatpaks, actualiza todas tus aplicaciones y elimina entornos de ejecución (*runtimes*) no utilizados.
5. **Aviso de Reinicio**: Te alerta de forma destacada si la actualización del Kernel requiere reiniciar el equipo.

---

## 🛠️ Instalación Rápida (Un solo comando)

Copia y pega la siguiente línea **completa** en tu terminal y presiona Enter:

```bash
curl -sSL [https://raw.githubusercontent.com/TU_USUARIO/fun-mint/main/instalar-fun.sh](https://raw.githubusercontent.com/TU_USUARIO/fun-mint/main/instalar-fun.sh) | bash

    (Recuerda reemplazar TU_USUARIO por tu nombre de usuario exacto de GitHub. La palabra | bash al final es necesaria para que la terminal ejecute el instalador descargado automáticamente).

📂 Instalación Manual (Descarga)

Si prefieres descargar el archivo manualmente:

    Descarga el archivo instalar-fun.sh de este repositorio.

    Abre la terminal en la carpeta de descarga y dale permisos de ejecución:
    Bash

    chmod +x instalar-fun.sh

    Ejecútalo escribiendo:
    Bash

    ./instalar-fun.sh

Al finalizar, abre una nueva terminal o ejecuta source ~/.bashrc. ¡Escribe fun y listo!
🐧 Compatibilidad

Diseñado optimizadamente para Linux Mint (Cinnamon, MATE, XFCE). Compatible también con Ubuntu, Pop!_OS, Zorin OS y distribuciones basadas en Debian.


---

### Instrucciones para guardar:
1. Una vez pegado el texto en `micro`, guarda los cambios con `Ctrl + S`.
2. Sal del editor con `Ctrl + Q`.
