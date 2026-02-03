# Cargo Escape MCP Server - Development Guide

> 🚀 **Personal Model Context Protocol server for the Cargo Escape Godot project**

This guide explains how to use, develop with, and extend the MCP server for your Cargo Escape game development.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Using the MCP Server](#using-the-mcp-server)
4. [Available Tools](#available-tools)
5. [Authentication](#authentication)
6. [API Reference](#api-reference)
7. [Adding New Tools](#adding-new-tools)
8. [Troubleshooting](#troubleshooting)
9. [Security Notes](#security-notes)

---

## Quick Start

### Starting the Server

```powershell
# Navigate to the MCP server directory
cd .mcp-server

# Start with Godot support (recommended)
docker-compose -f docker-compose.godot.yml up -d

# Or start without Godot (lighter image)
docker-compose up -d
```

### Verify It's Running

```powershell
# Check container status
docker ps

# View logs
docker logs cargo-escape-mcp-godot

# Test health endpoint
Invoke-WebRequest -Uri "http://localhost:3100/health" -UseBasicParsing
```

### Access the Dashboard

Open [http://localhost:3100](http://localhost:3100) in your browser for the interactive dashboard.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     VS Code                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              GitHub Copilot                          │   │
│  │    Uses MCP tools via .vscode/mcp.json config        │   │
│  └─────────────────────┬───────────────────────────────┘   │
│                        │ stdio transport                    │
│  ┌─────────────────────▼───────────────────────────────┐   │
│  │           MCP Server (index.js)                      │   │
│  │        Runs directly in VS Code                      │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   Docker Container                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         MCP HTTP Server (http-server.js)             │   │
│  │    - SSE transport for external clients              │   │
│  │    - REST API for tools                              │   │
│  │    - Dashboard UI                                    │   │
│  │    - Godot 4.6 headless (optional)                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                        ↓ localhost:3100                     │
└─────────────────────────────────────────────────────────────┘
```

### Two Transport Modes

| Mode | File | Use Case |
|------|------|----------|
| **stdio** | `index.js` | VS Code integration (Copilot) |
| **HTTP/SSE** | `http-server.js` | Docker, dashboard, external tools |

---

## Using the MCP Server

### With VS Code / GitHub Copilot

The MCP server is automatically available to Copilot via the `.vscode/mcp.json` configuration:

```json
{
  "servers": {
    "cargo-escape": {
      "command": "node",
      "args": ["${workspaceFolder}/.mcp-server/src/index.js"],
      "env": {
        "WORKSPACE_PATH": "${workspaceFolder}"
      }
    }
  }
}
```

**Ask Copilot things like:**
- "Use the MCP tools to analyze my GDScript dependencies"
- "Run the project stats tool and show me the results"
- "Find all TODO comments in the project"
- "List all scene files in the project"

### With the REST API

```powershell
# Set your API key
$apiKey = "CargoEscapeBigProject"  # Change if you customized it
$headers = @{ "Authorization" = "Bearer $apiKey" }

# Get project statistics
Invoke-WebRequest -Uri "http://localhost:3100/api/stats" -Headers $headers -UseBasicParsing

# Execute a tool
$body = @{
    tool = "project_stats"
    arguments = @{}
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:3100/api/execute" -Method POST -Headers $headers -Body $body -ContentType "application/json" -UseBasicParsing
```

### With the Dashboard

The web dashboard at [http://localhost:3100](http://localhost:3100) provides:

- 📊 Real-time project statistics
- 🔧 Interactive tool execution
- 📚 Learning resources for Godot & MCP
- 🎮 Space-themed UI matching Cargo Escape aesthetics

---

## Available Tools

### Project Analysis

| Tool | Description |
|------|-------------|
| `project_stats` | Get file counts, lines of code, averages |
| `find_todos` | Find TODO, FIXME, HACK comments |
| `godot_find_node_references` | Find node types/signals in scripts |

### Script Management

| Tool | Description |
|------|-------------|
| `list_scripts` | List all .gd script files |
| `godot_analyze_dependencies` | Analyze preload/load statements |

### Scene Management

| Tool | Description |
|------|-------------|
| `list_scenes` | List all .tscn scene files |

### File Operations

| Tool | Description |
|------|-------------|
| `read_script` | Read a specific .gd file |
| `search_scripts` | Search for patterns in scripts |

### Godot Integration (Godot build only)

| Tool | Description |
|------|-------------|
| `godot_version` | Get Godot version info |
| `godot_validate_project` | Validate project.godot |
| `godot_run_tests` | Run GDScript tests |

---

## Authentication

### API Key

The server uses API key authentication for protected endpoints.

**Default Key:** `CargoEscapeBigProject` (set in docker-compose.godot.yml)

**To change it:**

1. Edit `.mcp-server/docker-compose.godot.yml`:
   ```yaml
   environment:
     - MCP_API_KEY=your-super-secret-key-here
   ```

2. Restart the container:
   ```powershell
   docker-compose -f docker-compose.godot.yml down
   docker-compose -f docker-compose.godot.yml up -d
   ```

### Using the API Key

```powershell
# Method 1: Authorization header (recommended)
$headers = @{ "Authorization" = "Bearer your-api-key" }
Invoke-WebRequest -Uri "http://localhost:3100/api/stats" -Headers $headers

# Method 2: X-API-Key header
$headers = @{ "X-API-Key" = "your-api-key" }
Invoke-WebRequest -Uri "http://localhost:3100/api/stats" -Headers $headers

# Method 3: Query parameter (for quick testing only)
Invoke-WebRequest -Uri "http://localhost:3100/api/stats?api_key=your-api-key"
```

### Public vs Protected Endpoints

| Endpoint | Auth Required | Description |
|----------|---------------|-------------|
| `/` | ❌ No | Dashboard |
| `/health` | ❌ No | Health check |
| `/api/tools` | ❌ No | List available tools |
| `/api/execute` | ✅ Yes | Execute tools |
| `/api/stats` | ✅ Yes | Project statistics |
| `/sse` | ✅ Yes | SSE connection |
| `/message` | ✅ Yes | MCP messages |

---

## API Reference

### GET /health

Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "server": "Cargo Escape MCP",
  "tools": 12,
  "security": {
    "authEnabled": true,
    "rateLimit": 60
  }
}
```

### GET /api/tools

List all available tools.

**Response:**
```json
{
  "tools": [
    {
      "name": "project_stats",
      "description": "Get statistics about the Cargo Escape project"
    },
    ...
  ]
}
```

### POST /api/execute

Execute a tool.

**Request:**
```json
{
  "tool": "project_stats",
  "arguments": {}
}
```

**Response:**
```json
{
  "result": {
    "scripts": { "count": 105, "totalLines": 36206 },
    "scenes": { "count": 45 },
    "resources": { "count": 21 },
    "averageLinesPerScript": 345
  }
}
```

### GET /api/stats

Quick project statistics (shortcut for project_stats tool).

---

## Adding New Tools

### Step 1: Define the Tool Schema

In `http-server.js` (or `index.js` for stdio), add to the `ListToolsRequestSchema` handler:

```javascript
{
  name: 'my_new_tool',
  description: 'Description of what this tool does',
  inputSchema: {
    type: 'object',
    properties: {
      param1: {
        type: 'string',
        description: 'First parameter'
      },
      param2: {
        type: 'number',
        description: 'Second parameter'
      }
    },
    required: ['param1']
  }
}
```

### Step 2: Implement the Tool Logic

In the `CallToolRequestSchema` handler, add a case:

```javascript
case 'my_new_tool': {
  const { param1, param2 = 10 } = args;
  
  // Your implementation here
  const result = await doSomething(param1, param2);
  
  return {
    content: [
      {
        type: 'text',
        text: JSON.stringify(result, null, 2)
      }
    ]
  };
}
```

### Step 3: Rebuild and Test

```powershell
# Rebuild container
docker-compose -f docker-compose.godot.yml build --no-cache

# Restart
docker-compose -f docker-compose.godot.yml up -d

# Test your new tool
$body = @{ tool = "my_new_tool"; arguments = @{ param1 = "test" } } | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:3100/api/execute" -Method POST -Headers $headers -Body $body -ContentType "application/json"
```

---

## Troubleshooting

### Container Won't Start

```powershell
# Check logs
docker logs cargo-escape-mcp-godot

# Check if port is in use
netstat -an | findstr 3100

# Force rebuild
docker-compose -f docker-compose.godot.yml down
docker-compose -f docker-compose.godot.yml build --no-cache
docker-compose -f docker-compose.godot.yml up -d
```

### 401 Unauthorized

Make sure you're using the correct API key:

```powershell
# Check current API key in docker-compose
cat docker-compose.godot.yml | Select-String "MCP_API_KEY"
```

### Tool Not Found

```powershell
# List available tools
Invoke-WebRequest -Uri "http://localhost:3100/api/tools" -UseBasicParsing | Select-Object -ExpandProperty Content
```

### Godot Commands Fail

```powershell
# Check Godot is installed in container
docker exec cargo-escape-mcp-godot godot --version

# Check workspace is mounted
docker exec cargo-escape-mcp-godot ls -la /workspace
```

### VS Code MCP Not Working

1. Ensure the MCP extension is enabled
2. Check `.vscode/mcp.json` configuration
3. Reload VS Code window: `Ctrl+Shift+P` → "Reload Window"
4. Check Output panel for MCP errors

---

## Security Notes

### What's Protected

| Protection | Status |
|------------|--------|
| Localhost-only binding | ✅ `127.0.0.1:3100` |
| API key authentication | ✅ Required for sensitive endpoints |
| Rate limiting | ✅ 60/min for non-localhost (you're exempt!) |
| CORS restrictions | ✅ Only localhost origins |
| Path traversal protection | ✅ Can't escape workspace |

### Rate Limiting

- **Localhost requests are EXEMPT** from rate limiting
- Non-localhost requests: 60 requests/minute
- This protects against abuse while not limiting your productivity

### Changing Security Settings

Edit `.mcp-server/docker-compose.godot.yml`:

```yaml
environment:
  # Custom API key
  - MCP_API_KEY=my-super-secret-key
  
  # Custom allowed origins
  - ALLOWED_ORIGINS=http://localhost:3100,http://127.0.0.1:3100
  
  # Adjust rate limit for non-localhost
  - RATE_LIMIT=100
```

---

## Development Workflow Tips

### 1. Keep the Server Running

Start the Docker container once and leave it running:

```powershell
docker-compose -f docker-compose.godot.yml up -d
```

### 2. Use the Dashboard for Quick Checks

Bookmark [http://localhost:3100](http://localhost:3100) for instant access to:
- Project statistics
- Tool testing
- Learning resources

### 3. Leverage Copilot Integration

Ask Copilot to use MCP tools directly:
- "Analyze the dependencies in player.gd using MCP"
- "Show me all TODO comments in the project"
- "Get project statistics"

### 4. Rebuild Only When Needed

Only rebuild the container when you change:
- `http-server.js` or `index.js`
- `dashboard.js`
- `Dockerfile.godot`
- `package.json`

```powershell
docker-compose -f docker-compose.godot.yml build --no-cache
docker-compose -f docker-compose.godot.yml up -d
```

### 5. Check Logs for Issues

```powershell
# Follow logs in real-time
docker logs -f cargo-escape-mcp-godot

# Last 50 lines
docker logs --tail 50 cargo-escape-mcp-godot
```

---

## File Structure

```
.mcp-server/
├── src/
│   ├── index.js          # stdio transport (VS Code)
│   ├── http-server.js    # HTTP/SSE transport (Docker)
│   └── dashboard.js      # Web dashboard HTML
├── docker-compose.yml       # Lightweight build
├── docker-compose.godot.yml # Full build with Godot
├── Dockerfile              # Base image
├── Dockerfile.godot        # Image with Godot 4.6
├── package.json            # Dependencies
└── DEVELOPMENT.md          # This file
```

---

## Version Info

- **MCP SDK:** 1.0.0
- **Node.js:** 20.x
- **Godot:** 4.6 (headless, Linux)
- **Transport:** stdio + HTTP/SSE

---

*Happy coding, space captain! 🚀*
