#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starte Proxmine Installer ..."

# Repository-URL
GIT_REPO="https://raw.githubusercontent.com/fmando/proxmine/main"
SCRIPTS=("deploy-xcb-proxy.sh" \
         "deploy-coreminer.sh" \
         "uninstall-xcb-proxy.sh")

# Arbeitsverzeichnis (aktuelles Repo oder tmp)
WORKDIR="$(pwd)/proxmine-scripts"
mkdir -p "$WORKDIR"
chmod 700 "$WORKDIR"
echo "📂 Lade Skripte nach: $WORKDIR"

# Skripte herunterladen
for script in "${SCRIPTS[@]}"; do
  url="${GIT_REPO}/${script}"
  echo "⬇️  Lade ${script}..."
  curl -fsSL "$url" -o "${WORKDIR}/${script}"
  chmod +x "${WORKDIR}/${script}"
done

echo
echo "✅ Alle Skripte wurden heruntergeladen."
echo
echo "👉 Bitte wechsle jetzt in das Arbeitsverzeichnis:"
echo "   cd $WORKDIR"
echo
echo "👉 Und führe die Skripte manuell aus, damit du alle Fragen interaktiv beantworten kannst:"
echo "   ./deploy-xcb-proxy.sh"
echo "   ./deploy-coreminer.sh"
echo
echo "🧹 Für Deinstallation kannst du später verwenden:"
echo "   ./uninstall-xcb-proxy.sh"
echo
echo "🚀 Installation vorbereitet – bitte jetzt manuell fortfahren!"
