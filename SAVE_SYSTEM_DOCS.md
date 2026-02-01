# Auto-Save System Documentation

## Overview

The Cargo Escape game now includes a comprehensive auto-save system that preserves player progress across game sessions. The system uses Godot's `ConfigFile` API to store data in the user's local application data directory.

## Features

### Data Saved
The save system automatically tracks and persists:

1. **Player Inventory**
   - Ship inventory (items currently on the ship)
   - Stash inventory (items stored in hideout)
   
2. **Credits & Economy**
   - Current credits balance
   
3. **Upgrades**
   - Health upgrade level
   - Laser damage upgrade level
   - Ship inventory capacity upgrades
   - Stash inventory capacity upgrades
   
4. **Player Preferences**
   - Ship type selection
   - Current loot tier
   
5. **Equipped Modules**
   - All three module slots (Flight, Combat, Utility)
   
6. **Game State**
   - Current station location

### Auto-Save Triggers

The game automatically saves at strategic points:

1. **After Boarding Mission** - When successfully completing a boarding mission
2. **Arriving at Hideout** - When reaching the hideout after escaping
3. **Leaving Hideout** - Before departing for a new mission
4. **Returning to Menu** - When exiting to the main menu

### Manual Save

Players can manually save at any time by pressing **F5** while in the hideout. A notification will confirm the save was successful.

## Technical Details

### Save File Location

The save file is stored in the platform-specific user data directory:

- **Windows**: `%APPDATA%\Godot\app_userdata\Cargo Escape\save_data.cfg`
- **Linux**: `~/.local/share/godot/app_userdata/Cargo Escape/save_data.cfg`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/Cargo Escape/save_data.cfg`

### Save File Format

The system uses Godot's ConfigFile format (INI-style), which is human-readable and easy to debug. Example structure:

```ini
[meta]
version=1
save_time="2024-01-15 14:30:22"

[player]
credits=1500
health_upgrade_level=2
laser_upgrade_level=1
ship_inventory_upgrade=0
stash_inventory_upgrade=1
ship_type=0
loot_tier=1

[modules]
module_slot_0="res://resources/modules/basic_thruster.tres"
module_slot_1="res://resources/modules/basic_laser.tres"
module_slot_2=""

[ship_inventory]
count=3
item_0="res://resources/items/salvage_1.tres"
item_1="res://resources/items/medical_kit.tres"
item_2="res://resources/items/fuel_cell.tres"

[stash_inventory]
count=5
item_0="res://resources/items/rare_artifact.tres"
...
```

### Implementation Files

The save system consists of:

1. **SaveManager** (`scripts/save_manager.gd`) - Singleton autoload that handles all save/load operations
2. **Integration Points** - Scene transition hooks in:
   - `scripts/main.gd` - Escape sequence completion
   - `scripts/hideout/hideout_manager.gd` - Hideout interactions
   - `scripts/boarding/boarding_manager.gd` - Boarding completion

## For Developers

### Accessing the Save System

The SaveManager is available globally as an autoload:

```gdscript
# Save the game
if has_node("/root/SaveManager"):
    var save_manager = get_node("/root/SaveManager")
    save_manager.save_game()

# Load the game
if has_node("/root/SaveManager"):
    var save_manager = get_node("/root/SaveManager")
    save_manager.load_game()

# Auto-save (only saves if enabled)
if has_node("/root/SaveManager"):
    var save_manager = get_node("/root/SaveManager")
    save_manager.auto_save()
```

### Save Manager Signals

The SaveManager emits signals for save/load events:

```gdscript
# Connect to signals
save_manager.save_completed.connect(_on_save_completed)
save_manager.load_completed.connect(_on_load_completed)
save_manager.save_failed.connect(_on_save_failed)
save_manager.load_failed.connect(_on_load_failed)
```

### Extending the Save System

To add new data to the save system:

1. Add the data to GameManager as a persistent variable
2. Update `SaveManager.save_game()` to save the new data:
   ```gdscript
   config.set_value("player", "new_stat", game_manager.new_stat)
   ```
3. Update `SaveManager.load_game()` to load the new data:
   ```gdscript
   game_manager.new_stat = config.get_value("player", "new_stat", default_value)
   ```

### Testing

A test script is provided at `test_save_system.gd` that can be attached to a test scene to verify save/load functionality. Run it to ensure the system is working correctly after making changes.

### Troubleshooting

**Save file not found**: The game automatically creates a save file on first save. If loading fails, it's because no save exists yet.

**Data not persisting**: Ensure the data is stored in GameManager (the autoload singleton) and not in scene-specific scripts, as scene data is not persistent.

**Version conflicts**: The save system includes a version number. If you make breaking changes to the save format, increment `SAVE_VERSION` in SaveManager and add migration logic in `load_game()`.

## Future Enhancements

Potential improvements for the save system:

- Multiple save slots
- Cloud save integration
- Compressed save files
- Encrypted save data (prevent tampering)
- Auto-save frequency settings
- Save game metadata (playtime, difficulty, etc.)
- Backup saves (automatic backup of last N saves)

## Notes

- The system automatically loads the save file when the game starts (in SaveManager._ready())
- Auto-save is enabled by default but can be disabled with `SaveManager.set_auto_save_enabled(false)`
- The save file is human-readable, making it easy to debug issues
- All resource references (items, modules) are saved as resource paths and reloaded from disk
