#!/usr/bin/env bash
set -Eeuo pipefail

BASE_URL="https://abuelazotech.github.io/fun-mint/apt"
KEYRING="/etc/apt/keyrings/fun-archive-keyring.gpg"
LIST="/etc/apt/sources.list.d/fun.list"
TMP_KEY="$(mktemp)"
trap 'rm -f "$TMP_KEY"' EXIT

echo "🔑 Añadiendo la clave del repositorio de FUN..."
curl -fsSL "$BASE_URL/keyring.gpg" -o "$TMP_KEY"
sudo install -d -m 755 /etc/apt/keyrings
sudo install -m 644 "$TMP_KEY" "$KEYRING"

echo "📝 Registrando el repositorio..."
echo "deb [signed-by=$KEYRING arch=amd64] $BASE_URL stable main" | sudo tee "$LIST" >/dev/null

echo "🔄 Actualizando la lista de paquetes..."
sudo apt update

echo "📦 Instalando FUN desde el repositorio..."
sudo apt install -y fun

echo "🔄 Refrescando la caché del Gestor de Software..."
pkill -f '/usr/lib/linuxmint/mintinstall/mintinstall.py' >/dev/null 2>&1 || true
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/mintinstall/pkginfo.json"
if [[ -x /usr/lib/linuxmint/mintinstall/mintinstall-update-pkgcache.py ]]; then
  /usr/lib/linuxmint/mintinstall/mintinstall-update-pkgcache.py >/dev/null 2>&1 || true
fi
python3 - <<'PY'
from gi.repository import Gio
s = Gio.Settings.new('com.linuxmint.install')
items = list(s.get_strv('installed-apps'))
if 'apt:fun' not in items:
    items.append('apt:fun')
    s.set_strv('installed-apps', items)
PY

echo "✅ Listo. Busca FUN - El Abuelazo Tech en el Gestor de Software."
