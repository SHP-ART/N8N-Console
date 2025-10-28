// Lade Umgebungsvariablen aus .env Datei
require('dotenv').config();

const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// CORS Middleware für externe Zugriffe
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    if (req.method === 'OPTIONS') {
        return res.sendStatus(200);
    }
    next();
});

// Middleware
app.use(express.json());
app.use(express.static(__dirname));

// SSE (Server-Sent Events) Verbindungen speichern
let clients = [];

// SSE Endpoint für Live-Updates
app.get('/events', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('Access-Control-Allow-Origin', '*');

    // Füge Client zur Liste hinzu
    const clientId = Date.now();
    const newClient = {
        id: clientId,
        res
    };
    clients.push(newClient);

    console.log(`Client ${clientId} verbunden. Aktive Clients: ${clients.length}`);

    // Keine initiale Nachricht mehr - nur Status-Anzeige im Footer

    // Entferne Client bei Verbindungsabbruch
    req.on('close', () => {
        clients = clients.filter(client => client.id !== clientId);
        console.log(`Client ${clientId} getrennt. Aktive Clients: ${clients.length}`);
    });
});

// Webhook Endpoint für n8n
app.post('/webhook', (req, res) => {
    console.log('Webhook empfangen:', req.body);

    const message = {
        type: req.body.type || 'info',
        message: req.body.message || 'Nachricht von n8n',
        data: req.body.data  // Kein Fallback mehr auf req.body!
    };

    // Sende Nachricht an alle verbundenen Clients
    broadcastMessage(message);

    res.json({
        success: true,
        message: 'Nachricht empfangen und versendet',
        clients: clients.length
    });
});

// POST Endpoint für einfache Nachrichten
app.post('/message', (req, res) => {
    const message = {
        type: req.body.type || 'info',
        message: req.body.message || 'Keine Nachricht',
        data: req.body.data  // Konsistent: Kein Fallback
    };

    broadcastMessage(message);

    res.json({
        success: true,
        message: 'Nachricht versendet',
        clients: clients.length
    });
});

// GET Endpoint für Test-Nachrichten
app.get('/test', (req, res) => {
    const testMessage = {
        type: 'success',
        message: 'Test-Nachricht vom Server',
        data: {
            timestamp: new Date().toISOString(),
            source: 'GET /test'
        }
    };

    broadcastMessage(testMessage);

    res.json({
        success: true,
        message: 'Test-Nachricht versendet',
        clients: clients.length
    });
});

// Funktion zum Versenden von Nachrichten an alle Clients
function broadcastMessage(message) {
    clients.forEach(client => {
        try {
            client.res.write(`data: ${JSON.stringify(message)}\n\n`);
        } catch (error) {
            console.error('Fehler beim Senden an Client:', error);
        }
    });
    console.log(`Nachricht an ${clients.length} Clients gesendet:`, message.message);
}

// Endpoint für Nachrichten VON der Console AN n8n
app.post('/send-to-n8n', async (req, res) => {
    // n8n Chat-Trigger Format: chatInput ist erforderlich
    const message = {
        chatInput: req.body.message || 'Keine Nachricht',
        type: req.body.type || 'info',
        source: req.body.source || 'console',
        timestamp: req.body.timestamp || new Date().toISOString(),
        sessionId: 'console-session-' + Date.now(),
        data: req.body.data
    };

    console.log('Nachricht von Console-User an n8n:', message);

    // Hier kannst du die n8n Webhook URL konfigurieren
    const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL || 'http://192.168.12.190:5678/webhook/bbe5e339-573c-4917-8649-a27f29e6330d';

    try {
        console.log('Sende an n8n URL:', N8N_WEBHOOK_URL);

        // Sende an n8n Webhook
        const fetch = (await import('node-fetch')).default;
        const response = await fetch(N8N_WEBHOOK_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(message)
        });

        console.log('n8n Response Status:', response.status);
        const responseText = await response.text();
        console.log('n8n Response Body:', responseText);

        if (response.ok) {
            console.log('✓ Erfolgreich an n8n gesendet!');
            res.json({
                success: true,
                message: 'Nachricht an n8n gesendet',
                n8nResponse: response.status
            });
        } else {
            console.error('✗ n8n Webhook Fehler:', response.status);
            res.status(500).json({
                success: false,
                message: 'n8n Webhook Fehler',
                status: response.status
            });
        }
    } catch (error) {
        console.error('✗ Fehler beim Senden an n8n:', error.message);
        console.error('Stack:', error.stack);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
});

// Status Endpoint
app.get('/status', (req, res) => {
    res.json({
        status: 'online',
        clients: clients.length,
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

// Root Endpoint
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Server starten - Binde an 0.0.0.0 für externe Zugriffe
app.listen(PORT, '0.0.0.0', () => {
    console.log(`
╔═══════════════════════════════════════════════════════╗
║         N8N Console Server gestartet!                 ║
╠═══════════════════════════════════════════════════════╣
║                                                       ║
║  🌐 Lokal:      http://localhost:${PORT}                ║
║  🌍 Netzwerk:   http://0.0.0.0:${PORT}                  ║
║                                                       ║
║  📡 Webhook:    POST /webhook                         ║
║  💬 Message:    POST /message                         ║
║  🧪 Test:       GET  /test                            ║
║  📊 Status:     GET  /status                          ║
║                                                       ║
║  🔗 NPM Ready:  Reverse Proxy kann konfiguriert       ║
║                 werden auf Port ${PORT}                  ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
    `);
});

// Graceful Shutdown
process.on('SIGINT', () => {
    console.log('\nServer wird heruntergefahren...');
    clients.forEach(client => {
        try {
            client.res.end();
        } catch (error) {
            // Ignoriere Fehler beim Schließen
        }
    });
    process.exit(0);
});
