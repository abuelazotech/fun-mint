# 🐧 FUN — Mantenimiento y Salud para Linux Mint

**FUN** (*Full Update Upgrade*) es una utilidad en Bash creada por **El Abuelazo Tech** que deja tu Linux Mint actualizado, limpio y revisado con una sola orden: `fun`.

- ✅ Un solo comando, sin memorizar sintaxis largas.
- ✅ Contraseña de administrador una sola vez por ejecución.
- ✅ Modo simulación para ver qué hará antes de ejecutarlo.
- ✅ Reporte de salud en pantalla y, si quieres, en tu Escritorio.

![Vista previa de FUN](assets/preview.png)

---

## 🚀 ¿Qué hace `fun`?

Al ejecutarlo realiza 7 pasos, con el estado de cada uno al final:

| Paso | Acción |
|---|---|
| 1️⃣ Sincronizar e instalar | `apt-get update` con registro en vivo, instala `nala` y `lm-sensors` si faltan, y avisa si detecta claves GPG ausentes (**no las importa automáticamente**). |
| 2️⃣ Sistema | Actualiza paquetes con `nala upgrade` y aplica las opciones estándar para no sobrescribir configuraciones propias. |
| 3️⃣ Huérfanos y caché | `nala autoremove`, `nala clean` y `journalctl --vacuum-time=7d` (logs de más de 7 días). |
| 4️⃣ Flatpak | Actualiza las apps Flatpak y elimina las dependencias sin uso. |
| 5️⃣ Cinnamon Spices | Actualiza applets, temas y extensiones con `cinnamon-spice-updater`. |
| 6️⃣ Limpieza visual | Borra `.deb` con más de 7 días en `Descargas`/`Downloads` y limpia la caché de miniaturas. |
| 7️⃣ Salud | Muestra kernel, temperatura de CPU, RAM libre, disco, errores recientes del disco y espacio neto recuperado. |

**Extras**

- 📄 Guarda opcionalmente un reporte `.txt` en el Escritorio.
- 🔔 Pregunta al final si quieres abrir el Gestor de Actualizaciones cuando quedan pendientes reales (por ejemplo, kernels retenidos).
- 🎨 Terminal con colores de alto contraste.

---

## 📥 Instalación

### Opción 1 — Paquete `.deb` (recomendada, en 2 clics)

1. Descarga [**fun_1.2.0-1_amd64.deb**](https://github.com/abuelazotech/fun-mint/releases/download/1.2.0-1/fun_1.2.0-1_amd64.deb).
2. Haz doble clic y pulsa **Instalar** en el Gestor de Software de Linux Mint.

Después busca **FUN - El Abuelazo Tech** en el menú o escribe `fun` en la terminal.

### Opción 2 — Un solo comando en la terminal

Descarga el instalador, verifica la suma SHA256 del paquete y lo instala:

```bash
curl -fsSL https://raw.githubusercontent.com/abuelazotech/fun-mint/main/src/instalar-fun.sh -o /tmp/instalar-fun.sh && bash /tmp/instalar-fun.sh
```

Si FUN ya estaba instalado en la misma versión y no se refrescaron el icono o la captura, fuerza una reinstalación:

```bash
curl -fsSL https://raw.githubusercontent.com/abuelazotech/fun-mint/main/src/instalar-fun.sh -o /tmp/instalar-fun.sh && bash /tmp/instalar-fun.sh --reinstall
```

Si lo prefieres sin `curl`, descarga `instalar-fun.sh` desde este repositorio y ejecútalo con `bash instalar-fun.sh`.

### Opción 3 — Desde el código fuente

```bash
git clone https://github.com/abuelazotech/fun-mint.git
cd fun-mint
./build.sh
bash src/instalar-fun.sh
```

También puedes usar el instalador gráfico con `bash src/instalar-fun-gui.sh` (necesita `zenity` y `pkexec`).

---

## 🧰 Uso

```bash
fun                 # mantenimiento completo
fun --dry-run       # simula los 7 pasos sin tocar nada
fun --help          # ayuda rápida
fun --version       # versión instalada
```

Opciones del instalador:

```bash
bash instalar-fun.sh --reinstall   # reinstala aunque ya estés en la misma versión
bash instalar-fun.sh --uninstall   # desinstala FUN del sistema
bash instalar-fun.sh --dry-run     # simula sin descargar ni modificar nada
```

Si el icono no aparece tras instalar, cierra sesión y vuelve a entrar, o ejecuta `sudo gtk-update-icon-cache /usr/share/icons/hicolor/`.

---

## ⬆️ Actualizar desde FUN 1.1

Instala el `.deb` de 1.2.0 encima del anterior (doble clic o cualquiera de los comandos anteriores). El paquete elimina automáticamente las copias heredadas en `/usr/local/bin/fun` y `~/.local/bin/fun`, que en 1.1 hacían que la primera ejecución instalara un segundo script. La línea `export PATH="$HOME/.local/bin:$PATH"` que añadía 1.1 al `.bashrc` es inofensiva y se puede dejar.

---

## 🗑️ Desinstalar

- **Gestor de Software:** busca «FUN - Mantenimiento Linux Mint» y pulsa **Eliminar**.
- **Terminal:** `sudo apt remove fun`.
- **Instalador:** `bash instalar-fun.sh --uninstall` (o `bash src/instalar-fun-gui.sh --uninstall` para confirmar con una ventana).

Los reportes que hayas guardado en el Escritorio no se eliminan: son tus archivos.

---

## 🧩 Requisitos y compatibilidad

- Linux Mint **21.x / 22.x** (Cinnamon; también funciona en terminal sobre Ubuntu/Mint derivados).
- `nala` se instala automáticamente porque es dependencia del paquete.
- `zenity` es **opcional**: solo se usa para ventanas de confirmación y para el instalador gráfico.
- Sin Snap: Linux Mint prioriza Flatpak. Los AppImage se actualizan manualmente desde su desarrollador.

---

## 🛠️ Solución de problemas

| Situación | Qué hacer |
|---|---|
| Aparece `NO_PUBKEY` durante la sincronización | FUN lo muestra y no importa claves por seguridad. Ajusta ese repositorio con `signed-by=/ruta/a/clave.gpg`. |
| `fun: command not found` | Abre una terminal nueva; si persiste, comprueba `dpkg -l fun`. |
| El icono no aparece | `sudo gtk-update-icon-cache /usr/share/icons/hicolor/` y vuelve a iniciar sesión. |
| No se puede descargar el paquete | Usa el enlace directo de la sección Instalación desde el navegador. |
| Falló la verificación SHA256 | No instalés ese archivo: descárgalo de nuevo desde Releases. |
| No aparece la captura en el Gestor de Software | Ejecuta `bash instalar-fun.sh --reinstall` y luego `sudo appstreamcli refresh --force`; reinicia el Gestor de Software y comprueba tu conexión (la imagen se sirve desde este repositorio). |

---

## 📁 Estructura del repositorio

| Ruta | Contenido |
|---|---|
| `src/fun.sh` | Comando `fun`: los 7 pasos y el reporte de salud. |
| `src/instalar-fun.sh` | Instalador de terminal: descarga, verifica, reinstala y desinstala (`--reinstall`, `--uninstall`). |
| `src/instalar-fun-gui.sh` | Instalador con ventanas (zenity + pkexec), también con `--uninstall`. |
| `build.sh` | Construye `fun_1.2.0-1_amd64.deb` con permisos y propietario correctos. |
| `packaging/` | Metadatos Debian: `control`, `changelog`, `copyright`, `postinst`, `fun.desktop` y `fun.appdata.xml` (captura del Gestor de Software). |
| `assets/` | Iconos 256x256 y 1024x1024, `preview.png` del README y `captura.png` mostrada en el Gestor de Software. |
| `LICENSE` | Texto completo de GPL-3.0. |

---

## 📄 Licencia

**GPL-3.0.** Libre de usar, modificar y compartir. Consulta el archivo [LICENSE](LICENSE) y la sección [Novedades](https://github.com/abuelazotech/fun-mint/releases) para el historial de cambios.

---

## ☕ ¿Te resulta útil?

Si FUN te ahorró tiempo, puedes apoyar nuevas herramientas de **El Abuelazo Tech**:

👉 [Invítame un café en Ko-fi](https://ko-fi.com/abuelazotech)

Hecho con ❤️ por **El Abuelazo Tech**.
