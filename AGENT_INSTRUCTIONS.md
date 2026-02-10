# Agent Instructions for Cargo Escape

> **Comprehensive guide for AI agents working on this Godot 4.x space game project**

---

## Project Identity

| Property | Value |
|----------|-------|
| **Name** | Cargo Escape |
| **Engine** | Godot 4.x |
| **Language** | GDScript |
| **Genre** | 2D Space Combat/Boarding |
| **MCP Server** | Node.js + Docker |

---

## Quick Reference

### Project Structure

```
cargo-escape/
├── .mcp-server/          # MCP Server (Docker-based tooling)
├── assets/               # Sprites, audio
├── resources/            # .tres files (items, modules, backgrounds)
├── scenes/               # .tscn files (UI, enemies, player)
├── scripts/              # GDScript game logic
├── shaders/              # Shader files
├── test/                 # Test files
└── project.godot         # Godot project config
```

### Key Autoloads (Singletons)

- `GameManager` - Game state, scoring
- `AudioManager` - Sound effects, music
- `SaveManager` - Save/load functionality
- `AchievementManager` - Achievements
- `PopupManager` - UI notifications

---

## MCP Tools Available

This project has a **Model Context Protocol server** with specialized tools. Use them proactively.

### Project Analysis Tools

| Tool | Purpose | Example Use |
|------|---------|-------------|
| `project_stats` | File counts, lines of code | "How big is this project?" |
| `find_todos` | Find TODO/FIXME/HACK comments | "What technical debt exists?" |

### Godot-Specific Tools

| Tool | Purpose | Example Use |
|------|---------|-------------|
| `list_scripts` | List all .gd files | "Show me all scripts" |
| `list_scenes` | List all .tscn files | "What scenes exist?" |
| `godot_find_node_references` | Find node types/signals | "Where is Area2D used?" |
| `godot_analyze_dependencies` | Analyze preload/load | "What does player.gd depend on?" |

### When to Use MCP Tools

| User Request | Tool to Use |
|--------------|-------------|
| "Analyze dependencies in X.gd" | `godot_analyze_dependencies` |
| "Show project stats" | `project_stats` |
| "Find all TODOs" | `find_todos` |
| "List all scenes" | `list_scenes` |
| "Find where signal X is used" | `godot_find_node_references` |

---

## Coding Standards

### GDScript Conventions

```gdscript
# Naming
var player_health: int = 100      # snake_case for variables
const MAX_SPEED: float = 500.0    # SCREAMING_SNAKE_CASE for constants
var _private_data: Dictionary     # underscore prefix for private
class_name PlayerShip             # PascalCase for classes

# Type hints are encouraged
func take_damage(amount: int) -> void:
    player_health -= amount
```

### Signal Naming

- **Past tense for events:** `health_changed`, `enemy_died`, `item_collected`
- **Present tense for requests:** `damage_requested`, `spawn_requested`

### File Organization

- One class per file
- Match filename to class name (`player.gd` → `Player`)
- Group related scripts in subdirectories

---

## Common Patterns

### Scene Instantiation

```gdscript
# Preload for frequently used scenes
const EnemyScene = preload("res://scenes/enemy.tscn")

# Instance and add to tree
func spawn_enemy() -> void:
    var enemy = EnemyScene.instantiate()
    add_child(enemy)
```

### Signal Connection

```gdscript
func _ready() -> void:
    health_component.health_depleted.connect(_on_health_depleted)

func _on_health_depleted() -> void:
    queue_free()
```

### Using Autoloads

```gdscript
# Access global managers directly
GameManager.add_score(100)
AudioManager.play_sfx("explosion")
SaveManager.save_game()
```

---

## Documentation Map

### Core Game Systems

| System | Documentation File |
|--------|-------------------|
| Boarding Mechanics | `BOARDING_SYSTEM_DESIGN.md` |
| Loot/Items | `LOOT_SYSTEM_DOCS.md` |
| Save/Load | `SAVE_SYSTEM_DOCS.md` |
| Achievements | `ACHIEVEMENT_SYSTEM.md` |
| Tutorial | `TUTORIAL_SYSTEM_DOCS.md` |
| Factions | `FACTION_ITEMS.md` |

### UI Systems

| System | Documentation File |
|--------|-------------------|
| Minimap | `MINIMAP_DOCUMENTATION.md` |
| Pause Menu | `PAUSE_MENU_DOCS.md` |
| Loading Screen | `LOADING_SCREEN_DOCS.md` |

### Technical Systems

| System | Documentation File |
|--------|-------------------|
| AI Behavior | `AI_BEHAVIOR_TREES.md` |
| Object Pooling | `OBJECT_POOL_DOCS.md` |
| Visual Effects | `VISUAL_FEEDBACK_FEATURES.md` |
| Sound | `SOUND_SYSTEM_DOCS.md` |

**Always check relevant documentation before implementing features.**

---

## MCP Server Management

### Starting the Server

```powershell
cd .mcp-server
docker-compose -f docker-compose.godot.yml up -d
```

### Stopping the Server

```powershell
cd .mcp-server
docker-compose -f docker-compose.godot.yml down
```

### Checking Status

```powershell
docker ps | findstr cargo-escape
docker logs cargo-escape-mcp-godot
```

### Dashboard

Web UI available at `http://localhost:3100` when server is running.

### API Access

```powershell
# API Key: CargoEscapeBigProject
$headers = @{ "Authorization" = "Bearer CargoEscapeBigProject" }
Invoke-WebRequest -Uri "http://localhost:3100/api/stats" -Headers $headers
```

---

## Testing

### Test Location

- Test files in `test/` directory
- Naming convention: `test_*.gd`

### Running Tests

```powershell
# Via Docker container
docker exec cargo-escape-mcp-godot godot --headless --path /workspace --script test/run_tests.gd
```

Or use the `godot_run_tests` MCP tool when available.

---

## Troubleshooting

### Common Godot Issues

| Problem | Solution |
|---------|----------|
| Scene won't load | Check for circular dependencies |
| Signals not connecting | Verify node paths are correct |
| Null reference | Ensure `@onready` vars accessed after `_ready()` |
| Resource not found | Check `res://` path is correct |

### MCP Server Issues

```powershell
# View logs
docker logs cargo-escape-mcp-godot

# Restart server
cd .mcp-server
docker-compose -f docker-compose.godot.yml down
docker-compose -f docker-compose.godot.yml up -d

# Rebuild after code changes
docker-compose -f docker-compose.godot.yml build --no-cache
docker-compose -f docker-compose.godot.yml up -d
```

---

## Security Notes

| Feature | Status |
|---------|--------|
| Localhost-only binding | ✅ `127.0.0.1:3100` |
| API key authentication | ✅ Required for protected endpoints |
| Rate limiting | ✅ Non-localhost only |
| Path traversal protection | ✅ Cannot escape workspace |

---

## Agent Workflow Checklist

When working on this project:

- [ ] **Use MCP tools** for code analysis and navigation
- [ ] **Check documentation** before implementing features
- [ ] **Follow GDScript conventions** for consistency
- [ ] **Reference autoloads** for global functionality
- [ ] **Test changes** when possible
- [ ] **Check for existing patterns** before creating new ones

---

## File Locations Quick Reference

| Looking For | Location |
|-------------|----------|
| Main game script | `scripts/main.gd` |
| Player logic | `scripts/player.gd` |
| Enemy logic | `scripts/enemy.gd` |
| Game state | `scripts/game_manager.gd` |
| Audio handling | `scripts/audio_manager.gd` |
| Save/load | `scripts/save_manager.gd` |
| UI scenes | `scenes/ui/` |
| Enemy scenes | `scenes/enemies/` |
| Item resources | `resources/items/` |
| Sprites | `assets/sprites/` |
| Audio files | `assets/audio/` |

---

*Last updated: February 2, 2026*
