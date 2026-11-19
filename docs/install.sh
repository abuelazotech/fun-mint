#!/usr/bin/env bash
set -Eeuo pipefail

curl -fsSL https://github.com/abuelazotech/fun-mint/raw/refs/heads/main/src/agregar-repo.sh -o /tmp/agregar-repo.sh
bash /tmp/agregar-repo.sh
