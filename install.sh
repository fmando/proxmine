#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starte Proxmine Installation ..."

# Reihenfolge: Proxy → Coreminer → Uninstall nur bereitlegen
SCRIPTS=("deploy-xcb-proxy.sh" \
         "deploy-coreminer.sh" \
         "uninstall-xcb-proxy.sh")

# Prüfen, ob Skript direkt lokal ausgeführt wird oder per curl | bash
if [[ -f "${SCRIPTS[0]}" ]]; then
  # Lokaler Modus (z. B. nach git clone)
  WORKDIR="$(pwd)"
  echo "📂 Lokaler Modus: benutze aktuellem Ordner $WORKDIR"
else
  # Remote-Modus (per curl | bash)
  GIT_REPO="https://raw.githubusercontent.com/fmando/proxmine/main"
  WORKDIR="$(mktemp -d)"
  chmod 700 "$WORKDIR"
  echo "📂 Remote Modus: Arbeitsverzeichnis $WORKDIR"

  # Skripte herunterladen
  for script in "${SCRIPTS[@]}"; do
    url="${GIT_REPO}/${script}"
    echo "⬇️  Lade ${script}..."
    curl -fsSL "$url" -o "${WORKDIR}/${script}"
    chmod +x "${WORKDIR}/${script}"
  done
fi

cd "$WORKDIR"

# Proxy deployen
echo "🔌 Starte Proxy-Deployment..."
./deploy-xcb-proxy.sh

# Coreminer deployen
echo "⛏  Starte Coreminer-Deployment..."
./deploy-coreminer.sh

# Uninstall-Skript nur bereitlegen
echo "🧹 Uninstall-Skript verfügbar unter: ${WORKDIR}/uninstall-xcb-proxy.sh"
echo "   (manuell ausführen, wenn du den Proxy wieder entfernen willst)"

echo "✅ Installation abgeschlossen!"
