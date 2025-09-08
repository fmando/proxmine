# 📦 Proxmine

Automatisches Deployment von **XCB Proxy** und **Coreminer** mit einem einzigen Befehl.  

---

## 🚀 Quick Start

Einfach diesen Befehl in der Konsole ausführen:

```bash
curl -fsSL https://raw.githubusercontent.com/fmando/proxmine/main/install.sh | bash
```

Das Script erledigt automatisch:

1. Proxy-Deployment starten  
2. Coreminer-Deployment starten  
3. Uninstall-Skript bereitlegen (aber **nicht** ausführen)  

---

## 🖥️ Alternative: Installation via git clone

Falls du das Repository lokal klonen möchtest:

```bash
git clone https://github.com/fmando/proxmine.git
cd proxmine
chmod +x install.sh
./install.sh
```

Das Ergebnis ist identisch – die Skripte werden aus dem lokalen Verzeichnis genutzt.  

---

## 🧹 Deinstallation

Falls du später den Proxy wieder entfernen möchtest, steht dir im Repo bzw. Arbeitsverzeichnis das Skript bereit:

```bash
./uninstall-xcb-proxy.sh
```

---

## ℹ️ Hinweise

- Das Installationsskript (`install.sh`) erkennt automatisch, ob es **remote** (`curl | bash`) oder **lokal** (`git clone`) gestartet wurde.  
- Für den normalen Gebrauch reicht der **Quick Start** völlig aus.  
