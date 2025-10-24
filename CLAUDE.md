# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

N8N Console is a bidirectional chat interface for n8n workflows. It receives and displays real-time messages from n8n workflows AND allows users to send commands/messages back to n8n. Uses Server-Sent Events (SSE) for live updates.

**Tech Stack:**
- Frontend: Vanilla JavaScript, HTML5, CSS3
- Backend: Node.js with Express, node-fetch
- Real-time: Server-Sent Events (SSE)
- Message types: info, success, warning, error, system (each with distinct colors)

**Bidirectional Flow:**
- n8n → Console: Via POST /webhook endpoint
- Console → n8n: Via POST /send-to-n8n endpoint (user input)

## Commands

### Development
```bash
npm install              # Install dependencies
npm start               # Start production server on port 3000
npm run dev             # Start with nodemon (auto-reload)
PORT=8080 npm start     # Run on custom port
```

### Testing Endpoints
```bash
curl http://localhost:3000/status                    # Check server status
curl http://localhost:3000/test                      # Send test message to console
curl -X POST http://localhost:3000/message \        # Send custom message
  -H "Content-Type: application/json" \
  -d '{"type":"success","message":"Test"}'
```

### Production Deployment (PM2)
```bash
pm2 start server.js --name n8n-console
pm2 startup && pm2 save
pm2 logs n8n-console
pm2 restart n8n-console
```

## Architecture

### Server-Sent Events (SSE) Flow

The application maintains persistent SSE connections for real-time updates:

1. **Client Connection** (`/events` endpoint in server.js:25-52)
   - Clients connect via EventSource API (script.js:6-28)
   - Each client stored in `clients` array with unique ID
   - Connection opened with initial 'system' message
   - Auto-reconnect logic triggers every 5 seconds on disconnect

2. **Message Broadcasting** (server.js:112-121)
   - `broadcastMessage()` sends to all connected clients
   - Uses SSE format: `data: ${JSON.stringify(message)}\n\n`
   - Graceful error handling for disconnected clients

3. **Frontend Message Handling** (script.js:30-73)
   - Parses incoming messages and creates DOM elements
   - Applies type-specific CSS classes (info/success/warning/error)
   - Displays timestamp, message, and optional data payload
   - Auto-scroll maintains view at bottom when enabled

### API Endpoints

**POST /webhook** (server.js:55-72)
- Primary endpoint for n8n → Console messages
- Accepts: `{type, message, data}`
- Broadcasts to all connected clients via SSE
- Returns client count in response

**POST /message** (server.js:74-89)
- Simplified message endpoint
- Same structure as /webhook

**POST /send-to-n8n** (server.js:124-169)
- NEW: Sends messages from Console → n8n
- Accepts: `{type, message, source, timestamp, data}`
- Forwards to n8n webhook URL (configurable via N8N_WEBHOOK_URL env var)
- Default n8n URL: http://192.168.12.85:5678/webhook-test/bbe5e339-573c-4917-8649-a27f29e6330d
- Returns success/failure based on n8n response

**GET /test** (server.js:92-109)
- Sends test message with timestamp
- Useful for debugging SSE connection

**GET /status** (server.js:172-179)
- Returns server health: status, client count, uptime

### CORS Configuration

Server binds to `0.0.0.0` (server.js:139) and enables CORS (server.js:6-15) to allow:
- Network access from n8n server (192.168.12.85)
- Nginx Proxy Manager (NPM) reverse proxy support
- External webhook integrations

### Graceful Shutdown

SIGINT handler (server.js:161-171) closes all SSE connections before exit to prevent client-side errors.

## Message Structure

All messages should follow this format:
```json
{
  "type": "info|success|warning|error|system",
  "message": "Display message",
  "data": {}  // Optional: additional structured data
}
```

## N8N Integration Pattern

In n8n workflows, add an HTTP Request node:
- **Method:** POST
- **URL:** `http://192.168.12.168:3000/webhook` (or via NPM domain)
- **Body:** JSON with type, message, and data fields
- **Use n8n expressions:** `{{ $workflow.name }}`, `{{ $json }}`, `{{ $now }}`

Example for error handling workflows: Use separate nodes for success/error paths with appropriate message types.

## Frontend State Management

Global state in script.js:
- `messageCount`: Total messages received
- `autoScroll`: Boolean for auto-scroll behavior
- `eventSource`: SSE connection object

UI controls update status indicators in real-time (connection status, message count).

### Chat Commands (script.js:147-183)

Users can send commands from the input field:

**Local Commands** (processed client-side):
- `/help` - Display help menu with all commands
- `/clear` - Clear console output
- `/test` - Generate local test message
- `/status` - Fetch and display server status

**n8n Commands** (sent to n8n via /send-to-n8n):
- `/info [text]` - Send info message to n8n
- `/success [text]` - Send success message to n8n
- `/warning [text]` - Send warning message to n8n
- `/error [text]` - Send error message to n8n
- Any text without `/` prefix - Sent as info message to n8n

Commands starting with `/` are parsed in `handleLocalCommand()` (script.js:147-183).
Messages to n8n are sent via `sendToN8N()` (script.js:186-220) which calls POST /send-to-n8n.

## Deployment Notes

- Server runs on port 3000 by default (configurable via PORT env var)
- Binds to 0.0.0.0 for network accessibility
- **N8N_WEBHOOK_URL** environment variable: Configure target n8n webhook for user messages
  - Default: http://192.168.12.85:5678/webhook/bbe5e339-573c-4917-8649-a27f29e6330d
  - Set via: `N8N_WEBHOOK_URL=https://your-n8n.com/webhook/xyz npm start`
- For production with NPM reverse proxy, enable WebSocket support and add SSE-specific nginx config (see QUICK-START.md:62-71)
- PM2 recommended for process management and auto-restart

## n8n Webhook Setup for Receiving User Messages

To receive messages from the console in n8n:
1. Create a Webhook node in n8n (Production URL mode)
2. Set the N8N_WEBHOOK_URL environment variable to this webhook URL
3. In your n8n workflow, process incoming messages with structure:
   ```json
   {
     "type": "info|success|warning|error",
     "message": "User message text",
     "source": "console-user",
     "timestamp": "ISO timestamp"
   }
   ```
4. Optionally send responses back to the console via POST /webhook
