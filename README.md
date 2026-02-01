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

**Note:** All controls can be customized through the Accessibility menu!

## Accessibility Features

Cargo Escape includes comprehensive accessibility options to ensure everyone can enjoy the game:

### Visual Accessibility
- **Colorblind Modes**: Support for deuteranopia, protanopia, and tritanopia
  - Simulates how colorblind players see the game
  - Uses scientifically-based color transformation matrices
- **High Contrast Mode**: Enhances UI visibility with increased contrast
- **Text Size Options**: Choose from Normal, Large, or Extra Large text
  - Applies to all in-game menus and HUD elements

### Motion Accessibility
- **Reduce Motion**: Disables animations and transitions
  - Helpful for players sensitive to motion
  - Improves performance on lower-end systems

### Input Accessibility
- **Custom Control Remapping**: Remap any game action to your preferred keys
  - All movement, combat, and menu actions can be customized
  - Settings persist across game sessions

### Screen Reader Support
- **Screen Reader Mode**: Announces important UI changes
  - Currently outputs to console log
  - Can be extended for OS-level screen reader integration

### How to Access

From the main menu, click **ACCESSIBILITY** to configure all settings. Your preferences are automatically saved and will persist across game sessions.
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

