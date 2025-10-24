# N8N Console

Eine moderne Console-Webseite mit Terminal-Look als **bidirektionale** Kommunikation für n8n Workflows.

## Features

- 🎨 Modernes Terminal-Design mit Retro-Look
- 📡 Real-time Updates über Server-Sent Events (SSE)
- 🔄 **Bidirektional**: n8n → Console UND Console → n8n
- 🎯 Webhook-Unterstützung für n8n
- 💬 Chat-Befehle (/help, /clear, /test, /status)
- 🎨 Verschiedene Nachrichtentypen (Info, Success, Warning, Error)
- 📊 Status-Anzeige mit Verbindungsstatus
- 🧹 Clear-Funktion zum Löschen der Console
- 🏠 Home Assistant Integration (optional)

## Quick Start

### 1. Projekt herunterladen

```bash
# Mit Git (empfohlen):
git clone https://github.com/SHP-ART/N8N-Console.git
cd N8N-Console
```

**Oder ohne Git:**
1. Gehe zu https://github.com/SHP-ART/N8N-Console
2. Klicke auf den grünen **"Code"** Button
3. Wähle **"Download ZIP"**
4. Entpacke die ZIP-Datei
5. Öffne ein Terminal im entpackten Ordner

### 2. Installation & Start

**Automatisch (empfohlen):**
```bash
./setup.sh
```

Das Setup-Skript konfiguriert alles automatisch und startet die Console.

**Manuell:**
```bash
npm install
npm start
```

### 3. Console öffnen

Öffne deinen Browser und gehe zu:
```
http://localhost:3000
```

Fertig! 🎉

### Voraussetzungen

Bevor du startest, stelle sicher, dass folgendes installiert ist:

- **Node.js** (Version 14 oder höher) - [Download](https://nodejs.org/)
- **npm** (kommt mit Node.js)
- **Git** (optional, für Updates) - [Download](https://git-scm.com/)

**Prüfe deine Installation:**
```bash
node -v   # Sollte v14.0.0 oder höher anzeigen
npm -v    # Sollte eine Versionsnummer anzeigen
```

## Installation

### Automatische Installation (empfohlen)

```bash
git clone https://github.com/SHP-ART/N8N-Console.git
cd N8N-Console
./setup.sh
```

Das Setup-Skript führt dich durch die komplette Konfiguration.

### Manuelle Installation

1. Dependencies installieren:
```bash
npm install
```

2. Server starten:
```bash
npm start
```

3. Für Entwicklung mit Auto-Reload:
```bash
npm run dev
```

Der Server läuft standardmäßig auf `http://localhost:3000`

## Updates

### Automatisches Update von GitHub

```bash
./update.sh
```

Das Update-Skript:
- ✅ Erstellt automatische Backups (.env & server.js)
- ✅ Lädt neueste Version von GitHub
- ✅ Prüft auf package.json Änderungen
- ✅ Installiert Dependencies bei Bedarf
- ✅ Startet PM2/Systemd Service automatisch neu
- ✅ Zeigt Changelog an

### Manuelles Update

```bash
git pull origin main
npm install  # falls package.json geändert wurde
pm2 restart n8n-console  # oder: sudo systemctl restart n8n-console
```

## Verwendung

### Console öffnen

Öffne deinen Browser und navigiere zu:
```
http://localhost:3000
```

### API Endpoints

#### 1. Webhook für n8n (POST /webhook)

Verwende diesen Endpoint in deinen n8n Workflows:

```bash
curl -X POST http://localhost:3000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "info",
    "message": "Workflow erfolgreich ausgeführt",
    "data": {
      "workflowId": "123",
      "status": "success"
    }
  }'
```

#### 2. Einfache Nachricht (POST /message)

```bash
curl -X POST http://localhost:3000/message \
  -H "Content-Type: application/json" \
  -d '{
    "type": "success",
    "message": "Daten erfolgreich verarbeitet"
  }'
```

#### 3. Test-Nachricht (GET /test)

```bash
curl http://localhost:3000/test
```

#### 4. Server Status (GET /status)

```bash
curl http://localhost:3000/status
```

## Nachrichtentypen

Die Console unterstützt verschiedene Nachrichtentypen mit unterschiedlichen Farben:

- `info` - Blau (Informationen)
- `success` - Grün (Erfolg)
- `warning` - Orange (Warnungen)
- `error` - Rot (Fehler)
- `system` - Grau (System-Nachrichten)

## n8n Integration

### Schritt 1: HTTP Request Node in n8n

1. Füge einen "HTTP Request" Node zu deinem Workflow hinzu
2. Konfiguriere den Node:
   - **Method**: POST
   - **URL**: `http://localhost:3000/webhook`
   - **Body Content Type**: JSON
   - **Body**:
   ```json
   {
     "type": "{{ $json.type }}",
     "message": "{{ $json.message }}",
     "data": {{ $json.data }}
   }
   ```

### Schritt 2: Beispiel Workflow

```json
{
  "type": "success",
  "message": "Neuer Kunde registriert",
  "data": {
    "name": "Max Mustermann",
    "email": "max@example.com",
    "timestamp": "2025-10-23T10:30:00Z"
  }
}
```

## Tastenkombinationen

- `Strg + T` - Test-Nachricht hinzufügen (nur für Entwicklung)

## Anpassungen

### Port ändern

Setze die Umgebungsvariable `PORT`:
```bash
PORT=8080 npm start
```

### Styling anpassen

Bearbeite `styles.css` um das Aussehen der Console anzupassen.

### Farben ändern

Die Hauptfarbe (Standard: Grün `#00ff00`) kann in `styles.css` geändert werden:
- Suche nach `#00ff00` und ersetze es mit deiner gewünschten Farbe
- Für einen klassischen Amber-Look verwende `#ffb000`
- Für einen Matrix-Look behalte `#00ff00`

## Beispiel-Screenshots

Die Console zeigt:
- Header mit Titel und Kontrollen
- Scrollbare Nachrichtenliste mit Timestamps
- Footer mit Status-Informationen
- Unterschiedliche Farben je nach Nachrichtentyp

## Technologie-Stack

- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Backend**: Node.js, Express
- **Real-time**: Server-Sent Events (SSE)

## Fehlerbehandlung

Bei Verbindungsverlust versucht die Console automatisch alle 5 Sekunden eine Wiederverbindung herzustellen.

## Support

Bei Problemen oder Fragen erstelle ein Issue im Repository.

## Lizenz

MIT
