# MCP Project Hub

> 🚀 **Ultimate MCP Server for Godot Game Development**

A comprehensive Model Context Protocol server with plugin architecture, MCP resources/prompts support, Git integration, and a beautiful project hub dashboard.

## Features

- **🔌 Plugin Architecture** - Modular, extensible tool system
- **📦 MCP Resources** - Structured data for LLM context
- **💬 MCP Prompts** - Pre-built prompt templates
- **🎮 30+ Godot Tools** - Scene analysis, linting, docs generation
- **📋 Git Integration** - Status, branches, commits, blame
- **📊 Metrics & Caching** - Performance monitoring, result caching
- **🎨 Project Hub Dashboard** - Beautiful web UI with tool execution

## Quick Start

```powershell
cd .mcp-server
docker-compose -f docker-compose.godot.yml up -d --build
```

Open http://localhost:3100 to access the dashboard.

## Documentation

See [DEVELOPMENT.md](DEVELOPMENT.md) for complete documentation including:

- Architecture overview
- All available tools
- MCP resources and prompts
- API reference
- Plugin development
- Configuration options
- Troubleshooting

## Tools Overview

### Godot Tools
- `godot_scene_graph` - Analyze scene hierarchy
- `godot_asset_usage` - Find unused assets
- `godot_lint` - GDScript style checker
- `godot_performance_hints` - Find anti-patterns
- `godot_generate_docs` - Generate documentation
- And many more...

### Git Tools
- `git_status` - Repository status
- `git_log` - Commit history
- `git_diff` - View changes
- `git_blame` - File blame
- And more...

## Security

- ✅ Localhost-only binding
- ✅ API key authentication
- ✅ Rate limiting
- ✅ Non-root container
- ✅ Path traversal protection

## License

MIT - Built for personal game development.
