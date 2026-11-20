#!/usr/bin/env bash
set -Eeuo pipefail

SERIE="${1:-noble}"
SUFIJO="${2:-}"
RAIZ="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SALIDA="${TMPDIR:-/tmp}/fun-ppa-build/$SERIE"
VERSION="1.2.0-1${SUFIJO}"
ORIG="1.2.0"
FPR="B075A1B11956EE1B427AE26202ACB4742E42E79E"

cd "$RAIZ"
rm -rf "$SALIDA"
mkdir -p "$SALIDA"

git archive --prefix="fun-$ORIG/" HEAD | gzip -n > "$SALIDA/fun_${ORIG}.orig.tar.gz"
tar -xzf "$SALIDA/fun_${ORIG}.orig.tar.gz" -C "$SALIDA"
cp -a ppa/debian "$SALIDA/fun-$ORIG/"
sed -i "s/^fun (1.2.0-1) noble;/fun ($VERSION) $SERIE;/" "$SALIDA/fun-$ORIG/debian/changelog"

cd "$SALIDA"
dpkg-source -b "fun-$ORIG"
cd "$SALIDA/fun-$ORIG"
dpkg-buildpackage -S -d -k"$FPR"

echo "Paquetes fuente en: $SALIDA"
ls -1 "$SALIDA"/fun_${VERSION}*
