# 🤖 FUN - Mantenimiento y Salud para Linux Mint

![FUN - El Abuelazo Tech](preview.png)

**FUN** es una herramienta automatizada en Bash, creada por **El Abuelazo Tech**, que mantiene tu Linux Mint limpio, actualizado y saludable con un solo comando.

---

## 🚀 ¿Qué hace `fun`?

Al ejecutar la herramienta, realiza 7 pasos ultrarrápidos:

1. 🔄 **Actualización con Nala** — Sincroniza repositorios, repara claves GPG obsoletas y actualiza el sistema.
2. 🧹 **Dependencias huérfanas** — Elimina paquetes que ya no sirven.
3. 🗑️ **Caché y logs** — Poda la caché de APT y los registros mayores de 7 días.
4. 📦 **Flatpak** — Actualiza aplicaciones y borra residuos sin usar.
5. 🎨 **Cinnamon Spices** — Sincroniza temas, applets y complementos.
6. 🖼️ **Miniaturas y `.deb` viejos** — Limpia la caché de imágenes y paquetes de instalación de más de 7 días en la carpeta de Descargas.
7. 🩺 **Reporte de salud** — Muestra en pantalla el kernel activo, temperatura de la CPU, uso de RAM, espacio en disco y estado de los logs.

**✨ Extras:**
- Calcula el **espacio exacto recuperado** en cada ejecución.
- Abre el **Gestor de Actualizaciones** automáticamente solo si detecta pendientes reales (como kernels retenidos).
- Interfaz visual en terminal con colores de alto contraste.

---

## 📥 Instalación

### Opción 1 — Paquete `.deb` (Recomendada)
1. Descarga el archivo `fun_1.1-1_amd64.deb` desde la sección de Releases de este repositorio.
2. Haz doble clic sobre el archivo y pulsa **Instalar** en el Gestor de Software.

### Opción 2 — Instalador Bash
1. Descarga el archivo `instalar-fun.sh`.
2. Dale permisos de ejecución y ejecútalo desde la terminal.

---

## ⚙️ Requisitos

- **Linux Mint** (Cinnamon) 21.x / 22.x
- `nala` (se instala solo automáticamente si no lo tienes)
- `zenity` (para las ventanas gráficas)

---

## 📝 Notas técnicas

- **Snap:** Omitido a propósito por rendimiento (Linux Mint prioriza Flatpak).
- **AppImage:** Al ser formato portátil, se actualizan manualmente desde la web del desarrollador.
- **GPG:** Usa el método moderno y seguro `/etc/apt/trusted.gpg.d/` (sin el obsoleto `apt-key`).

---

## 🗑️ ¿Cómo desinstalarlo?

Si en algún momento deseas eliminar la herramienta, es muy sencillo:

1. Abre el **Gestor de Software** de Linux Mint.
2. Busca **"FUN - Mantenimiento Linux Mint"**.
3. **Selecciona** la herramienta en la lista para abrir su ficha.
4. Haz clic en el botón **Eliminar**.

*(Para usuarios avanzados: también puedes ejecutar `sudo apt remove fun` en la terminal).*

---

## ☕ ¿Te resulta útil?

Si `fun` te hizo la vida más fácil con tu Linux Mint y quieres apoyar más herramientas y contenido de **El Abuelazo Tech**, ¡estos proyectos se alimentan a base de buen café!

👉 **[Invítame un café en Ko-fi](https://ko-fi.com/abuelazotech)**

¡Mil gracias por ser parte de esta comunidad! 🐧

---

## 📄 Licencia

GPL-3.0. Libre de usar, modificar y compartir.

**Hecho con ❤️ por El Abuelazo Tech.**
