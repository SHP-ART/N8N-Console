#!/bin/bash

# Test-Skript zum Senden von Daten an n8n, die dann an die Console weitergeleitet werden

N8N_WEBHOOK="http://192.168.12.85:5678/webhook-test/bbe5e339-573c-4917-8649-a27f29e6330d"

echo "╔═══════════════════════════════════════════════════════╗"
echo "║      N8N → Console Integration Test                   ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""
echo "Sende Test-Daten an n8n Webhook..."
echo "URL: $N8N_WEBHOOK"
echo ""

# Test 1: Einfache Nachricht
echo "Test 1: Einfache Nachricht"
curl -X POST "$N8N_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hallo von Test-Skript",
    "type": "test",
    "timestamp": "'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'"
  }'
echo -e "\n"

sleep 2

# Test 2: Benutzer-Registrierung
echo "Test 2: Benutzer-Registrierung simulieren"
curl -X POST "$N8N_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "user_registered",
    "user": {
      "name": "Max Mustermann",
      "email": "max@example.com",
      "id": "12345"
    }
  }'
echo -e "\n"

sleep 2

# Test 3: Fehler simulieren
echo "Test 3: Fehler simulieren"
curl -X POST "$N8N_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "error_occurred",
    "error": {
      "message": "Datenbank-Verbindung fehlgeschlagen",
      "code": "DB_CONNECTION_ERROR"
    }
  }'
echo -e "\n"

sleep 2

# Test 4: Erfolgreiche Transaktion
echo "Test 4: Erfolgreiche Transaktion"
curl -X POST "$N8N_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{
    "event": "payment_received",
    "transaction": {
      "amount": 99.99,
      "currency": "EUR",
      "customer": "Max Mustermann",
      "status": "success"
    }
  }'
echo -e "\n"

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║      Alle Tests abgeschlossen!                        ║"
echo "║      Prüfe die Console im Browser:                    ║"
echo "║      http://localhost:3000                            ║"
echo "╚═══════════════════════════════════════════════════════╝"
