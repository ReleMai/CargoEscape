# Tutorial System Documentation

## Overview

The tutorial system provides an interactive, step-by-step guide for first-time players. It features:
- Dynamic UI highlighting
- Context-sensitive tooltips
- Skip option
- Persistent completion tracking
- Minimal code coupling

## Architecture

### Components

1. **SaveManager** (`scripts/core/save_manager.gd`)
   - Autoload singleton
   - Manages save/load of tutorial completion state
   - Tracks individual step completion
   - Stores player settings

2. **TutorialManager** (`scripts/core/tutorial_manager.gd`)
   - Autoload singleton
   - Controls tutorial flow and step progression
   - Defines tutorial steps and their requirements
   - Manages tutorial lifecycle

3. **TutorialOverlay** (`scenes/ui/tutorial_overlay.tscn` + `scripts/ui/tutorial_overlay.gd`)
   - Visual UI layer (CanvasLayer, layer 100)
   - Displays tooltips and highlights
   - Provides skip button
   - Handles animations

### Tutorial Steps

```gdscript
enum TutorialStep {
    NONE = -1,
    MOVEMENT = 0,              # WASD/Arrow keys
    CONTAINER_INTERACTION = 1, # Press E on containers
    INVENTORY = 2,             # Press I/TAB
    TIMER = 3,                 # Understand time limit
    EXIT = 4,                  # Find and reach exit
    SELLING = 5                # Sell loot at station
}
```

## Integration Points

### Boarding Manager Integration
The boarding manager triggers tutorial events:

```gdscript
# In boarding_manager.gd
func _interact_with_container(container: Node2D) -> void:
    _on_container_interacted()  # Notifies tutorial
    # ... rest of interaction code
```

### Player Movement Detection
Player movement is detected via signal:

```gdscript
# In boarding_player.gd
signal tutorial_movement_detected

# Emitted when player first moves during tutorial
```

### Station Integration
Station selling is tracked:

```gdscript
# In station.gd
func _on_sell_pressed() -> void:
    _on_item_sold()  # Notifies tutorial
    # ... rest of selling code
```

## Adding New Tutorial Steps

1. **Define the step in TutorialManager:**

```gdscript
const STEP_DATA = {
    TutorialStep.NEW_STEP: {
        "id": "new_step",
        "title": "New Tutorial Step",
        "description": "Instructions for the player...",
        "highlight_target": "target_name",  # or null
        "wait_for_action": "action_name"    # or "none"
    }
}
```

2. **Add to SaveManager tracking:**

```gdscript
var tutorial_steps_completed: Dictionary = {
    # ... existing steps
    "new_step": false
}
```

3. **Configure highlight target (if needed):**

In `tutorial_overlay.gd`:

```gdscript
const HIGHLIGHT_TARGETS = {
    "target_name": {"group": "group_name", "name": null},
    # OR
    "target_name": {"group": null, "name": "NodeName"}
}
```

4. **Trigger the step:**

```gdscript
# In appropriate game script
if has_node("/root/TutorialManager"):
    var tutorial_manager = get_node("/root/TutorialManager")
    tutorial_manager.on_player_action("action_name")
```

## API Reference

### SaveManager

```gdscript
# Check if tutorial should show
SaveManager.should_show_tutorial() -> bool

# Mark tutorial complete
SaveManager.complete_tutorial() -> void

# Complete a specific step
SaveManager.complete_tutorial_step(step_id: String) -> void

# Check if step is completed
SaveManager.is_tutorial_step_completed(step_id: String) -> bool

# Reset tutorial (for testing)
SaveManager.reset_tutorial() -> void
```

### TutorialManager

```gdscript
# Start tutorial system
TutorialManager.start_tutorial() -> void

# Skip tutorial
TutorialManager.skip_tutorial() -> void

# Complete current step
TutorialManager.complete_current_step() -> void

# Start specific step
TutorialManager.start_step(step: TutorialStep) -> void

# Notify of player action
TutorialManager.on_player_action(action: String) -> void

# Check if active
TutorialManager.is_tutorial_active() -> bool

# Signals
signal tutorial_started
signal tutorial_completed
signal tutorial_skipped
signal step_started(step_id: String)
signal step_completed(step_id: String)
```

### TutorialOverlay

```gdscript
# Show a tutorial step
show_step(step_data: Dictionary) -> void

# Hide tutorial
hide_tutorial() -> void

# Signals
signal skip_requested
```

## Configuration

### Autoloads
Configured in `project.godot`:

```ini
[autoload]
GameManager="*res://scripts/game_manager.gd"
SaveManager="*res://scripts/core/save_manager.gd"
TutorialManager="*res://scripts/core/tutorial_manager.gd"
```

### Save File Location

`user://save_data.cfg` (varies by platform)

## Best Practices

1. **Non-blocking**: Tutorial doesn't prevent normal gameplay
2. **Skippable**: Always allow players to skip
3. **Persistent**: Save completion state
4. **Visual**: Use highlights and clear text
5. **Progressive**: Steps build on each other
6. **Forgiving**: Don't punish players for exploring

## Testing

See `TUTORIAL_TESTING.md` for comprehensive testing guide.

## Troubleshooting

### Tutorial not starting
- Verify autoloads are configured
- Check save file: `tutorial/completed` should be `false`
- Ensure `SaveManager.should_show_tutorial()` returns `true`

### Highlights not appearing
- Verify target nodes exist in scene tree
- Check node names/groups match `HIGHLIGHT_TARGETS`
- Ensure nodes are children of scene root

### Steps not progressing
- Verify tutorial actions are being called
- Check console for `[TutorialManager]` messages
- Ensure signal connections are set up

### Save not persisting
- Check file permissions on save directory
- Look for errors in console from SaveManager
- Verify `ConfigFile.save()` returns OK

## Future Enhancements

Potential improvements:
- Tutorial for space combat phase
- Multi-language support
- Configurable tutorial verbosity
- In-game tutorial replay option
- Achievement/reward for completing tutorial
- Adaptive difficulty based on player performance
