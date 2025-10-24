# 🚀 Quick Start - NPM Setup

## Deine Netzwerk-Konfiguration

**Console Server IP:** `192.168.12.168`
**Console Server Port:** `3000`
**N8N Server IP:** `192.168.12.85`
**N8N Port:** `5678`
**N8N Webhook:** `http://192.168.12.85:5678/webhook-test/bbe5e339-573c-4917-8649-a27f29e6330d`

---

## ✅ Server Status

Der Console-Server läuft jetzt und ist bereit für NPM!

- 🌐 Lokal: `http://localhost:3000`
- 🌍 Im Netzwerk: `http://192.168.12.168:3000`

### Teste die Erreichbarkeit:

```bash
# Von diesem Server:
curl http://localhost:3000/status

# Von einem anderen Gerät im Netzwerk:
curl http://192.168.12.168:3000/status
```

---

## 📋 NPM Einrichtung in 3 Schritten

### Schritt 1: NPM Dashboard öffnen

Öffne in deinem Browser:
```
http://192.168.12.85:81
```

### Schritt 2: Proxy Host erstellen

**Klicke auf:** Proxy Hosts → Add Proxy Host

**Konfiguration:**

**Details Tab:**
- **Domain Names:** `console.deinedomain.de` (oder deine gewünschte (Sub-)Domain)
- **Scheme:** `http`
- **Forward Hostname / IP:** `192.168.12.168`
- **Forward Port:** `3000`
- **Cache Assets:** ✅
- **Block Common Exploits:** ✅
- **Websockets Support:** ✅ **WICHTIG!**

**SSL Tab (Optional):**
- **SSL Certificate:** Request a new SSL Certificate
- **Force SSL:** ✅
- **HTTP/2 Support:** ✅
- **E-Mail:** deine@email.de

**Advanced Tab (für bessere SSE Unterstützung):**
```nginx
proxy_set_header Connection '';
proxy_http_version 1.1;
chunked_transfer_encoding off;
proxy_buffering off;
proxy_cache off;
proxy_read_timeout 86400;
proxy_send_timeout 86400;
```

### Schritt 3: Speichern & Testen

Klicke auf **Save** und teste:

```bash
# Status prüfen
curl https://console.deinedomain.de/status

# Test-Nachricht senden
curl -X POST https://console.deinedomain.de/message \
  -H "Content-Type: application/json" \
  -d '{"type":"success","message":"NPM Setup erfolgreich!"}'
```

---

## 🔗 N8N Integration

### Option 1: Direkter Zugriff (Lokal)

In deinem n8n Workflow (da beide im gleichen Netzwerk sind):

**HTTP Request Node:**
- **URL:** `http://192.168.12.168:3000/webhook`
- **Method:** POST
- **Body:**
```json
{
  "type": "success",
  "message": "Nachricht von n8n",
  "data": {{ $json }}
}
```

### Option 2: Über NPM (Öffentlich)

Nach NPM-Setup:

**HTTP Request Node:**
- **URL:** `https://console.deinedomain.de/webhook`
- **Method:** POST
- **Body:**
```json
{
  "type": "success",
  "message": "Nachricht von n8n über NPM",
  "data": {{ $json }}
}
```

---

## 🧪 Test-Workflow für n8n

Erstelle einen einfachen Test-Workflow in n8n:

1. **Schedule Trigger** (alle 1 Minute)
2. **HTTP Request Node:**
   - URL: `http://192.168.12.168:3000/webhook`
   - Method: POST
   - Body:
   ```json
   {
     "type": "info",
     "message": "Automatische Nachricht alle 60 Sekunden",
     "data": {
       "timestamp": "{{ $now }}",
       "workflow": "Test"
     }
   }
   ```

3. Aktiviere den Workflow und öffne die Console im Browser!

---

## 📱 Console öffnen

**Lokal:**
```
http://localhost:3000
```

**Im Netzwerk:**
```
http://192.168.12.168:3000
```

**Über NPM (nach Setup):**
```
https://console.deinedomain.de
```

---

## 🎯 Produktions-Setup mit PM2

Für dauerhaften Betrieb:

```bash
# PM2 installieren
npm install -g pm2

# Console als Service starten
cd /Users/shp-art/Documents/Github/N8N-Console
pm2 start server.js --name n8n-console

# Auto-Start bei System-Neustart
pm2 startup
pm2 save

# Status prüfen
pm2 status

# Logs ansehen
pm2 logs n8n-console

# Stoppen
pm2 stop n8n-console

# Neustarten
pm2 restart n8n-console
```

---

## 🔍 Troubleshooting

### Console ist nicht erreichbar

```bash
# Prüfe ob der Server läuft
pm2 status
# oder
curl http://localhost:3000/status

# Prüfe welcher Prozess Port 3000 nutzt
lsof -i :3000

# Server neu starten
pm2 restart n8n-console
```

### NPM kann Console nicht erreichen

1. Stelle sicher beide Server sind im gleichen Netzwerk
2. Prüfe die IP-Adresse: `192.168.12.168`
3. Prüfe ob Port 3000 vom Console-Server aus erreichbar ist
4. Firewall-Regel prüfen (falls vorhanden)

### SSE funktioniert nicht

1. "Websockets Support" in NPM aktivieren
2. Advanced Tab Konfiguration hinzufügen (siehe oben)
3. Browser Cache leeren
4. Console-Seite neu laden

---

## 📊 Nächste Schritte

1. ✅ Server läuft auf `192.168.12.168:3000`
2. ⏳ NPM konfigurieren (siehe Schritt 2 oben)
3. ⏳ Domain einrichten
4. ⏳ SSL-Zertifikat erstellen
5. ⏳ n8n Workflows anpassen
6. ⏳ PM2 einrichten für Auto-Start

---

## 💡 Tipps

- **Test von n8n aus:** `curl http://192.168.12.168:3000/test`
- **Logs ansehen:** `pm2 logs n8n-console --lines 100`
- **Status prüfen:** `curl http://192.168.12.168:3000/status`
- **Test-Nachrichten:** `./test-message.sh`

---

Viel Erfolg! 🎉
