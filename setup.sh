#!/bin/bash

#######################################
# N8N Console - Setup Script
# Automatische Installation und Konfiguration
#######################################

set -e  # Exit bei Fehler

# Farben für bessere Lesbarkeit
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║           N8N Console - Setup Script                 ║
║                                                       ║
║  Automatische Installation und Konfiguration         ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

#######################################
# Funktionen
#######################################

print_step() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Prüfe ob Befehl existiert
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Eingabe mit Default-Wert
read_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    echo -e -n "${YELLOW}${prompt} [${default}]: ${NC}"
    read input
    eval $var_name="${input:-$default}"
}

#######################################
# 1. Systemprüfung
#######################################

print_step "Prüfe Systemvoraussetzungen..."

# Node.js prüfen
if command_exists node; then
    NODE_VERSION=$(node -v)
    print_success "Node.js gefunden: $NODE_VERSION"
else
    print_error "Node.js nicht gefunden!"
    echo "Bitte installiere Node.js von https://nodejs.org/"
    exit 1
fi

# npm prüfen
if command_exists npm; then
    NPM_VERSION=$(npm -v)
    print_success "npm gefunden: v$NPM_VERSION"
else
    print_error "npm nicht gefunden!"
    exit 1
fi

# git prüfen (optional)
if command_exists git; then
    print_success "git gefunden"
else
    print_warning "git nicht gefunden (optional)"
fi

#######################################
# 2. Konfiguration abfragen
#######################################

print_step "Konfiguration"

echo ""
echo -e "${BLUE}═════════════════════════════════════════${NC}"
echo -e "${BLUE}  Server-Konfiguration${NC}"
echo -e "${BLUE}═════════════════════════════════════════${NC}"

# Port
read_with_default "Console Server Port" "3000" CONSOLE_PORT

# Lokale IP automatisch erkennen
if command_exists ip; then
    DEFAULT_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo "localhost")
elif command_exists ifconfig; then
    DEFAULT_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n1 || echo "localhost")
else
    DEFAULT_IP="localhost"
fi

read_with_default "Lokale IP-Adresse" "$DEFAULT_IP" LOCAL_IP

echo ""
echo -e "${BLUE}═════════════════════════════════════════${NC}"
echo -e "${BLUE}  n8n Integration${NC}"
echo -e "${BLUE}═════════════════════════════════════════${NC}"

read_with_default "n8n Server IP" "192.168.12.190" N8N_IP
read_with_default "n8n Port" "5678" N8N_PORT
read_with_default "n8n Webhook ID" "" N8N_WEBHOOK_ID

if [ -z "$N8N_WEBHOOK_ID" ]; then
    print_warning "Keine Webhook-ID angegeben. Du kannst diese später in server.js eintragen."
    N8N_WEBHOOK_URL="http://${N8N_IP}:${N8N_PORT}/webhook/WEBHOOK_ID_HIER_EINTRAGEN"
else
    N8N_WEBHOOK_URL="http://${N8N_IP}:${N8N_PORT}/webhook/${N8N_WEBHOOK_ID}"
fi

echo ""
echo -e "${BLUE}═════════════════════════════════════════${NC}"
echo -e "${BLUE}  Home Assistant Integration (Optional)${NC}"
echo -e "${BLUE}═════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Hinweis:${NC} Home Assistant wird über n8n integriert."
echo "Die Console benötigt keinen direkten Home Assistant Zugriff."
echo ""
echo "Für Details siehe: HOME-ASSISTANT-SETUP.md"

# Keine HA-Konfiguration nötig - läuft über n8n
SETUP_HA="n"

#######################################
# 3. Dependencies installieren
#######################################

print_step "Installiere Dependencies..."

if npm install; then
    print_success "Dependencies erfolgreich installiert"
else
    print_error "Fehler beim Installieren der Dependencies"
    exit 1
fi

#######################################
# 4. Konfiguration in server.js schreiben
#######################################

print_step "Konfiguriere server.js..."

# Backup erstellen
if [ -f server.js ]; then
    cp server.js server.js.backup
    print_success "Backup erstellt: server.js.backup"
fi

# n8n Webhook URL aktualisieren
if [ ! -z "$N8N_WEBHOOK_ID" ]; then
    # Verwende sed mit unterschiedlicher Syntax für macOS und Linux
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL.*|const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || '${N8N_WEBHOOK_URL}';|g" server.js
    else
        # Linux
        sed -i "s|const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL.*|const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || '${N8N_WEBHOOK_URL}';|g" server.js
    fi
    print_success "n8n Webhook URL konfiguriert: $N8N_WEBHOOK_URL"
fi

# Port aktualisieren
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s|const PORT = process.env.PORT.*|const PORT = process.env.PORT || ${CONSOLE_PORT};|g" server.js
else
    sed -i "s|const PORT = process.env.PORT.*|const PORT = process.env.PORT || ${CONSOLE_PORT};|g" server.js
fi
print_success "Port konfiguriert: $CONSOLE_PORT"

#######################################
# 5. .env Datei erstellen (optional)
#######################################

print_step "Erstelle .env Datei..."

cat > .env << EOF
# N8N Console Konfiguration
# Generiert von setup.sh am $(date)

# Server Einstellungen
PORT=${CONSOLE_PORT}
LOCAL_IP=${LOCAL_IP}

# n8n Integration
N8N_WEBHOOK_URL=${N8N_WEBHOOK_URL}

# Home Assistant Integration erfolgt über n8n (siehe HOME-ASSISTANT-SETUP.md)
EOF

if [[ $SETUP_HA == "j" || $SETUP_HA == "J" ]]; then
    cat >> .env << EOF
HA_IP=${HA_IP}
HA_PORT=${HA_PORT}
HA_TOKEN=${HA_TOKEN}
HA_URL=http://${HA_IP}:${HA_PORT}
EOF
fi

print_success ".env Datei erstellt"

# .env zu .gitignore hinzufügen
if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
    echo ".env" >> .gitignore
    print_success ".env zu .gitignore hinzugefügt"
fi

#######################################
# 6. Systemd Service erstellen (Linux)
#######################################

if [[ "$OSTYPE" != "darwin"* ]] && command_exists systemctl; then
    print_step "Systemd Service konfigurieren..."

    read -p "Systemd Service erstellen für Auto-Start? (j/n): " CREATE_SERVICE

    if [[ $CREATE_SERVICE == "j" || $CREATE_SERVICE == "J" ]]; then
        CURRENT_DIR=$(pwd)
        CURRENT_USER=$(whoami)

        sudo tee /etc/systemd/system/n8n-console.service > /dev/null << EOF
[Unit]
Description=N8N Console Server
After=network.target

[Service]
Type=simple
User=${CURRENT_USER}
WorkingDirectory=${CURRENT_DIR}
ExecStart=$(which node) ${CURRENT_DIR}/server.js
Restart=on-failure
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=n8n-console
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        print_success "Systemd Service erstellt: /etc/systemd/system/n8n-console.service"

        echo ""
        echo "Service-Befehle:"
        echo "  sudo systemctl start n8n-console    # Service starten"
        echo "  sudo systemctl stop n8n-console     # Service stoppen"
        echo "  sudo systemctl status n8n-console   # Status anzeigen"
        echo "  sudo systemctl enable n8n-console   # Auto-Start aktivieren"
    fi
fi

#######################################
# 7. PM2 Setup (Alternative)
#######################################

if command_exists pm2; then
    print_step "PM2 Setup verfügbar"

    read -p "PM2 Process Manager verwenden? (j/n): " USE_PM2

    if [[ $USE_PM2 == "j" || $USE_PM2 == "J" ]]; then
        pm2 delete n8n-console 2>/dev/null || true
        pm2 start server.js --name n8n-console
        pm2 save

        print_success "PM2 konfiguriert"
        echo ""
        echo "PM2 Befehle:"
        echo "  pm2 status              # Status anzeigen"
        echo "  pm2 logs n8n-console    # Logs anzeigen"
        echo "  pm2 restart n8n-console # Neu starten"
        echo "  pm2 stop n8n-console    # Stoppen"
    fi
else
    print_warning "PM2 nicht installiert. Installiere mit: npm install -g pm2"
fi

#######################################
# 8. Firewall Konfiguration (Linux)
#######################################

if [[ "$OSTYPE" != "darwin"* ]] && command_exists ufw; then
    print_step "Firewall Konfiguration"

    read -p "Port ${CONSOLE_PORT} in UFW Firewall freigeben? (j/n): " SETUP_FIREWALL

    if [[ $SETUP_FIREWALL == "j" || $SETUP_FIREWALL == "J" ]]; then
        sudo ufw allow ${CONSOLE_PORT}/tcp comment 'N8N Console'
        print_success "Port ${CONSOLE_PORT} in UFW freigegeben"
    else
        print_warning "Stelle sicher, dass Port ${CONSOLE_PORT} von n8n erreichbar ist!"
    fi
fi

#######################################
# 9. Post-Installation Test
#######################################

print_step "Starte Post-Installation Tests..."

# Teste ob server.js existiert und korrekt ist
if [ ! -f "server.js" ]; then
    print_error "server.js nicht gefunden!"
    exit 1
fi

# Prüfe ob alle benötigten Dateien existieren
REQUIRED_FILES=("server.js" "index.html" "script.js" "styles.css" "package.json")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    print_error "Fehlende Dateien: ${MISSING_FILES[*]}"
    exit 1
else
    print_success "Alle benötigten Dateien gefunden"
fi

# Teste ob node_modules existiert
if [ ! -d "node_modules" ]; then
    print_error "node_modules nicht gefunden. npm install fehlgeschlagen?"
    exit 1
else
    print_success "Dependencies korrekt installiert"
fi

# Optionaler Live-Test
echo ""
read -p "Möchtest du einen Live-Test durchführen? Der Server wird kurz gestartet. (j/n): " RUN_TEST

if [[ $RUN_TEST == "j" || $RUN_TEST == "J" ]]; then
    print_step "Starte Test-Server..."

    # Starte Server im Hintergrund
    PORT=${CONSOLE_PORT} node server.js &
    SERVER_PID=$!

    # Warte kurz auf Server-Start
    sleep 3

    # Teste Status-Endpoint
    if command_exists curl; then
        TEST_URL="http://localhost:${CONSOLE_PORT}/status"
        print_step "Teste Endpoint: $TEST_URL"

        if curl -s -f "$TEST_URL" > /dev/null 2>&1; then
            print_success "Server läuft und antwortet korrekt!"

            # Teste auch /test Endpoint
            curl -s "http://localhost:${CONSOLE_PORT}/test" > /dev/null 2>&1
            print_success "Test-Nachricht erfolgreich gesendet"
        else
            print_error "Server antwortet nicht auf Port ${CONSOLE_PORT}"
        fi
    else
        print_warning "curl nicht verfügbar, überspringe Endpoint-Tests"
    fi

    # Stoppe Test-Server
    kill $SERVER_PID 2>/dev/null
    print_success "Test-Server gestoppt"
fi

#######################################
# 10. Browser Auto-Start (Optional)
#######################################

echo ""
read -p "Möchtest du die Console jetzt im Browser öffnen? (j/n): " OPEN_BROWSER

if [[ $OPEN_BROWSER == "j" || $OPEN_BROWSER == "J" ]]; then
    CONSOLE_URL="http://${LOCAL_IP}:${CONSOLE_PORT}"

    # Starte Server im Hintergrund wenn nicht bereits gestartet (z.B. durch PM2)
    if [[ $USE_PM2 != "j" && $USE_PM2 != "J" ]]; then
        print_step "Starte Server..."
        PORT=${CONSOLE_PORT} node server.js &
        SERVER_PID=$!
        sleep 2

        echo -e "${YELLOW}Server läuft im Hintergrund (PID: $SERVER_PID)${NC}"
        echo -e "${YELLOW}Zum Stoppen: kill $SERVER_PID${NC}"
    fi

    # Öffne Browser
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open "$CONSOLE_URL"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists xdg-open; then
            xdg-open "$CONSOLE_URL"
        elif command_exists gnome-open; then
            gnome-open "$CONSOLE_URL"
        else
            print_warning "Kein Browser-Starter gefunden. Öffne manuell: $CONSOLE_URL"
        fi
    fi

    print_success "Browser geöffnet: $CONSOLE_URL"
fi

#######################################
# 11. Zusammenfassung
#######################################

echo ""
echo -e "${GREEN}═════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup erfolgreich abgeschlossen! 🎉${NC}"
echo -e "${GREEN}═════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}Konfiguration:${NC}"
echo "  📍 Console URL:        http://${LOCAL_IP}:${CONSOLE_PORT}"
echo "  📡 n8n Webhook:        ${N8N_WEBHOOK_URL}"
if [[ $SETUP_HA == "j" || $SETUP_HA == "J" ]]; then
    echo "  🏠 Home Assistant:     http://${HA_IP}:${HA_PORT}"
fi

echo ""
echo -e "${BLUE}Server starten:${NC}"
echo "  npm start                    # Normal starten"
echo "  npm run dev                  # Mit Auto-Reload (Entwicklung)"
if command_exists pm2 && [[ $USE_PM2 == "j" || $USE_PM2 == "J" ]]; then
    echo "  pm2 start n8n-console        # Mit PM2 (bereits konfiguriert)"
fi

echo ""
echo -e "${BLUE}Quick-Start Befehle:${NC}"
echo "  # Console testen:"
echo "  curl http://${LOCAL_IP}:${CONSOLE_PORT}/test"
echo ""
echo "  # Nachricht an Console senden:"
echo "  curl -X POST http://${LOCAL_IP}:${CONSOLE_PORT}/message \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"type\":\"success\",\"message\":\"Test\"}'"

echo ""
echo -e "${BLUE}n8n Integration:${NC}"
echo "  1. Erstelle HTTP Request Node in n8n"
echo "  2. Method: POST"
echo "  3. URL: http://${LOCAL_IP}:${CONSOLE_PORT}/webhook"
echo "  4. Body: {\"type\":\"info\",\"message\":\"Test von n8n\"}"

echo ""
echo -e "${BLUE}Nächste Schritte:${NC}"
echo "  1. Öffne n8n und konfiguriere den Workflow"
echo "  2. Teste die Console: http://${LOCAL_IP}:${CONSOLE_PORT}"
echo "  3. Verwende /help in der Console für alle Befehle"
if [[ $SETUP_HA == "j" || $SETUP_HA == "J" ]]; then
    echo "  4. Lies HOME-ASSISTANT-SETUP.md für Home Assistant Integration"
fi

echo ""
echo -e "${BLUE}Dokumentation:${NC}"
echo "  📄 README.md                 - Hauptdokumentation"
echo "  📄 CLAUDE.md                 - Entwickler-Dokumentation"
echo "  📄 .env                      - Deine Konfiguration"
if [[ $SETUP_HA == "j" || $SETUP_HA == "J" ]]; then
    echo "  📄 HOME-ASSISTANT-SETUP.md   - Home Assistant Integration"
fi

echo ""
echo -e "${YELLOW}⚠ Wichtig:${NC}"
echo "  - Backup erstellt: server.js.backup"
echo "  - Konfiguration gespeichert in: .env"
echo "  - Port ${CONSOLE_PORT} muss von n8n erreichbar sein!"
if [[ "$OSTYPE" != "darwin"* ]] && command_exists ufw; then
    if [[ $SETUP_FIREWALL != "j" && $SETUP_FIREWALL != "J" ]]; then
        echo "  - Firewall: Port ${CONSOLE_PORT} ggf. manuell freigeben"
    fi
fi
echo "  - Sensible Daten NICHT zu GitHub committen!"

echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "  - Port belegt: Andere Anwendung beenden oder PORT in .env ändern"
echo "  - n8n keine Verbindung: Firewall/Netzwerk prüfen"
echo "  - Logs anzeigen: pm2 logs n8n-console (falls PM2 verwendet)"
echo "  - Status prüfen: curl http://localhost:${CONSOLE_PORT}/status"

echo ""
echo -e "${GREEN}Viel Erfolg mit deinem n8n Chat! 🚀${NC}"
echo ""
