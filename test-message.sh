#!/bin/bash

# Test-Skript zum Senden verschiedener Nachrichten an die Console

echo "Sende verschiedene Test-Nachrichten..."
echo ""

# Info Nachricht
echo "1. Info Nachricht..."
curl -X POST http://localhost:3000/message \
  -H "Content-Type: application/json" \
  -d '{"type":"info","message":"Dies ist eine Info-Nachricht"}'
echo ""

# Success Nachricht
echo "2. Success Nachricht..."
curl -X POST http://localhost:3000/message \
  -H "Content-Type: application/json" \
  -d '{"type":"success","message":"Workflow erfolgreich abgeschlossen!"}'
echo ""

# Warning Nachricht
echo "3. Warning Nachricht..."
curl -X POST http://localhost:3000/message \
  -H "Content-Type: application/json" \
  -d '{"type":"warning","message":"Achtung: Langsame API-Antwort"}'
echo ""

# Error Nachricht
echo "4. Error Nachricht..."
curl -X POST http://localhost:3000/message \
  -H "Content-Type: application/json" \
  -d '{"type":"error","message":"Fehler beim Verbinden zur Datenbank"}'
echo ""

# Nachricht mit Daten
echo "5. Nachricht mit zusätzlichen Daten..."
curl -X POST http://localhost:3000/webhook \
  -H "Content-Type: application/json" \
  -d '{"type":"success","message":"Neuer Benutzer registriert","data":{"name":"Max Mustermann","email":"max@example.com","id":"12345"}}'
echo ""

echo ""
echo "Alle Test-Nachrichten wurden gesendet!"
