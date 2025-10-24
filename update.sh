#!/bin/bash

#######################################
# N8N Console - Update Script
# Lädt die neueste Version von GitHub und startet den Service neu
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
║           N8N Console - Update Script                ║
║                                                       ║
║  Aktualisiert das Projekt von GitHub                 ║
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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# 1. Voraussetzungen prüfen
#######################################

print_step "Prüfe Voraussetzungen..."

# Prüfe ob wir in einem Git-Repository sind
if [ ! -d ".git" ]; then
    print_error "Kein Git-Repository gefunden!"
    echo "Dieses Skript muss im N8N-Console Verzeichnis ausgeführt werden."
    exit 1
fi

# Git prüfen
if ! command_exists git; then
    print_error "Git nicht installiert!"
    exit 1
fi

print_success "Git Repository gefunden"

#######################################
# 2. Aktuelle Version sichern
#######################################

print_step "Erstelle Backup der aktuellen Version..."

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/backup_${TIMESTAMP}"

# Erstelle Backup-Verzeichnis falls nicht vorhanden
mkdir -p "$BACKUP_DIR"

# Backup wichtiger Dateien
if [ -f "server.js" ]; then
    cp server.js "${BACKUP_PATH}_server.js"
    print_success "server.js gesichert"
fi

if [ -f ".env" ]; then
    cp .env "${BACKUP_PATH}.env"
    print_success ".env gesichert"
fi

#######################################
# 3. Prüfe auf lokale Änderungen
#######################################

print_step "Prüfe auf lokale Änderungen..."

# Prüfe ob es uncommitted changes gibt
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    print_warning "Lokale Änderungen gefunden!"
    echo ""
    git status --short
    echo ""

    read -p "Möchtest du die lokalen Änderungen stashen? (j/n): " STASH_CHANGES

    if [[ $STASH_CHANGES == "j" || $STASH_CHANGES == "J" ]]; then
        git stash push -m "Auto-stash vor Update $(date +%Y-%m-%d_%H:%M:%S)"
        print_success "Änderungen gestasht"
        STASHED=true
    else
        print_error "Update abgebrochen. Bitte committe oder stashe deine Änderungen."
        exit 1
    fi
else
    print_success "Keine lokalen Änderungen"
    STASHED=false
fi

#######################################
# 4. Aktuelle Version speichern
#######################################

CURRENT_COMMIT=$(git rev-parse --short HEAD)
print_step "Aktuelle Version: $CURRENT_COMMIT"

#######################################
# 5. Von GitHub pullen
#######################################

print_step "Lade Updates von GitHub..."

# Hole neueste Änderungen
if git pull origin main; then
    NEW_COMMIT=$(git rev-parse --short HEAD)

    if [ "$CURRENT_COMMIT" == "$NEW_COMMIT" ]; then
        print_success "Bereits auf dem neuesten Stand!"
        echo "Version: $CURRENT_COMMIT"

        # Stash zurückholen falls nötig
        if [ "$STASHED" = true ]; then
            git stash pop
            print_success "Lokale Änderungen wiederhergestellt"
        fi

        exit 0
    else
        print_success "Update erfolgreich!"
        echo "  Alt: $CURRENT_COMMIT"
        echo "  Neu: $NEW_COMMIT"
    fi
else
    print_error "Git pull fehlgeschlagen!"

    # Stash zurückholen falls nötig
    if [ "$STASHED" = true ]; then
        git stash pop
        print_success "Lokale Änderungen wiederhergestellt"
    fi

    exit 1
fi

#######################################
# 6. Prüfe auf package.json Änderungen
#######################################

print_step "Prüfe Dependencies..."

# Prüfe ob package.json geändert wurde
if git diff --name-only $CURRENT_COMMIT HEAD | grep -q "package.json"; then
    print_warning "package.json wurde geändert!"

    read -p "npm install ausführen? (j/n): " RUN_NPM_INSTALL

    if [[ $RUN_NPM_INSTALL == "j" || $RUN_NPM_INSTALL == "J" ]]; then
        print_step "Installiere Dependencies..."

        if npm install; then
            print_success "Dependencies erfolgreich aktualisiert"
        else
            print_error "npm install fehlgeschlagen"
            exit 1
        fi
    fi
else
    print_success "Keine Änderungen an Dependencies"
fi

#######################################
# 7. .env Datei wiederherstellen
#######################################

if [ -f "${BACKUP_PATH}.env" ]; then
    print_step "Stelle .env wieder her..."
    cp "${BACKUP_PATH}.env" .env
    print_success ".env wiederhergestellt"
fi

# Stash zurückholen falls nötig
if [ "$STASHED" = true ]; then
    print_step "Stelle lokale Änderungen wieder her..."
    if git stash pop; then
        print_success "Lokale Änderungen wiederhergestellt"
    else
        print_warning "Konflikt beim Wiederherstellen. Bitte manuell lösen."
    fi
fi

#######################################
# 8. Service neu starten
#######################################

print_step "Starte Service neu..."

SERVICE_RESTARTED=false

# Prüfe PM2
if command_exists pm2; then
    if pm2 list | grep -q "n8n-console"; then
        print_step "Starte PM2 Service neu..."

        pm2 restart n8n-console

        if [ $? -eq 0 ]; then
            print_success "PM2 Service erfolgreich neugestartet"
            SERVICE_RESTARTED=true

            echo ""
            echo "Logs anzeigen mit: pm2 logs n8n-console"
        else
            print_error "PM2 Restart fehlgeschlagen"
        fi
    fi
fi

# Prüfe Systemd (Linux)
if [ "$SERVICE_RESTARTED" = false ] && command_exists systemctl; then
    if systemctl is-active --quiet n8n-console 2>/dev/null; then
        print_step "Starte Systemd Service neu..."

        sudo systemctl restart n8n-console

        if [ $? -eq 0 ]; then
            print_success "Systemd Service erfolgreich neugestartet"
            SERVICE_RESTARTED=true

            echo ""
            echo "Status anzeigen mit: sudo systemctl status n8n-console"
        else
            print_error "Systemd Restart fehlgeschlagen"
        fi
    fi
fi

# Keine automatische Service-Verwaltung gefunden
if [ "$SERVICE_RESTARTED" = false ]; then
    print_warning "Kein laufender Service gefunden (PM2 oder Systemd)"
    echo "Bitte starte den Server manuell:"
    echo "  npm start"
    echo "  oder"
    echo "  pm2 restart n8n-console"
fi

#######################################
# 9. Zusammenfassung
#######################################

echo ""
echo -e "${GREEN}═════════════════════════════════════════${NC}"
echo -e "${GREEN}  Update erfolgreich abgeschlossen! 🎉${NC}"
echo -e "${GREEN}═════════════════════════════════════════${NC}"
echo ""

echo -e "${BLUE}Versions-Info:${NC}"
echo "  Vorher: $CURRENT_COMMIT"
echo "  Nachher: $NEW_COMMIT"
echo ""

echo -e "${BLUE}Änderungen:${NC}"
git log --oneline $CURRENT_COMMIT..HEAD | head -n 10

echo ""
echo -e "${BLUE}Geänderte Dateien:${NC}"
git diff --name-status $CURRENT_COMMIT HEAD

echo ""
echo -e "${BLUE}Backup:${NC}"
if [ -f "${BACKUP_PATH}_server.js" ]; then
    echo "  server.js: ${BACKUP_PATH}_server.js"
fi
if [ -f "${BACKUP_PATH}.env" ]; then
    echo "  .env: ${BACKUP_PATH}.env"
fi

echo ""
echo -e "${BLUE}Nützliche Befehle:${NC}"
if [ "$SERVICE_RESTARTED" = true ]; then
    if pm2 list | grep -q "n8n-console" 2>/dev/null; then
        echo "  pm2 logs n8n-console        # Logs anzeigen"
        echo "  pm2 status                  # Status prüfen"
    elif systemctl is-active --quiet n8n-console 2>/dev/null; then
        echo "  sudo systemctl status n8n-console   # Status prüfen"
        echo "  sudo journalctl -u n8n-console -f  # Logs anzeigen"
    fi
fi
echo "  git log --oneline -10       # Letzte Commits anzeigen"
echo "  git stash list              # Gestashte Änderungen anzeigen"

echo ""
echo -e "${GREEN}N8N Console läuft auf dem neuesten Stand! 🚀${NC}"
echo ""
