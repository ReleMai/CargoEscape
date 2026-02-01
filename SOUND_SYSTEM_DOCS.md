# Sound System Documentation

## Overview

The CargoEscape game features a comprehensive sound effects system that enhances the boarding and looting gameplay experience. The system is managed through a centralized `AudioManager` singleton that provides efficient audio playback with features like sound pooling, pitch variation, and volume control.

## Architecture

### AudioManager (Singleton)

The `AudioManager` is an autoloaded singleton (accessible globally as `AudioManager`) that manages all sound effects in the game.

**Location**: `scripts/audio_manager.gd`

**Key Features**:
- **Centralized Sound Management**: All sound effects are played through a single manager
- **Audio Player Pooling**: Reuses AudioStreamPlayer nodes for performance
- **Pitch Variation**: Adds variety to repeated sounds
- **Volume Control**: Master and SFX volume settings
- **Easy API**: Simple function calls to play sounds from anywhere

### Sound Effects Library

All sound effects are stored in: `assets/audio/sfx/boarding/`

**Available Sounds**:

| Sound Name | File | Description | Used For |
|------------|------|-------------|----------|
| `airlock_open` | airlock_open.wav | Airlock door opening | Airlock entry/exit |
| `airlock_close` | airlock_close.wav | Airlock door closing | Airlock sealing |
| `door_open` | (reuses airlock_open) | Regular door opening | Ship interior doors |
| `door_close` | (reuses airlock_close) | Regular door closing | Ship interior doors |
| `footstep` | footstep.wav | Player footstep | Movement on ship floors |
| `container_open` | container_open.wav | Container opening | Opening loot containers |
| `container_search` | container_search.wav | Searching container | Searching for items |
| `loot_pickup` | loot_pickup.wav | Item pickup | Transferring items to inventory |
| `escape` | escape.wav | Escape success | Reaching exit point |

## Usage

### Playing a Sound Effect

```gdscript
# Simple playback
AudioManager.play_sfx("footstep")

# With custom volume (in decibels)
AudioManager.play_sfx("door_open", -2.0)

# With custom volume and pitch
AudioManager.play_sfx("loot_pickup", -2.0, 1.2)
```

### Playing with Pitch Variation

For sounds that repeat frequently (like footsteps), use pitch variation to make them sound more natural:

```gdscript
# Vary pitch by ±10% and adjust volume
AudioManager.play_sfx_varied("footstep", 0.1, -6.0)

# Vary pitch by ±20%
AudioManager.play_sfx_varied("loot_pickup", 0.2)
```

### Volume Control

```gdscript
# Set master volume (0.0 to 1.0)
AudioManager.set_master_volume(0.8)

# Set SFX volume (0.0 to 1.0)
AudioManager.set_sfx_volume(0.7)
```

### Stopping Sounds

```gdscript
# Stop all instances of a specific sound
AudioManager.stop_sfx("container_search")

# Stop all currently playing sounds
AudioManager.stop_all_sfx()
```

## Integration Points

### Door Sounds

**File**: `scripts/boarding/door.gd`

Doors automatically play sounds when opened/closed:
- Airlocks (when `is_airlock = true`) play louder sounds at -2dB
- Regular doors play quieter sounds at -4dB

```gdscript
# In door.gd
func open() -> void:
    # ...
    if is_airlock:
        AudioManager.play_sfx("airlock_open", -2.0)
    else:
        AudioManager.play_sfx("door_open", -4.0)
    # ...
```

### Footstep Sounds

**File**: `scripts/boarding/boarding_player.gd`

Footsteps are triggered automatically during player movement:
- Only plays when moving at >30% of max speed
- Timed intervals of 0.35 seconds between steps
- Uses pitch and volume variation for natural sound

```gdscript
# In boarding_player.gd
func _play_footstep() -> void:
    var pitch_var = randf_range(0.9, 1.1)
    var volume_var = randf_range(-8.0, -6.0)
    AudioManager.play_sfx("footstep", volume_var, pitch_var)
```

### Container Sounds

**File**: `scripts/boarding/ship_container.gd`

Containers play sounds during interaction:
- Opening sound when first interacted with
- Search sound when searching begins

```gdscript
# In ship_container.gd
func start_search() -> void:
    # ...
    AudioManager.play_sfx_varied("container_open", 0.15, -3.0)
    # ...
    AudioManager.play_sfx_varied("container_search", 0.1, -5.0)
```

### Loot Pickup Sound

**File**: `scripts/boarding/loot_menu.gd`

Plays when successfully transferring an item to inventory:

```gdscript
# In loot_menu.gd
if placed:
    # ...
    AudioManager.play_sfx_varied("loot_pickup", 0.2, -2.0)
    # ...
```

### Escape Sound

**File**: `scripts/boarding/exit_point.gd`

Plays when triggering escape:

```gdscript
# In exit_point.gd
func trigger_escape() -> void:
    # ...
    AudioManager.play_sfx("escape", 0.0)
    # ...
```

## Sound Design Notes

The current sound effects are **placeholder tones** generated programmatically:
- Each sound has a distinct frequency to make it recognizable
- Simple sine waves with fade in/out envelopes
- Designed to be easily replaced with custom audio

### Recommended Replacements

For production, consider replacing with:

1. **Airlock Sounds**: 
   - Heavy mechanical hissing and pressurization sounds
   - Duration: 0.5-0.8 seconds

2. **Footsteps**: 
   - Metal grating footsteps with slight echo
   - Very short (0.08-0.1 seconds)
   - Should sound good when repeated rapidly

3. **Container Sounds**:
   - Metal latches, creaking doors
   - Opening: 0.3-0.5 seconds
   - Searching: Rustling, rummaging sounds (0.2-0.4 seconds)

4. **Loot Pickup**: 
   - Satisfying "pop" or "click" with metallic tinge
   - Very short (0.1-0.2 seconds)

5. **Escape Sound**: 
   - Success chord or triumphant beep
   - Can be longer (0.5-1.0 seconds)

### Replacing Sound Files

To replace a sound:

1. Export your new sound as WAV format (44.1kHz recommended)
2. Replace the corresponding file in `assets/audio/sfx/boarding/`
3. Godot will automatically reimport the file
4. No code changes needed!

## Performance Considerations

- **Player Pool**: The AudioManager maintains a pool of 10 reusable AudioStreamPlayer nodes
- **Automatic Cleanup**: Players automatically return to pool when sounds finish
- **Limit Per Sound**: Maximum 3 simultaneous instances of the same sound
- **No Spatial Audio**: Current implementation uses 2D audio (non-positional)

## Future Enhancements

Potential improvements to consider:

1. **Spatial Audio**: Add 2D positional audio for distance-based volume
2. **Audio Bus Routing**: Separate buses for different categories (SFX, UI, Ambient)
3. **Music System**: Background music with cross-fading
4. **Sound Variations**: Multiple sound files per effect, randomly selected
5. **Environmental Reverb**: Different reverb based on room size
6. **Player Preferences**: In-game volume sliders with persistence

## Testing

The sound system can be tested by:

1. Playing through a boarding sequence
2. Listening for:
   - Door open/close sounds when passing through doors
   - Footsteps while moving (should vary in pitch)
   - Container opening when first interacting
   - Search sounds when searching containers
   - Pickup sound when dragging items to inventory
   - Escape sound when reaching exit

All sounds should play without errors and enhance the game feel.

## Troubleshooting

### Sounds Not Playing

1. Check that AudioManager is loaded as autoload in project.godot
2. Verify sound files exist in `assets/audio/sfx/boarding/`
3. Check Godot console for warnings about missing files
4. Ensure volume is not set to 0

### Sounds Too Loud/Quiet

Adjust volume in the specific play_sfx calls:
- Negative values (in dB) reduce volume: -6dB = half volume
- Positive values increase volume (use sparingly)

### Too Many Sounds Playing

The AudioManager automatically limits simultaneous sounds using a pool system. If you hear sounds being cut off, you may need to:
- Increase `MAX_PLAYERS_PER_SOUND` constant
- Increase initial pool size in `_create_player_pool()`

## Credits

Sound effects system designed and implemented for CargoEscape boarding/looting gameplay.

Placeholder sounds are programmatically generated sine waves and should be replaced with professional game audio for production use.
