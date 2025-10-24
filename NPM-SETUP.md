# Nginx Proxy Manager (NPM) Setup für N8N Console

Diese Anleitung zeigt dir, wie du die N8N Console über Nginx Proxy Manager (NPM) öffentlich erreichbar machst.

## Voraussetzungen

- ✅ N8N Console läuft auf Port 3000
- ✅ Nginx Proxy Manager ist installiert und läuft
- ✅ Du hast eine Domain oder Subdomain (z.B. `console.deine-domain.de`)
- ✅ Beide Server sind im gleichen Netzwerk

## Server-IP herausfinden

Finde zunächst die lokale IP-Adresse des Servers, auf dem die Console läuft:

```bash
# Auf macOS/Linux:
ifconfig | grep "inet " | grep -v 127.0.0.1

# Oder:
hostname -I

# Oder:
ip addr show
```

Beispiel-IP: `192.168.12.100`

## Schritt 1: Console Server starten

Stelle sicher, dass der Server läuft:

```bash
cd /Users/shp-art/Documents/Github/N8N-Console
npm start
```

Der Server läuft jetzt auf:
- Lokal: `http://localhost:3000`
- Im Netzwerk: `http://192.168.12.100:3000` (nutze deine tatsächliche IP)

## Schritt 2: NPM Proxy Host einrichten

### 2.1 NPM Dashboard öffnen

Öffne Nginx Proxy Manager in deinem Browser:
```
http://192.168.12.85:81
```

### 2.2 Neuen Proxy Host erstellen

1. Klicke auf **"Proxy Hosts"**
2. Klicke auf **"Add Proxy Host"**

### 2.3 Details Tab konfigurieren

**Domain Names:**
```
console.deine-domain.de
```
(oder eine Subdomain deiner Wahl)

**Scheme:** `http`

**Forward Hostname / IP:**
```
192.168.12.100
```
(Die IP-Adresse des Servers, auf dem die Console läuft)

**Forward Port:**
```
3000
```

**Optionen aktivieren:**
- ✅ Cache Assets
- ✅ Block Common Exploits
- ✅ Websockets Support (WICHTIG für SSE!)

### 2.4 SSL Tab konfigurieren (Optional aber empfohlen)

**SSL Certificate:**
- Wähle "Request a new SSL Certificate"
- ✅ Force SSL
- ✅ HTTP/2 Support
- Gib deine E-Mail-Adresse ein
- ✅ Agree to Let's Encrypt Terms

**WICHTIG:** Deine Domain muss bereits auf deinen Server zeigen!

### 2.5 Advanced Tab (Optional)

Falls du zusätzliche Konfiguration benötigst:

```nginx
# Für bessere SSE Unterstützung
proxy_set_header Connection '';
proxy_http_version 1.1;
chunked_transfer_encoding off;
proxy_buffering off;
proxy_cache off;

# Timeouts für lange Verbindungen
proxy_read_timeout 86400;
proxy_send_timeout 86400;
```

## Schritt 3: Speichern und Testen

1. Klicke auf **"Save"**
2. Warte bis NPM die Konfiguration aktiviert hat
3. Teste den Zugriff:

```bash
# Von außen:
curl https://console.deine-domain.de/status

# Erwartete Antwort:
{
  "status": "online",
  "clients": 0,
  "uptime": 123.45,
  "timestamp": "2025-10-23T..."
}
```

## Schritt 4: Console im Browser öffnen

Öffne deinen Browser und navigiere zu:
```
https://console.deine-domain.de
```

Du solltest jetzt die grüne Terminal-Console sehen!

## Schritt 5: N8N konfigurieren

In deinem n8n Workflow, verwende jetzt die öffentliche URL:

**HTTP Request Node Konfiguration:**
- **Method:** POST
- **URL:** `https://console.deine-domain.de/webhook`
- **Body:**
```json
{
  "type": "success",
  "message": "Nachricht von n8n",
  "data": {{ $json }}
}
```

## Lokales Netzwerk (Alternative ohne Domain)

Falls du keine Domain hast und die Console nur im lokalen Netzwerk nutzen möchtest:

### NPM Konfiguration:

**Domain Names:**
```
console.local
```

**Forward Hostname / IP:**
```
192.168.12.100
```

**Forward Port:**
```
3000
```

Dann kannst du im lokalen Netzwerk zugreifen über:
```
http://192.168.12.85/
```
(Die IP deines NPM Servers)

Füge in deiner `/etc/hosts` (Linux/Mac) oder `C:\Windows\System32\drivers\etc\hosts` (Windows):
```
192.168.12.85  console.local
```

## Firewall-Regeln

Stelle sicher, dass folgende Ports erreichbar sind:

**Auf dem Console-Server:**
- Port 3000 (intern im Netzwerk)

**Auf dem NPM-Server:**
- Port 80 (HTTP)
- Port 443 (HTTPS)
- Port 81 (NPM Dashboard)

## Produktions-Setup mit PM2

Für einen stabilen Betrieb nutze PM2:

```bash
# PM2 installieren
npm install -g pm2

# Console als Dienst starten
pm2 start server.js --name "n8n-console"

# Auto-Start bei System-Neustart
pm2 startup
pm2 save

# Status prüfen
pm2 status

# Logs anschauen
pm2 logs n8n-console

# Neustart
pm2 restart n8n-console
```

## Troubleshooting

### Console nicht erreichbar

1. **Server läuft?**
   ```bash
   pm2 status
   # oder
   curl http://localhost:3000/status
   ```

2. **Firewall blockiert?**
   ```bash
   # Port 3000 öffnen (Ubuntu/Debian)
   sudo ufw allow 3000
   ```

3. **NPM Konfiguration prüfen:**
   - Ist die IP-Adresse korrekt?
   - Ist der Port 3000 eingetragen?
   - Ist "Websockets Support" aktiviert?

### SSE funktioniert nicht

1. In NPM "Websockets Support" aktivieren
2. Im Advanced Tab die SSE-Konfiguration hinzufügen (siehe oben)
3. Proxy Host neu starten

### SSL-Zertifikat funktioniert nicht

1. Domain muss auf deinen Server zeigen (DNS A-Record)
2. Port 80 und 443 müssen erreichbar sein
3. Warte 1-2 Minuten nach dem Erstellen

### n8n kann Console nicht erreichen

1. Verwende die öffentliche URL statt localhost
2. Prüfe ob CORS aktiviert ist (sollte automatisch funktionieren)
3. Teste mit curl:
   ```bash
   curl -X POST https://console.deine-domain.de/webhook \
     -H "Content-Type: application/json" \
     -d '{"type":"test","message":"Test"}'
   ```

## Monitoring

### Status überprüfen:
```bash
# Server Status
curl https://console.deine-domain.de/status

# PM2 Status
pm2 status

# Logs in Echtzeit
pm2 logs n8n-console --lines 50
```

### Health Check in n8n einrichten:

Erstelle einen Workflow, der regelmäßig den Status prüft:

```json
{
  "nodes": [
    {
      "name": "Schedule",
      "type": "n8n-nodes-base.scheduleTrigger",
      "parameters": {
        "rule": {
          "interval": [{ "field": "minutes", "minutesInterval": 5 }]
        }
      }
    },
    {
      "name": "Check Console",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "https://console.deine-domain.de/status",
        "method": "GET"
      }
    }
  ]
}
```

## Sicherheit

### Empfehlungen:

1. **SSL verwenden** - Immer HTTPS nutzen in Produktion
2. **Authentication hinzufügen** - Optional API-Key oder Basic Auth
3. **Rate Limiting** - In NPM oder direkt im Server
4. **IP Whitelist** - Nur bestimmte IPs erlauben (optional)

### IP Whitelist in NPM:

Im Advanced Tab:
```nginx
# Nur n8n Server erlauben
allow 192.168.12.85;
deny all;
```

## Zusammenfassung

Nach diesem Setup hast du:

- ✅ Console läuft auf Port 3000
- ✅ Server bindet an 0.0.0.0 für Netzwerk-Zugriff
- ✅ CORS ist aktiviert
- ✅ NPM leitet Traffic weiter
- ✅ SSL ist aktiviert (optional)
- ✅ n8n kann Nachrichten senden
- ✅ Console ist öffentlich erreichbar

**Deine URLs:**
- Console: `https://console.deine-domain.de`
- Webhook: `https://console.deine-domain.de/webhook`
- Status: `https://console.deine-domain.de/status`
