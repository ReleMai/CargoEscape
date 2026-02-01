# Cargo Escape 🚀

A side-scrolling space escape game built in Godot 4.5

## Quick Start

1. Open project in Godot 4.5+
2. Press F5 or click Play to run
3. Use WASD or Arrow Keys to move
4. Dodge the asteroids!

## Controls

### Movement
| Key | Action |
|-----|--------|
| W / ↑ | Move Up |
| S / ↓ | Move Down |
| A / ← | Move Left |
| D / → | Move Right |

### Inventory (Loot Phase)
| Key | Action |
|-----|--------|
| 1-9 | Quick select inventory slot |
| Q | Drop selected item |
| E | Use/equip selected item |
| Tab / I | Toggle inventory view |
| Escape | Close menus |

## Game Rules

- You have 3 lives
- Hitting an asteroid = lose 1 life
- Survive as long as possible!

## Project Structure

See `DOCUMENTATION.md` for full learning documentation.

## Files Overview

- `scenes/` - All game scenes (`.tscn` files)
- `scripts/` - All game logic (`.gd` files)
- `assets/` - Images and sounds

## For Learners

Every script file contains detailed comments explaining:
- What each line does
- Why it's written that way
- How to modify it

Start by reading `scripts/player.gd` - it's the most commented!
