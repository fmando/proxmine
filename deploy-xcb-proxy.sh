#!/usr/bin/env bash
set -e

# === Config ===
GO_VERSION="1.22.6"
INSTALL_DIR="/opt/xcb-proxy"
BINARY_PATH="/usr/local/bin/xcb-proxy"

# === Helper Functions ===
log() { echo -e "\e[32m[INFO]\e[0m $1"; }
err() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

# === 1. Prüfen ob root ===
if [ "$EUID" -ne 0 ]; then
  err "Bitte als root ausführen (sudo)."
fi

# === 2. Node-IP/Port + Proxy-Port abfragen ===
read -p "Bitte Node-IP angeben [127.0.0.1]: " NODE_IP
NODE_IP=${NODE_IP:-127.0.0.1}

read -p "Bitte Node-Port angeben [18545]: " NODE_PORT
NODE_PORT=${NODE_PORT:-18545}

read -p "Bitte Proxy-Port angeben [8545]: " PROXY_PORT
PROXY_PORT=${PROXY_PORT:-8545}

CORE_NODE="http://${NODE_IP}:${NODE_PORT}"
SERVICE_NAME="xcb-proxy-${PROXY_PORT}.service"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

log "Verwende Node: $CORE_NODE"
log "Proxy wird auf Port: $PROXY_PORT laufen"
log "Service-Name: $SERVICE_NAME"

# === 3. Node-Port prüfen ===
log "Prüfe Erreichbarkeit von $NODE_IP:$NODE_PORT..."
if ! nc -z -w3 $NODE_IP $NODE_PORT; then
  err "Node $NODE_IP:$NODE_PORT ist nicht erreichbar – bitte prüfen!"
fi

# === 4. Go prüfen / installieren ===
if ! command -v go &>/dev/null; then
  log "Go nicht gefunden – installiere Go $GO_VERSION..."
  cd /tmp
  wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
  rm -rf /usr/local/go
  tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
  export PATH=$PATH:/usr/local/go/bin
  echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
else
  GOV=$(go version | awk '{print $3}' | sed 's/go//')
  log "Gefunden: Go $GOV"
fi

# === 5. Arbeitsverzeichnis vorbereiten ===
log "Erstelle Arbeitsverzeichnis $INSTALL_DIR..."
rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# === 6. Proxy-Quellcode einbetten ===
log "Lege Proxy-Quellcode an..."
cat > xcb-proxy.go <<'EOF'
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

type RPCRequest struct {
	JSONRPC string        `json:"jsonrpc"`
	Method  string        `json:"method"`
	Params  []interface{} `json:"params"`
	ID      interface{}   `json:"id"`
}

var (
	coreNode  string
	proxyPort string
	verbose   bool
	showHelp  bool
)

func init() {
	flag.StringVar(&coreNode, "node", "http://127.0.0.1:18545", "Core Node RPC URL (default: http://127.0.0.1:18545)")
	flag.StringVar(&proxyPort, "port", "8545", "Port for the proxy to listen on (default: 8545)")
	flag.BoolVar(&verbose, "v", false, "Enable verbose logging (all requests/responses)")
	flag.BoolVar(&showHelp, "?", false, "Show help and examples")

	flag.Usage = func() {
		fmt.Println("xcb-proxy - a lightweight RPC translator for Core Blockchain miners\n")
		fmt.Println("Usage:")
		fmt.Println("  xcb-proxy [options]\n")
		fmt.Println("Options:")
		flag.PrintDefaults()
		fmt.Println("\nExamples:")
		fmt.Println("  # Standardstart (Proxy auf 8545, Node lokal auf 18545)")
		fmt.Println("  ./xcb-proxy")
		fmt.Println("")
		fmt.Println("  # Proxy auf Port 9000, Node auf anderem Server")
		fmt.Println("  ./xcb-proxy -node http://89.58.45.70:18545 -port 9000")
		fmt.Println("")
		fmt.Println("  # Mit Debug-Logging (zeigt auch alle getWork Calls)")
		fmt.Println("  ./xcb-proxy -v")
	}
}

func main() {
	flag.Parse()

	if showHelp || contains(os.Args, "-h") || contains(os.Args, "--help") {
		flag.Usage()
		os.Exit(0)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		handleRPC(w, r, coreNode)
	})

	log.Printf("🚀 Proxy läuft auf :%s (Miner) -> %s (Node)", proxyPort, coreNode)
	log.Fatal(http.ListenAndServe(":"+proxyPort, nil))
}

func handleRPC(w http.ResponseWriter, r *http.Request, coreNode string) {
	body, _ := io.ReadAll(r.Body)

	var req RPCRequest
	if err := json.Unmarshal(body, &req); err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	switch req.Method {
	case "eth_getWork":
		if verbose {
			log.Printf("📥 eth_getWork -> xcb_getWork")
		}
		req.Method = "xcb_getWork"

	case "eth_submitWork", "xcb_submitWork":
		req.Method = "xcb_submitWork"
		if len(req.Params) >= 2 {
			req.Params = []interface{}{req.Params[0], req.Params[1]}
			log.Printf("📥 Miner submitted share nonce=%v header=%v", req.Params[0], req.Params[1])
		}
	}

	payload, _ := json.Marshal(req)
	resp, err := http.Post(coreNode, "application/json", bytes.NewReader(payload))
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)

	if req.Method == "xcb_submitWork" || verbose {
		log.Printf("📤 Node response: %s", string(respBody))
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(respBody)
}

func contains(slice []string, s string) bool {
	for _, v := range slice {
		if v == s {
			return true
		}
	}
	return false
}
EOF

# === 7. Build ===
log "Baue Proxy..."
go build -o $BINARY_PATH xcb-proxy.go

# === 8. Alte systemd Unit prüfen ===
if [ -f "$SERVICE_PATH" ]; then
  read -p "Service $SERVICE_NAME existiert bereits. Soll er gelöscht werden? [y/N]: " CONFIRM
  if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    log "Stoppe und lösche alten Service..."
    systemctl stop $SERVICE_NAME || true
    systemctl disable $SERVICE_NAME || true
    rm -f $SERVICE_PATH
  else
    err "Abbruch, da Service bereits existiert."
  fi
fi

# === 9. systemd Unit anlegen ===
log "Erstelle systemd Service..."
cat > $SERVICE_PATH <<EOF
[Unit]
Description=XCB Proxy Service (Port $PROXY_PORT)
After=network.target

[Service]
ExecStart=$BINARY_PATH -node $CORE_NODE -port $PROXY_PORT
Restart=always
RestartSec=5
User=root
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# === 10. Service aktivieren ===
log "Starte systemd Service $SERVICE_NAME..."
systemctl daemon-reload
systemctl enable --now $SERVICE_NAME

# === 11. Testen ===
sleep 2
log "Teste Proxy via curl..."
if curl -s -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getWork","params":[],"id":1}' \
  http://127.0.0.1:$PROXY_PORT | grep -q "result"; then
  log "Proxy erfolgreich gestartet und liefert Work 🎉"
else
  err "Proxy läuft, aber liefert kein Work – bitte Logs prüfen mit: journalctl -fu $SERVICE_NAME"
fi
