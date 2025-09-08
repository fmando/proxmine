# 📦 Proxmine

Automatisches Deployment von **XCB Proxy** und **Coreminer**.  

---

## 🚀 Quick Start

Lade die Installations-Skripte mit nur einem Befehl herunter:

```bash
curl -fsSL https://raw.githubusercontent.com/fmando/proxmine/main/install.sh | bash
```

👉 Dadurch werden alle benötigten Skripte in ein lokales Verzeichnis `proxmine-scripts` geladen und ausführbar gemacht.  
Die Ausführung erfolgt **nicht automatisch**, damit du alle Eingaben interaktiv machen kannst.  

---

## ▶️ Interaktive Ausführung

Nach dem Download:

```bash
cd proxmine-scripts
./deploy-xcb-proxy.sh
./deploy-coreminer.sh
```

Währenddessen wirst du nach den gewünschten Einstellungen gefragt (Node-IP, Ports, CPU-Threads etc.).  

---

## 🧹 Deinstallation

Um den Proxy später zu entfernen, kannst du folgendes Skript ausführen:

```bash
./uninstall-xcb-proxy.sh
```

---

## ℹ️ Hinweise

- `install.sh` sorgt nur für das **Herunterladen und Vorbereiten** der Skripte.  
- Die eigentliche Ausführung (`deploy-coreminer.sh`, `deploy-xcb-proxy.sh`) bleibt bewusst **manuell**, damit du die Parameter interaktiv eingeben kannst.  
- Für den normalen Gebrauch reicht es, zuerst den **Quick Start** auszuführen und dann im `proxmine-scripts` Verzeichnis die gewünschten Skripte zu starten.  
