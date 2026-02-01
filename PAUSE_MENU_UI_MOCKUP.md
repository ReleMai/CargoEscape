# Pause Menu UI Mockup

## Pause Menu Layout

```
┌──────────────────────────────────────────┐
│                                          │
│          ╔════════════════════╗          │
│          ║                    ║          │
│          ║      PAUSED        ║          │
│          ║                    ║          │
│          ║   ┌──────────┐     ║          │
│          ║   │  Resume  │     ║          │
│          ║   └──────────┘     ║          │
│          ║                    ║          │
│          ║   ┌──────────┐     ║          │
│          ║   │ Settings │     ║          │
│          ║   └──────────┘     ║          │
│          ║                    ║          │
│          ║   ┌──────────┐     ║          │
│          ║   │Main Menu │     ║          │
│          ║   └──────────┘     ║          │
│          ║                    ║          │
│          ║   ┌──────────┐     ║          │
│          ║   │Quit Game │     ║          │
│          ║   └──────────┘     ║          │
│          ║                    ║          │
│          ╚════════════════════╝          │
│                                          │
│      (Semi-transparent dark overlay)     │
└──────────────────────────────────────────┘
```

## Settings Menu Layout

```
┌──────────────────────────────────────────────────┐
│                                                  │
│        ╔════════════════════════════════╗        │
│        ║         SETTINGS               ║        │
│        ║                                ║        │
│        ║  Audio                         ║        │
│        ║  ────────────────────────      ║        │
│        ║                                ║        │
│        ║  Master Volume:  [▓▓▓▓▓▓▓▓] 100% ║      │
│        ║  SFX Volume:     [▓▓▓▓▓▓▓▓] 100% ║      │
│        ║  Music Volume:   [▓▓▓▓▓▓▓▓] 100% ║      │
│        ║                                ║        │
│        ║  Display                       ║        │
│        ║  ────────────────────────      ║        │
│        ║                                ║        │
│        ║  [✓] Fullscreen                ║        │
│        ║                                ║        │
│        ║  Controls                      ║        │
│        ║  ────────────────────────      ║        │
│        ║                                ║        │
│        ║  Control rebinding coming soon! ║       │
│        ║                                ║        │
│        ║                                ║        │
│        ║        ┌──────────┐            ║        │
│        ║        │   Back   │            ║        │
│        ║        └──────────┘            ║        │
│        ║                                ║        │
│        ╚════════════════════════════════╝        │
│                                                  │
│        (Semi-transparent dark overlay)           │
└──────────────────────────────────────────────────┘
```

## User Flow Diagram

```
┌─────────────┐
│  Gameplay   │
│             │
└──────┬──────┘
       │
       │ Press ESC
       ▼
┌─────────────┐     Click Settings     ┌──────────────┐
│ Pause Menu  │───────────────────────>│Settings Menu │
│             │                        │              │
│  - Resume   │<───────────────────────│  - Audio     │
│  - Settings │     Click Back         │  - Display   │
│  - Main Menu│                        │  - Controls  │
│  - Quit     │                        │  - Back      │
└──────┬──────┘                        └──────────────┘
       │                                      │
       │ Click Resume / Press ESC            │ Auto-saves
       │                                      │ settings
       ▼                                      ▼
┌─────────────┐                        user://settings.cfg
│  Gameplay   │
│ (Resumed)   │
└─────────────┘
```

## Key Features

### Pause Menu
- **Overlay**: Semi-transparent black (70% opacity)
- **Panel**: Centered, white/light colored background
- **Buttons**: Large, easy to click (font size: 20)
- **Title**: "PAUSED" in large text (font size: 32)

### Settings Menu
- **Sliders**: HSlider controls for volume (0.0 - 1.0 range)
- **Labels**: Display current percentage values
- **Checkbox**: Toggle button for fullscreen
- **Organization**: Grouped by category (Audio, Display, Controls)

### Interaction
1. **Pause**: Press ESC key during gameplay
2. **Navigate**: Mouse or keyboard (Tab/Arrow keys + Enter)
3. **Resume**: ESC again or click Resume button
4. **Settings**: All changes auto-save immediately
5. **Main Menu**: Unpauses game and returns to main menu
6. **Quit**: Exits the application

## Technical Implementation

### Process Mode
All UI elements use `PROCESS_MODE_ALWAYS` to function when game is paused.

### Input Handling
- Pause menu listens for "pause" action (ESC key)
- Can toggle pause state from anywhere in the game
- Input is properly handled to prevent conflicts

### Settings Persistence
```gdscript
# Settings stored in ConfigFile format
[audio]
master_volume=1.0
sfx_volume=1.0
music_volume=1.0

[display]
fullscreen=false
```

### Audio Implementation
Uses Godot's AudioServer to control volume:
- Linear volume (0.0-1.0) converted to decibels
- Separate buses for Master, SFX, and Music
- Real-time volume adjustment
