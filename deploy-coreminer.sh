#!/bin/bash
set -e

echo "=========================================================="
echo " Coreminer Deploy Script "
echo "=========================================================="
echo

# --- Docker prüfen / installieren ---
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker nicht gefunden – Installation wird gestartet..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo mkdir -m 0755 -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo "Docker wurde installiert."
else
  echo "Docker ist bereits installiert."
fi

# --- Arbeitsverzeichnis prüfen ---
echo
echo "Aktuelles Arbeitsverzeichnis: $(pwd)"
read -p "Hier deployen? [Y/n] " CONFIRM

if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
  echo "Wechsle zu /opt/coreminer ..."
  sudo mkdir -p /opt/coreminer
  cd /opt/coreminer
  echo "Arbeitsverzeichnis: $(pwd)"
fi

# --- Dockerfile erzeugen (falls nicht vorhanden) ---
if [ ! -f Dockerfile ]; then
  echo "Erzeuge Dockerfile ..."
  cat > Dockerfile <<'EOF'
# -------- Build Stage --------
FROM buildpack-deps:bullseye AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake make g++ git && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Coreminer Repo mit Submodules klonen
RUN git clone --recursive https://github.com/catchthatrabbit/coreminer.git
WORKDIR /src/coreminer

# Build
RUN mkdir build && cd build && cmake .. && make -j$(nproc)

# -------- Runtime Stage --------
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl && rm -rf /var/lib/apt/lists/*

# Nur das Binary übernehmen
COPY --from=builder /src/coreminer/build/coreminer/coreminer /usr/local/bin/coreminer

# Default Start
ENTRYPOINT ["coreminer"]
EOF
else
  echo "Dockerfile existiert bereits – überspringe Erzeugung."
fi

# --- Proxy-Port abfragen ---
read -p "Bitte Proxy-Port eingeben (Default: 8545): " PROXY_PORT
PROXY_PORT=${PROXY_PORT:-8545}

echo
echo "Proxy-Port: $PROXY_PORT"
echo

# --- Image bauen ---
echo "Baue Coreminer Image (kann 10+ Minuten dauern)..."
docker build -t coreminer .

echo
echo "=========================================================="
echo " Docker-Image 'coreminer' wurde gebaut."
echo "=========================================================="
echo

# --- Startskript erzeugen ---
cat > start-coreminer.sh <<EOF
#!/bin/bash
set -e

THREADS=\$1
TOTAL_CPUS=\$(nproc)

if [ -z "\$THREADS" ]; then
  THREADS=\$TOTAL_CPUS
fi

echo "Nutze \$THREADS von \$TOTAL_CPUS Threads für Coreminer."

docker rm -f coreminer 2>/dev/null || true
docker run -d \\
  --name coreminer \\
  --restart unless-stopped \\
  --network host \\
  coreminer \\
  --pool http://127.0.0.1:$PROXY_PORT -t \$THREADS
EOF

chmod +x start-coreminer.sh

echo
echo "=========================================================="
echo "Startskript 'start-coreminer.sh' wurde erzeugt."
echo
echo "Beispiele:"
echo "./start-coreminer.sh         # nutzt alle CPUs"
echo "./start-coreminer.sh 4       # nutzt 4 Threads"
echo
echo "Logs ansehen mit:"
echo "docker logs -f coreminer"
echo "=========================================================="
