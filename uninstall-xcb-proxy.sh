#!/usr/bin/env bash
set -e

# === Config ===
INSTALL_DIR="/opt/xcb-proxy"
BINARY_PATH="/usr/local/bin/xcb-proxy"

# === Helper Functions ===
log() { echo -e "\e[32m[INFO]\e[0m $1"; }
err() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
  err "Bitte als root ausführen (sudo)."
fi

log "Suche nach laufenden xcb-proxy Services..."
SERVICES=$(systemctl list-unit-files | grep xcb-proxy | awk '{print $1}')

if [ -n "$SERVICES" ]; then
  for SVC in $SERVICES; do
    log "Stoppe und deaktiviere $SVC..."
    systemctl stop "$SVC" || true
    systemctl disable "$SVC" || true
    rm -f "/etc/systemd/system/$SVC"
  done
  systemctl daemon-reload
  systemctl reset-failed
  log "Alle xcb-proxy Services wurden entfernt."
else
  log "Keine xcb-proxy Services gefunden."
fi

if [ -f "$BINARY_PATH" ]; then
  read -p "Soll das Binary $BINARY_PATH gelöscht werden? [y/N]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    rm -f "$BINARY_PATH"
    log "Binary gelöscht."
  fi
fi

if [ -d "$INSTALL_DIR" ]; then
  read -p "Soll das Arbeitsverzeichnis $INSTALL_DIR gelöscht werden? [y/N]: " CONFIRM2
  if [[ "$CONFIRM2" =~ ^[Yy]$ ]]; then
    rm -rf "$INSTALL_DIR"
    log "Arbeitsverzeichnis gelöscht."
  fi
fi

log "Deinstallation abgeschlossen ✅"
