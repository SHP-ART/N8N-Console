let messageCount = 0;
let autoScroll = true;
let eventSource = null;

// Initialisiere die Verbindung zum Server
function initConnection() {
    // Server-Sent Events für Live-Updates
    eventSource = new EventSource('/events');

    eventSource.onopen = function() {
        updateConnectionStatus(true);
    };

    eventSource.onerror = function() {
        updateConnectionStatus(false);
        // Versuche Reconnect nach 5 Sekunden
        setTimeout(initConnection, 5000);
    };

    eventSource.onmessage = function(event) {
        try {
            const data = JSON.parse(event.data);
            addConsoleMessage(data);
        } catch (e) {
            console.error('Fehler beim Parsen der Nachricht:', e);
        }
    };
}

// Füge eine neue Nachricht zur Console hinzu
function addConsoleMessage(data) {
    const consoleBody = document.getElementById('console');
    const line = document.createElement('div');

    // Bestimme den Nachrichtentyp
    const type = data.type || 'info';
    line.className = `console-line ${type}`;

    // Erstelle Timestamp
    const timestamp = new Date().toLocaleTimeString('de-DE');
    const timestampSpan = document.createElement('span');
    timestampSpan.className = 'timestamp';
    timestampSpan.textContent = `[${timestamp}]`;

    // Erstelle Message
    const messageSpan = document.createElement('span');
    messageSpan.className = 'message';
    messageSpan.textContent = data.message || 'Keine Nachricht';

    line.appendChild(timestampSpan);
    line.appendChild(messageSpan);

    // Füge zusätzliche Daten hinzu, falls vorhanden und nicht redundant
    if (data.data && typeof data.data === 'object') {
        // Zeige nur Daten an, wenn sie mehr enthalten als nur "response" und "timestamp"
        const keys = Object.keys(data.data);
        const hasExtraData = keys.some(key => key !== 'response' && key !== 'timestamp');

        if (hasExtraData) {
            const dataDiv = document.createElement('div');
            dataDiv.className = 'message-data';
            dataDiv.textContent = JSON.stringify(data.data, null, 2);
            line.appendChild(dataDiv);
        }
    } else if (data.data && typeof data.data === 'string') {
        // Zeige String-Daten nur an, wenn sie sich von der Nachricht unterscheiden
        if (data.data !== data.message) {
            const dataDiv = document.createElement('div');
            dataDiv.className = 'message-data';
            dataDiv.textContent = data.data;
            line.appendChild(dataDiv);
        }
    }

    consoleBody.appendChild(line);

    // Update Message Count
    messageCount++;
    document.getElementById('message-count').textContent = messageCount;

    // Auto-scroll wenn aktiviert
    if (autoScroll) {
        consoleBody.scrollTop = consoleBody.scrollHeight;
    }
}

// Lösche alle Console-Nachrichten
function clearConsole() {
    const consoleBody = document.getElementById('console');
    consoleBody.innerHTML = '<div class="console-line system"><span class="timestamp">[System]</span><span class="message">Console geleert.</span></div>';
    messageCount = 0;
    document.getElementById('message-count').textContent = messageCount;
}

// Toggle Auto-Scroll
function toggleAutoScroll() {
    autoScroll = !autoScroll;
    document.getElementById('autoscroll-status').textContent = autoScroll ? 'ON' : 'OFF';
}

// Update Connection Status
function updateConnectionStatus(connected) {
    const statusElement = document.getElementById('connection-status');
    if (connected) {
        statusElement.textContent = 'Verbunden';
        statusElement.className = 'status-connected';
    } else {
        statusElement.textContent = 'Getrennt';
        statusElement.className = 'status-disconnected';
    }
}

// Test-Funktion zum Hinzufügen von Demo-Nachrichten
function addTestMessage() {
    const types = ['info', 'success', 'warning', 'error'];
    const messages = [
        'Workflow gestartet',
        'Daten erfolgreich verarbeitet',
        'Achtung: Langsame Antwortzeit',
        'Fehler beim Verbinden zur API'
    ];

    const randomType = types[Math.floor(Math.random() * types.length)];
    const randomMessage = messages[Math.floor(Math.random() * messages.length)];

    addConsoleMessage({
        type: randomType,
        message: randomMessage,
        data: { workflow: 'Test', id: Math.random().toString(36).substr(2, 9) }
    });
}

// Sende Befehl an Server
function sendCommand() {
    const input = document.getElementById('command-input');
    const command = input.value.trim();

    if (!command) return;

    // Zeige Befehl in Console an
    addConsoleMessage({
        type: 'system',
        message: `> ${command}`
    });

    // Verarbeite Befehle
    if (command.startsWith('/')) {
        handleLocalCommand(command);
    } else {
        // Sende normalen Text an n8n
        sendToN8N(command, 'info');
    }

    // Leere Input-Feld
    input.value = '';
}

// Verarbeite lokale Befehle (starten mit /)
function handleLocalCommand(command) {
    const parts = command.split(' ');
    const cmd = parts[0].toLowerCase();
    const args = parts.slice(1).join(' ');

    switch(cmd) {
        case '/help':
            showHelp();
            break;
        case '/clear':
            clearConsole();
            break;
        case '/test':
            addTestMessage();
            break;
        case '/status':
            checkStatus();
            break;
        case '/info':
            sendToN8N(args || 'Info-Nachricht', 'info');
            break;
        case '/success':
            sendToN8N(args || 'Erfolgs-Nachricht', 'success');
            break;
        case '/warning':
            sendToN8N(args || 'Warnung', 'warning');
            break;
        case '/error':
            sendToN8N(args || 'Fehler-Nachricht', 'error');
            break;
        default:
            addConsoleMessage({
                type: 'error',
                message: `Unbekannter Befehl: ${cmd}. Verwende /help für Hilfe.`
            });
    }
}

// Sende Nachricht an n8n
async function sendToN8N(message, type = 'info') {
    try {
        const response = await fetch('/send-to-n8n', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                type: type,
                message: message,
                source: 'console-user',
                timestamp: new Date().toISOString()
            })
        });

        const result = await response.json();

        if (!result.success) {
            addConsoleMessage({
                type: 'error',
                message: `✗ Fehler beim Senden: ${result.message || 'Unbekannter Fehler'}`
            });
        }
        // Bei Erfolg keine Nachricht anzeigen - n8n wird antworten
    } catch (error) {
        addConsoleMessage({
            type: 'error',
            message: `✗ Verbindungsfehler: ${error.message}`
        });
    }
}

// Zeige Hilfe an
function showHelp() {
    const helpText = `
=== N8N Console Chat - Befehle ===

Lokale Befehle:
  /help              - Zeige diese Hilfe
  /clear             - Console leeren
  /test              - Test-Nachricht generieren
  /status            - Server-Status prüfen

Nachrichten an n8n senden:
  /info [text]       - Info-Nachricht senden
  /success [text]    - Erfolgs-Nachricht senden
  /warning [text]    - Warnung senden
  /error [text]      - Fehler-Nachricht senden

  [beliebiger text]  - Als Info-Nachricht senden

Tastenkombinationen:
  Enter              - Befehl senden
  Strg+T             - Test-Nachricht

Beispiele:
  /info Server gestartet
  /success Daten verarbeitet
  Hallo n8n!
    `;

    addConsoleMessage({
        type: 'system',
        message: helpText.trim()
    });
}

// Status prüfen
async function checkStatus() {
    try {
        const response = await fetch('/status');
        const status = await response.json();

        addConsoleMessage({
            type: 'info',
            message: `Server Status: ${status.status}`,
            data: {
                'Verbundene Clients': status.clients,
                'Uptime': Math.floor(status.uptime) + 's',
                'Timestamp': new Date(status.timestamp).toLocaleString('de-DE')
            }
        });
    } catch (error) {
        addConsoleMessage({
            type: 'error',
            message: `Fehler beim Status-Abruf: ${error.message}`
        });
    }
}

// Initialisiere beim Laden der Seite
document.addEventListener('DOMContentLoaded', function() {
    initConnection();

    const input = document.getElementById('command-input');

    // Enter-Taste zum Senden
    input.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            sendCommand();
        }
    });

    // Tastenkombination für Test-Nachricht (Strg+T)
    document.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.key === 't') {
            e.preventDefault();
            addTestMessage();
        }
    });

    // Focus auf Input beim Laden
    input.focus();
});
