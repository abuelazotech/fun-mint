#!/usr/bin/env bash
set -Eeuo pipefail

RAIZ="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

PAQUETE="fun_1.2.0-1_amd64.deb"
REPO_DIR="docs/apt"
FPR="B075A1B11956EE1B427AE26202ACB4742E42E79E"

./build.sh
install -D -m 644 "$PAQUETE" "$REPO_DIR/pool/main/f/fun/$PAQUETE"
install -d -m 755 "$REPO_DIR/dists/stable/main/binary-amd64"

cd "$REPO_DIR"
dpkg-scanpackages pool /dev/null > dists/stable/main/binary-amd64/Packages
gzip -9 -n -c dists/stable/main/binary-amd64/Packages > dists/stable/main/binary-amd64/Packages.gz
rm -f dists/stable/Release dists/stable/Release.gpg dists/stable/InRelease

apt-ftparchive \
  -o APT::FTPArchive::Release::Origin="El Abuelazo Tech" \
  -o APT::FTPArchive::Release::Label="FUN" \
  -o APT::FTPArchive::Release::Suite="stable" \
  -o APT::FTPArchive::Release::Codename="stable" \
  -o APT::FTPArchive::Release::Architectures="amd64" \
  -o APT::FTPArchive::Release::Components="main" \
  -o APT::FTPArchive::Release::Description="Repositorio apt de FUN para Linux Mint" \
  release dists/stable > Release.new
mv Release.new dists/stable/Release

gpg --batch --yes --pinentry-mode loopback --passphrase '' --armor --detach-sign --local-user "$FPR" -o dists/stable/Release.gpg dists/stable/Release
gpg --batch --yes --pinentry-mode loopback --passphrase '' --clearsign --local-user "$FPR" -o dists/stable/InRelease dists/stable/Release

cd "$RAIZ"
sha256sum "$PAQUETE"
