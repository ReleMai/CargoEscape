# Pause Menu Feature Documentation

## Overview
A comprehensive pause menu system has been added to Cargo Escape, accessible during gameplay by pressing the **ESC** key.

## Features

### Pause Menu
- **Resume**: Continue gameplay
- **Settings**: Access settings submenu
- **Main Menu**: Return to the main menu
- **Quit Game**: Exit the application

### Settings Menu
The settings menu provides customization options:

#### Audio Settings
- **Master Volume**: Control overall game volume (0-100%)
- **SFX Volume**: Control sound effects volume (0-100%)
- **Music Volume**: Control music volume (0-100%)

#### Display Settings
- **Fullscreen Toggle**: Switch between windowed and fullscreen mode

#### Controls
- Control rebinding functionality is documented as "coming soon"

## Implementation Details

### Files Created
1. **scripts/ui/pause_menu.gd** - Pause menu logic
2. **scripts/ui/settings_menu.gd** - Settings menu logic with persistent storage
3. **scripts/ui/pause_manager.gd** - Manages transitions between pause and settings
4. **scenes/ui/pause_menu.tscn** - Pause menu UI layout
5. **scenes/ui/settings_menu.tscn** - Settings menu UI layout
6. **scenes/ui/pause_manager.tscn** - Parent scene containing both menus

### Integration
The pause manager has been integrated into:
- Main game scene (scenes/main.tscn)
- Boarding scene (scenes/boarding/boarding_scene.tscn)
- Undocking scene (scenes/undocking/undocking_scene.tscn)

### Input Mapping
- **Pause Key**: ESC (Escape key - physical_keycode: 4194305)
- Added to project.godot input mappings

### Settings Persistence
Settings are saved to `user://settings.cfg` and persist between game sessions.

### Process Mode
All pause menu components use `PROCESS_MODE_ALWAYS` to ensure they function even when the game tree is paused.

## Usage

### For Players
1. Press **ESC** during gameplay to open the pause menu
2. Navigate using mouse or keyboard (Tab/Arrow keys)
3. Adjust settings as desired - changes are saved automatically
4. Press **ESC** again or click **Resume** to continue playing

### For Developers
To add the pause menu to a new scene:
```gdscript
# In your scene file (.tscn), add:
[ext_resource type="PackedScene" uid="uid://bpaxn8mxmxdmdc" path="res://scenes/ui/pause_manager.tscn" id="N_pause"]

# Then add as a child node:
[node name="PauseManager" parent="." instance=ExtResource("N_pause")]
```

The pause menu will automatically handle input and pause/unpause the game tree.

## Technical Notes

### Audio Bus Configuration
The settings menu expects these audio buses to be configured:
- Master (default, always present)
- SFX (optional - configure in Project Settings > Audio)
- Music (optional - configure in Project Settings > Audio)

If SFX or Music buses don't exist, their volume sliders will only affect the Master bus.

### Future Enhancements
- Control rebinding UI
- Additional graphics settings (resolution, vsync, etc.)
- Gameplay difficulty settings
- Key binding visualization
