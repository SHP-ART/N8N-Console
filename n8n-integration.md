# N8N Integration Anleitung

## Dein n8n Webhook
**URL:** `http://192.168.12.85:5678/webhook-test/bbe5e339-573c-4917-8649-a27f29e6330d`

## Console Server
**URL:** `http://localhost:3000/webhook`

---

## Setup in n8n

### Methode 1: Nachrichten von n8n an Console senden

Füge in deinem n8n Workflow einen **HTTP Request Node** hinzu:

#### Konfiguration:
- **Method:** POST
- **URL:** `http://localhost:3000/webhook`
- **Authentication:** None
- **Send Body:** Yes
- **Body Content Type:** JSON
- **Specify Body:** Using JSON

#### Body Beispiel:
```json
{
  "type": "success",
  "message": "Workflow {{ $workflow.name }} erfolgreich ausgeführt",
  "data": {
    "workflowId": "{{ $workflow.id }}",
    "executionId": "{{ $execution.id }}",
    "timestamp": "{{ $now }}"
  }
}
```

### Methode 2: Console von extern erreichbar machen

Wenn n8n auf einem anderen Server läuft (192.168.12.85), musst du die Console auch im Netzwerk erreichbar machen.

#### Option A: Server mit 0.0.0.0 binden

Ändere in `server.js`:
```javascript
app.listen(PORT, '0.0.0.0', () => {
  // ...
});
```

Dann wäre die URL: `http://[DEINE-IP]:3000/webhook`

#### Option B: ngrok verwenden (für externe Erreichbarkeit)
```bash
npm install -g ngrok
ngrok http 3000
```

Dann nutze die ngrok URL in n8n.

---

## Beispiel n8n Workflows

### 1. Einfacher Workflow mit Console-Ausgabe

```
[Trigger] → [Datenverarbeitung] → [HTTP Request zu Console]
```

**HTTP Request Body:**
```json
{
  "type": "info",
  "message": "Neues Event empfangen",
  "data": {{ $json }}
}
```

### 2. Workflow mit Fehlerbehandlung

```
[Trigger] → [Verarbeitung] → [Console Success]
              ↓ (bei Fehler)
           [Console Error]
```

**Success Body:**
```json
{
  "type": "success",
  "message": "Daten erfolgreich verarbeitet",
  "data": {
    "count": {{ $json.length }},
    "status": "completed"
  }
}
```

**Error Body:**
```json
{
  "type": "error",
  "message": "Fehler in Workflow: {{ $json.error.message }}",
  "data": {
    "node": "{{ $json.node.name }}",
    "error": "{{ $json.error }}"
  }
}
```

### 3. Webhook von n8n testen

Du kannst auch Daten VON n8n EMPfangen und an die Console weiterleiten.

Erstelle einen n8n Workflow:
1. **Webhook Trigger** (bereits vorhanden)
2. **HTTP Request Node** zur Console

Dann sende Daten an n8n:
```bash
curl -X POST http://192.168.12.85:5678/webhook-test/bbe5e339-573c-4917-8649-a27f29e6330d \
  -H "Content-Type: application/json" \
  -d '{"message":"Test von außen"}'
```

n8n leitet diese dann an die Console weiter.

---

## Nachrichtentypen

| Type | Farbe | Verwendung |
|------|-------|------------|
| `info` | Blau | Allgemeine Informationen |
| `success` | Grün | Erfolgreiche Operationen |
| `warning` | Orange | Warnungen |
| `error` | Rot | Fehler |
| `system` | Grau | System-Nachrichten |

---

## Vollständiges n8n Workflow-Beispiel (JSON Export)

Importiere diesen Workflow in n8n:

```json
{
  "nodes": [
    {
      "parameters": {},
      "name": "Start",
      "type": "n8n-nodes-base.start",
      "typeVersion": 1,
      "position": [250, 300]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://localhost:3000/webhook",
        "options": {},
        "bodyParametersJson": "{\n  \"type\": \"success\",\n  \"message\": \"Test-Nachricht von n8n\",\n  \"data\": {\n    \"workflow\": \"Test Workflow\",\n    \"timestamp\": \"{{ $now }}\"\n  }\n}"
      },
      "name": "Sende an Console",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 3,
      "position": [450, 300]
    }
  ],
  "connections": {
    "Start": {
      "main": [
        [
          {
            "node": "Sende an Console",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  }
}
```

---

## Tipps

1. **Dynamische Nachrichten:** Nutze n8n Expressions wie `{{ $json.field }}` für dynamische Inhalte
2. **Bedingte Typen:** Verwende IF-Nodes um verschiedene Nachrichtentypen zu senden
3. **Batch-Processing:** Sende mehrere Nachrichten in einer Schleife
4. **Logging:** Nutze die Console als zentrales Logging-Dashboard für alle n8n Workflows

---

## Fehlerbehebung

### Console empfängt keine Nachrichten
1. Prüfe ob der Server läuft: `curl http://localhost:3000/status`
2. Teste mit: `curl http://localhost:3000/test`
3. Prüfe die Browser-Console auf Fehler

### n8n kann Console nicht erreichen
1. Stelle sicher, dass beide im gleichen Netzwerk sind
2. Prüfe Firewall-Einstellungen
3. Verwende die korrekte IP-Adresse statt localhost

### Nachrichten erscheinen nicht in Echtzeit
1. Öffne die Console im Browser neu
2. Prüfe ob die SSE-Verbindung aktiv ist (Status: Verbunden)
3. Prüfe die Browser-Kompatibilität
