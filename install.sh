#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starte Proxmine Installation ..."

# Repository-URL
GIT_REPO="https://raw.githubusercontent.com/fmando/proxmine/main"

# Reihenfolge: Proxy → Coreminer → Uninstall nur bereitlegen
SCRIPTS=("deploy-xcb-proxy.sh" \
         "deploy-coreminer.sh" \
         "uninstall-xcb-proxy.sh")

# Arbeitsverzeichnis
WORKDIR="$(mktemp -d)"
chmod 700 "$WORKDIR"
echo "📂 Arbeitsverzeichnis: $WORKDIR"

# Skripte herunterladen
for script in "${SCRIPTS[@]}"; do
  url="${GIT_REPO}/${script}"
  echo "⬇️  Lade ${script}..."
  curl -fsSL "$url" -o "${WORKDIR}/${script}"
  chmod +x "${WORKDIR}/${script}"
done

cd "$WORKDIR"

# Proxy deployen
echo "🔌 Starte Proxy-Deployment..."
./deploy-xcb-proxy.sh

# Coreminer deployen
echo "⛏  Starte Coreminer-Deployment..."
./deploy-coreminer.sh

# Uninstall-Skript nur bereitlegen
echo "🧹 Uninstall-Skript bereit unter: ${WORKDIR}/uninstall-xcb-proxy.sh"
echo "   (bei Bedarf manuell ausführen, um den Proxy wieder zu entfernen)"

echo "✅ Installation abgeschlossen!"
