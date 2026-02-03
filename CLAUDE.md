# Claude Instructions for Cargo Escape

This file provides context and instructions for Claude when working on the Cargo Escape project.

---

## Project Overview

**Cargo Escape** is a 2D space game built with **Godot 4.x** using **GDScript**. The game features space combat, boarding mechanics, loot systems, and faction-based gameplay.

### Tech Stack
- **Engine:** Godot 4.x
- **Language:** GDScript
- **MCP Server:** Node.js with Docker

---

## MCP Server Integration

This project has a **personal Model Context Protocol (MCP) server** for enhanced development tooling. Use these tools to analyze code, get project statistics, and work with Godot files.

### Starting the MCP Server

```powershell
cd .mcp-server
docker-compose -f docker-compose.godot.yml up -d
```

### Available MCP Tools

| Tool | Description | When to Use |
|------|-------------|-------------|
| `project_stats` | Get file counts, lines of code, averages | Understanding project scope |
| `find_todos` | Find TODO, FIXME, HACK comments | Tracking technical debt |
| `list_scripts` | List all .gd script files | Navigating codebase |
| `list_scenes` | List all .tscn scene files | Finding scenes |
| `read_script` | Read a specific .gd file | Examining code |
| `search_scripts` | Search for patterns in scripts | Finding implementations |
| `godot_find_node_references` | Find node types/signals in scripts | Understanding connections |
| `godot_analyze_dependencies` | Analyze preload/load statements | Dependency mapping |
| `godot_version` | Get Godot version info | Version checks |
| `godot_validate_project` | Validate project.godot | Project validation |
| `godot_run_tests` | Run GDScript tests | Testing |

### Using MCP Tools

When the user asks about the project structure, statistics, or wants code analysis, proactively use the MCP tools:

```
"Analyze dependencies in player.gd" → Use godot_analyze_dependencies
"Show project stats" → Use project_stats
"Find all TODOs" → Use find_todos
"List all scenes" → Use list_scenes
```

### Dashboard Access

The MCP server provides a web dashboard at `http://localhost:3100` with:
- Real-time project statistics
- Interactive tool execution
- Learning resources

---

## Project Structure

```
cargo-escape/
├── .mcp-server/          # MCP Server (Docker-based)
│   ├── src/
│   │   ├── index.js      # stdio transport (VS Code)
│   │   ├── http-server.js # HTTP/SSE transport (Docker)
│   │   └── dashboard.js  # Web dashboard
│   ├── docker-compose.godot.yml  # Full build with Godot 4.6
│   └── DEVELOPMENT.md    # MCP development guide
├── assets/               # Game assets (sprites, audio)
├── resources/            # Godot resources (.tres files)
├── scenes/               # Godot scenes (.tscn files)
├── scripts/              # GDScript files (.gd)
├── shaders/              # Shader files
├── test/                 # Test files
└── project.godot         # Godot project config
```

### Key Directories

| Directory | Purpose |
|-----------|---------|
| `scripts/` | All game logic (GDScript) |
| `scenes/` | UI, enemies, player, etc. |
| `resources/` | Items, modules, backgrounds |
| `assets/sprites/` | Game artwork |
| `assets/audio/` | Sound effects and music |

---

## Coding Standards

### GDScript Conventions

1. **Use snake_case** for variables and functions
2. **Use PascalCase** for class names
3. **Use SCREAMING_SNAKE_CASE** for constants
4. **Prefix private members** with underscore `_private_var`
5. **Type hints** are encouraged: `var health: int = 100`

### File Organization

- One class per file
- Match filename to class name (e.g., `player.gd` for Player)
- Group related scripts in subdirectories

### Signal Naming

- Use past tense for events: `health_changed`, `enemy_died`
- Use present tense for requests: `damage_requested`

---

## Common Patterns

### Autoloads (Singletons)

Key global managers (check `project.godot` for current list):
- `GameManager` - Game state, scoring
- `AudioManager` - Sound effects and music
- `SaveManager` - Save/load functionality
- `AchievementManager` - Achievements
- `PopupManager` - UI notifications

### Scene Instantiation

```gdscript
# Preload for frequently used scenes
const EnemyScene = preload("res://scenes/enemy.tscn")

# Instance and add to tree
var enemy = EnemyScene.instantiate()
add_child(enemy)
```

### Signal Connection

```gdscript
# In _ready()
health_component.health_depleted.connect(_on_health_depleted)

# Handler
func _on_health_depleted() -> void:
    queue_free()
```

---

## Game Systems Reference

### Core Systems
- **Boarding System** - See `BOARDING_SYSTEM_DESIGN.md`
- **Loot System** - See `LOOT_SYSTEM_DOCS.md`
- **Save System** - See `SAVE_SYSTEM_DOCS.md`
- **Achievement System** - See `ACHIEVEMENT_SYSTEM.md`
- **Tutorial System** - See `TUTORIAL_SYSTEM_DOCS.md`

### UI Systems
- **Minimap** - See `MINIMAP_DOCUMENTATION.md`
- **Pause Menu** - See `PAUSE_MENU_DOCS.md`
- **Loading Screen** - See `LOADING_SCREEN_DOCS.md`

### Technical Docs
- **AI Behavior** - See `AI_BEHAVIOR_TREES.md`
- **Object Pooling** - See `OBJECT_POOL_DOCS.md`
- **Visual Effects** - See `VISUAL_FEEDBACK_FEATURES.md`

---

## Testing

### Running Tests

With MCP server running:
```
Use the godot_run_tests tool to execute GDScript tests
```

Or manually:
```powershell
# In container
docker exec cargo-escape-mcp-godot godot --headless --path /workspace --script test/run_tests.gd
```

### Test Location
- Test files are in `test/` directory
- Follow naming: `test_*.gd`

---

## Troubleshooting

### MCP Server Issues

```powershell
# Check if running
docker ps | findstr cargo-escape

# View logs
docker logs cargo-escape-mcp-godot

# Restart
cd .mcp-server
docker-compose -f docker-compose.godot.yml down
docker-compose -f docker-compose.godot.yml up -d
```

### Common Godot Issues

1. **Scene won't load** - Check for circular dependencies
2. **Signals not connecting** - Verify node paths are correct
3. **Null reference** - Ensure `@onready` vars are accessed after `_ready()`

---

## Security Notes

The MCP server has security features enabled:

| Feature | Status |
|---------|--------|
| Localhost-only binding | ✅ `127.0.0.1:3100` |
| API key authentication | ✅ Required for protected endpoints |
| Rate limiting | ✅ Non-localhost only (you're exempt) |
| CORS restrictions | ✅ Localhost origins only |
| Path traversal protection | ✅ Can't escape workspace |

**API Key:** `CargoEscapeBigProject` (configured in docker-compose)

---

## Quick Commands

```powershell
# Start MCP server
cd .mcp-server && docker-compose -f docker-compose.godot.yml up -d

# Stop MCP server
cd .mcp-server && docker-compose -f docker-compose.godot.yml down

# View server logs
docker logs -f cargo-escape-mcp-godot

# Rebuild after changes
cd .mcp-server && docker-compose -f docker-compose.godot.yml build --no-cache && docker-compose -f docker-compose.godot.yml up -d

# Check project stats (via API)
Invoke-WebRequest -Uri "http://localhost:3100/api/stats" -Headers @{"Authorization"="Bearer CargoEscapeBigProject"} -UseBasicParsing
```

---

## When Working on This Project

1. **Use MCP tools** for code analysis and navigation
2. **Check documentation** before implementing features (many .md files exist)
3. **Follow GDScript conventions** for consistency
4. **Test changes** using the Godot test framework
5. **Reference autoloads** for global functionality

---

*Last updated: February 2, 2026*
