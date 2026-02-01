# Ambient Object Spawner System

## Overview
The ambient object spawner system brings the space environment to life with visual-only background objects that add atmosphere without affecting gameplay.

## Files

### Core Scripts
- `scripts/background/ambient_object.gd` - Base class for all ambient objects
- `scripts/background/ambient_spawner.gd` - Main spawner that manages object creation

### Scenes
- `scenes/background/ambient_spawner.tscn` - Ready-to-use spawner node
- `scenes/background/ambient_objects/base_ambient_object.tscn` - Base ambient object scene
- `scenes/background/ambient_demo.tscn` - Demo scene showing the system in action

## Features

### Object Types

#### Static/Slow Objects
- **Planets** - Various sizes and colors (desert, ocean, red, green, ice)
- **Moons** - Smaller gray satellites
- **Space Stations** - Background structures with lights
- **Asteroid Clusters** - Small groups of asteroids

#### Moving Objects
- **Ships** - Passing vessels with engine glows
- **Comets** - Objects with glowing tails
- **Satellites** - Rotating space equipment
- **Escape Pods** - Small capsules with distress lights

#### Rare Events (Low Frequency)
- **Distant Explosions** - Expanding flash effects (ship destroyed)
- **Jump Gate Activations** - Bright blue flash
- **Solar Flares** - Radiating light waves
- **Meteor Showers** - Multiple meteors with trails

### Performance Features
- **Max Concurrent Objects Limit** - Default: 15 objects
- **Distance-based Despawn** - Auto-cleanup when off-screen
- **No Collision Detection** - Visual only, no physics
- **Efficient Drawing** - Procedural graphics using draw calls

### Spawn System
- **Random Timers** - Different intervals for each object category
- **Off-screen Spawning** - Objects appear just outside viewport
- **Cross-screen Travel** - Movement based on velocity
- **Category-based Spawning** - Static, Moving, and Events spawn separately

## Usage

### Basic Setup

1. Add the ambient spawner to your scene:
```gdscript
# In your scene tree or via code
var spawner = preload("res://scenes/background/ambient_spawner.tscn").instantiate()
add_child(spawner)
```

2. Configure spawn rates (optional):
```gdscript
spawner.static_object_interval = 15.0   # Seconds between static spawns
spawner.moving_object_interval = 8.0    # Seconds between moving spawns
spawner.rare_event_interval = 45.0      # Seconds between events
```

3. Set screen size:
```gdscript
spawner.set_screen_size(Vector2(1280, 720))
```

4. Start spawning:
```gdscript
spawner.start_spawning()
```

### Integration with Main Game

Add the spawner as a child of your background or main scene:

```gdscript
# In your main scene's _ready() function
var ambient_spawner = preload("res://scenes/background/ambient_spawner.tscn").instantiate()
ambient_spawner.screen_size = get_viewport_rect().size
ambient_spawner.z_index = -50  # Behind gameplay elements
add_child(ambient_spawner)
ambient_spawner.start_spawning()
```

### Custom Object Scenes

You can replace procedural objects with custom scenes:

```gdscript
# In the Inspector or via code
spawner.planet_scenes = [
    preload("res://scenes/custom/desert_planet.tscn"),
    preload("res://scenes/custom/ice_planet.tscn")
]
spawner.ship_scenes = [
    preload("res://scenes/custom/freighter.tscn")
]
```

## Configuration

### Export Variables

#### Container
- `object_container` - Node2D to spawn into (auto-created if null)

#### Spawn Settings
- `screen_size` - Viewport dimensions (Vector2)
- `spawn_margin` - How far off-screen to spawn (float, default: 100)

#### Performance
- `max_concurrent_objects` - Max active objects (int, default: 15)
- `spawning_enabled` - Enable/disable spawning (bool, default: true)

#### Spawn Rates
- `static_object_interval` - Seconds between static spawns (float, default: 15.0)
- `moving_object_interval` - Seconds between moving spawns (float, default: 8.0)
- `rare_event_interval` - Seconds between events (float, default: 45.0)

#### Object Scenes (Optional)
- `planet_scenes` - Array of planet PackedScenes
- `moon_scenes` - Array of moon PackedScenes
- `station_scenes` - Array of station PackedScenes
- `ship_scenes` - Array of ship PackedScenes
- `comet_scenes` - Array of comet PackedScenes
- `event_scenes` - Array of event PackedScenes

## API Reference

### AmbientSpawner

#### Methods

```gdscript
func start_spawning() -> void
```
Starts the spawning timers.

```gdscript
func stop_spawning() -> void
```
Stops all spawning.

```gdscript
func clear_all_objects() -> void
```
Removes all active ambient objects.

```gdscript
func set_screen_size(size: Vector2) -> void
```
Updates the screen dimensions for spawn positioning.

#### Signals

```gdscript
signal object_spawned(obj: AmbientObject)
```
Emitted when any ambient object is spawned.

### AmbientObject

#### Properties

- `velocity` - Movement vector (Vector2)
- `rotation_speed` - Rotation rate in radians/sec (float)
- `object_type` - Type from ObjectType enum
- `visual_scale` - Size multiplier (float)
- `base_color` - Tint color (Color)
- `despawn_distance` - Off-screen distance before removal (float)

#### Methods

```gdscript
func set_velocity(new_velocity: Vector2) -> void
```
Updates the object's velocity.

```gdscript
func despawn() -> void
```
Manually despawn the object.

```gdscript
func is_active() -> bool
```
Check if object is still active.

## Performance Tips

1. **Limit concurrent objects** - Keep max_concurrent_objects around 10-15
2. **Increase intervals** - Longer spawn intervals reduce object density
3. **Disable events** - Set rare_event_interval very high if not needed
4. **Custom scenes** - Use simple sprites instead of complex scenes
5. **Z-index** - Keep spawner at negative z-index (e.g., -50)

## Troubleshooting

### Objects not appearing
- Check `spawning_enabled` is true
- Verify `screen_size` matches your viewport
- Ensure spawner is added to scene tree
- Check `max_concurrent_objects` hasn't been reached

### Performance issues
- Reduce `max_concurrent_objects`
- Increase spawn intervals
- Disable rare events
- Use procedural graphics instead of custom scenes

### Objects not despawning
- Verify `despawn_distance` is set appropriately
- Check that cleanup is running in `_process`
- Ensure objects aren't stuck in parent node

## Demo

Run `scenes/background/ambient_demo.tscn` to see the system in action!

## Future Enhancements

Potential improvements:
- Distance-based object scaling (parallax depth)
- Sound effects for events
- Custom particle effects for comets/explosions
- Faction-specific ship designs
- Weather effects (space dust storms)
- Dynamic spawn rates based on game state
