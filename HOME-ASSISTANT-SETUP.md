# Home Assistant Integration für N8N Console

Diese Anleitung zeigt, wie du den AI Agent in n8n mit Home Assistant verbindest, sodass du dein Smart Home per Chat steuern kannst.

> **Wichtig:** Die Home Assistant Integration erfolgt **in n8n**, nicht in der Console selbst. Die Console benötigt keinen direkten Home Assistant Zugriff. Alle Befehle werden über n8n an Home Assistant weitergeleitet.

## 📋 Voraussetzungen

- n8n installiert und laufend
- Home Assistant installiert und erreichbar
- N8N Console läuft (siehe README.md)
- Home Assistant Long-Lived Access Token

## 🔑 Home Assistant Access Token erstellen

Falls du noch keinen Token hast:

1. Öffne Home Assistant: `http://DEINE_HA_IP:8123`
2. Klicke auf dein Profil (unten links)
3. Scrolle zu **"Long-Lived Access Tokens"**
4. Klicke auf **"Create Token"**
5. Gib einen Namen ein: z.B. "n8n AI Agent"
6. Kopiere den Token (wird nur einmal angezeigt!)

## 🤖 AI Agent System-Prompt

Öffne deinen **AI Agent Node** in n8n und füge folgenden **System Message** ein:

```
Du bist ein intelligenter Hausassistent mit direktem Zugriff auf Home Assistant. Deine Hauptaufgaben sind:

## Fähigkeiten:

1. **Home Assistant Steuerung:**
   - Smart-Home-Geräte steuern (Lichter, Schalter, Heizung, Jalousien, Mediaplayer, etc.)
   - Status von Geräten und Sensoren abfragen (Temperatur, Luftfeuchtigkeit, Bewegung, etc.)
   - Automatisierungen und Szenen auslösen
   - Zustand aller Räume und Geräte überwachen

2. **Allgemeine Assistenz:**
   - Fragen beantworten
   - Informationen über das Smart Home geben
   - Hilfreiche Vorschläge machen

## Wichtige Regeln:

- Antworte IMMER auf Deutsch
- Sei präzise und freundlich
- Bei kritischen Aktionen (z.B. "alle Lichter aus"), frage zuerst nach
- Gib klare Bestätigungen nach Aktionen
- Wenn du den Status nicht kennst, frage die verfügbaren Tools ab
- Erkläre was du tust, bevor du es ausführst

## Beispiele:

User: "Schalte das Licht im Wohnzimmer ein"
Du: Verwende homeassistant_steuern mit domain: light, service: turn_on, entity_id: light.wohnzimmer

User: "Wie warm ist es?"
Du: Verwende homeassistant_alle_geraete und suche nach Temperatursensoren

User: "Welche Lichter sind an?"
Du: Verwende homeassistant_alle_geraete und filtere nach domain: light mit state: on
```

## 🔧 Tools im AI Agent einrichten

### Tool 1: Alle Geräte abfragen

**Im AI Agent → Tools → Add Tool → HTTP Request**

#### Tool Details:
- **Name:** `homeassistant_alle_geraete`
- **Description:** `Ruft alle Geräte und deren Status aus Home Assistant ab. Zeigt alle verfügbaren Entities mit ihrem aktuellen Zustand, Attributen und letzter Änderung.`

#### HTTP Request Configuration:
- **Method:** `GET`
- **URL:** `http://DEINE_HA_IP:8123/api/states`

#### Headers:
Klicke auf **"Add Header"**:
- **Name:** `Authorization`
- **Value:** `Bearer DEIN_LONG_LIVED_ACCESS_TOKEN`

#### Optional - Response Format:
- **Response Format:** `JSON`

---

### Tool 2: Licht einschalten

**Add Tool → HTTP Request**

#### Tool Details:
- **Name:** `licht_einschalten`
- **Description:** `Schaltet ein Licht in Home Assistant ein. Benötigt die entity_id des Lichts (z.B. light.wohnzimmer).`

#### HTTP Request Configuration:
- **Method:** `POST`
- **URL:** `http://DEINE_HA_IP:8123/api/services/light/turn_on`

#### Headers:
- **Name:** `Authorization`
- **Value:** `Bearer DEIN_LONG_LIVED_ACCESS_TOKEN`
- **Name:** `Content-Type`
- **Value:** `application/json`

#### Body (Send Body: Yes, Content Type: JSON):
```json
{
  "entity_id": "={{ $fromAI('entity_id') }}"
}
```

#### Parameters:
Füge einen Parameter hinzu:
- **Name:** `entity_id`
- **Type:** `string`
- **Description:** `Die Entity-ID des Lichts (z.B. light.wohnzimmer)`
- **Required:** `Yes`

---

### Tool 3: Licht ausschalten

**Add Tool → HTTP Request**

#### Tool Details:
- **Name:** `licht_ausschalten`
- **Description:** `Schaltet ein Licht in Home Assistant aus. Benötigt die entity_id des Lichts.`

#### HTTP Request Configuration:
- **Method:** `POST`
- **URL:** `http://DEINE_HA_IP:8123/api/services/light/turn_off`

#### Headers:
- **Name:** `Authorization`
- **Value:** `Bearer DEIN_LONG_LIVED_ACCESS_TOKEN`
- **Name:** `Content-Type`
- **Value:** `application/json`

#### Body:
```json
{
  "entity_id": "={{ $fromAI('entity_id') }}"
}
```

#### Parameters:
- **Name:** `entity_id`
- **Type:** `string`
- **Description:** `Die Entity-ID des Lichts`
- **Required:** `Yes`

---

### Tool 4: Schalter umschalten

**Add Tool → HTTP Request**

#### Tool Details:
- **Name:** `schalter_toggle`
- **Description:** `Schaltet einen Schalter um (ein → aus, aus → ein). Benötigt die entity_id des Schalters.`

#### HTTP Request Configuration:
- **Method:** `POST`
- **URL:** `http://DEINE_HA_IP:8123/api/services/switch/toggle`

#### Headers:
- **Name:** `Authorization`
- **Value:** `Bearer DEIN_LONG_LIVED_ACCESS_TOKEN`
- **Name:** `Content-Type`
- **Value:** `application/json`

#### Body:
```json
{
  "entity_id": "={{ $fromAI('entity_id') }}"
}
```

#### Parameters:
- **Name:** `entity_id`
- **Type:** `string`
- **Description:** `Die Entity-ID des Schalters (z.B. switch.steckdose_wohnzimmer)`
- **Required:** `Yes`

---

### Tool 5: Szene aktivieren

**Add Tool → HTTP Request**

#### Tool Details:
- **Name:** `szene_aktivieren`
- **Description:** `Aktiviert eine Szene in Home Assistant. Benötigt die entity_id der Szene (z.B. scene.gemutlich).`

#### HTTP Request Configuration:
- **Method:** `POST`
- **URL:** `http://DEINE_HA_IP:8123/api/services/scene/turn_on`

#### Headers:
- **Name:** `Authorization`
- **Value:** `Bearer DEIN_LONG_LIVED_ACCESS_TOKEN`
- **Name:** `Content-Type`
- **Value:** `application/json`

#### Body:
```json
{
  "entity_id": "={{ $fromAI('entity_id') }}"
}
```

#### Parameters:
- **Name:** `entity_id`
- **Type:** `string`
- **Description:** `Die Entity-ID der Szene`
- **Required:** `Yes`

---

### Tool 6: Spezifisches Gerät abfragen

**Add Tool → HTTP Request**

#### Tool Details:
- **Name:** `geraet_status`
- **Description:** `Fragt den Status eines einzelnen Geräts ab. Benötigt die entity_id (z.B. sensor.temperatur_wohnzimmer).`

#### HTTP Request Configuration:
- **Method:** `GET`
- **URL:** `http://DEINE_HA_IP:8123/api/states/={{ $fromAI('entity_id') }}`

#### Headers:
- **Name:** `Authorization`
- **Value:** `Bearer DEIN_LONG_LIVED_ACCESS_TOKEN`

#### Parameters:
- **Name:** `entity_id`
- **Type:** `string`
- **Description:** `Die Entity-ID des Geräts`
- **Required:** `Yes`

---

## 🧪 Verbindung testen

Teste die Home Assistant API-Verbindung:

```bash
curl -X GET http://DEINE_HA_IP:8123/api/states \
  -H "Authorization: Bearer DEIN_TOKEN" \
  -H "Content-Type: application/json"
```

Erwartetes Ergebnis: JSON-Array mit allen Entities.

---

## 🎯 Workflow-Struktur in n8n

```
Webhook Trigger (empfängt von Console)
    ↓
AI Agent (mit Tools und System-Prompt)
    ↓
HTTP Request (sendet Antwort zurück zur Console)
```

### HTTP Request Node Konfiguration:

- **Method:** `POST`
- **URL:** `http://CONSOLE_IP:3000/webhook`
- **Body:**
  ```json
  {
    "type": "success",
    "message": "{{ $json.output }}"
  }
  ```

---

## 📝 Beispiel-Dialoge

### Geräte abfragen:
```
User: Welche Geräte sind verfügbar?
AI: [Verwendet homeassistant_alle_geraete Tool]
AI: Ich sehe folgende Geräte: Licht Wohnzimmer, Temperatur Sensor, ...
```

### Licht steuern:
```
User: Schalte das Licht im Wohnzimmer ein
AI: [Verwendet licht_einschalten mit entity_id: light.wohnzimmer]
AI: ✓ Das Licht im Wohnzimmer wurde eingeschaltet.
```

### Status abfragen:
```
User: Wie warm ist es im Schlafzimmer?
AI: [Verwendet homeassistant_alle_geraete, sucht nach Temperatur-Sensoren]
AI: Die Temperatur im Schlafzimmer beträgt 21.5°C.
```

---

## 🔐 Sicherheitshinweise

- **Speichere deinen Access Token NIEMALS in öffentlichen Repositories!**
- Verwende Umgebungsvariablen in n8n für sensible Daten
- Beschränke den Token auf notwendige Berechtigungen
- Verwende HTTPS in Produktionsumgebungen
- Aktiviere die n8n-Authentifizierung

---

## 🐛 Troubleshooting

### Problem: "401 Unauthorized"
- **Lösung:** Prüfe ob der Access Token korrekt ist
- Teste mit: `curl -H "Authorization: Bearer TOKEN" http://HA_IP:8123/api/`

### Problem: "Connection refused"
- **Lösung:** Prüfe ob Home Assistant erreichbar ist
- Teste mit: `curl http://HA_IP:8123/api/`

### Problem: AI Agent verwendet Tools nicht
- **Lösung:**
  - Prüfe ob Tool-Beschreibungen klar sind
  - Füge mehr Beispiele im System-Prompt hinzu
  - Teste mit expliziten Befehlen: "Verwende das Tool homeassistant_alle_geraete"

### Problem: Entity-ID nicht gefunden
- **Lösung:**
  - Liste alle Entities: `http://HA_IP:8123/api/states`
  - Prüfe die korrekte Schreibweise (z.B. `light.wohnzimmer` statt `light.Wohnzimmer`)

---

## 📚 Weiterführende Informationen

- [Home Assistant REST API Dokumentation](https://developers.home-assistant.io/docs/api/rest/)
- [n8n AI Agent Dokumentation](https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.agent/)
- [N8N Console README](./README.md)

---

## 🎉 Erweiterungsmöglichkeiten

### Weitere Tools hinzufügen:

- **Heizung steuern:** `climate.set_temperature`
- **Jalousien:** `cover.open_cover`, `cover.close_cover`
- **Mediaplayer:** `media_player.play_media`, `media_player.pause`
- **Benachrichtigungen:** `notify.notify`
- **Automatisierungen:** `automation.trigger`

### Kalender-Integration:

Füge Google Calendar, Nextcloud Calendar oder andere Kalender-Tools hinzu, damit der AI Agent auch Termine verwalten kann.

### Erweiterte Szenarien:

- **Sprachsteuerung:** Integriere mit Speech-to-Text
- **Zeitpläne:** Automatische Aktionen basierend auf Tageszeit
- **Präsenzerkennung:** Aktionen basierend auf Anwesenheit
- **Wetter-Integration:** Automatische Anpassungen basierend auf Wetter

---

## 💡 Best Practices

1. **Klare Entity-Namen:** Verwende sprechende Namen in Home Assistant (z.B. `light.wohnzimmer` statt `light.entity_1`)
2. **Gruppierung:** Nutze Home Assistant Areas/Räume für bessere Organisation
3. **Testen:** Teste jedes Tool einzeln bevor du den AI Agent verwendest
4. **Logging:** Aktiviere Logging in n8n für Debugging
5. **Backup:** Erstelle regelmäßig Backups deiner n8n Workflows

---

**Viel Erfolg mit deinem AI-gesteuerten Smart Home!** 🏠🤖
