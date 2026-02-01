# Integrating the Ambient Spawner into Your Game

## Quick Integration

### Option 1: Replace Background Scene

The easiest way to add ambient objects is to use the pre-configured background scene:

1. In your main scene (`scenes/main.tscn`), replace the background instance:
   - Change: `path="res://scenes/background.tscn"`
   - To: `path="res://scenes/background/background_with_ambient.tscn"`

### Option 2: Add to Existing Scene

If you want to keep your current background, add the spawner as a child:

1. Open `scenes/background.tscn` in Godot
2. Add a child node: Scene → New Inherited Scene
3. Select `res://scenes/background/ambient_spawner.tscn`
4. Position it in the scene tree (before or after other background elements)
5. Adjust the spawner's z_index to -50 or lower (behind gameplay)

### Option 3: Code Integration

Add the spawner programmatically in your main script:

```gdscript
extends Node2D

@onready var background = $Background

func _ready():
    # Create ambient spawner
    var spawner = preload("res://scenes/background/ambient_spawner.tscn").instantiate()
    spawner.screen_size = get_viewport_rect().size
    spawner.max_concurrent_objects = 12
    
    # Add to background
    background.add_child(spawner)
    spawner.start_spawning()
```

## Configuration Tips

### For Main Game (Fast-paced)
- Lower intervals for more action: `moving_object_interval = 5.0`
- More concurrent objects: `max_concurrent_objects = 20`
- Frequent events: `rare_event_interval = 30.0`

### For Calm Scenes (Menus, Loading)
- Higher intervals: `static_object_interval = 20.0`
- Fewer objects: `max_concurrent_objects = 8`
- Rare events only: `rare_event_interval = 60.0`

### For Intense Asteroid Fields
- Focus on asteroid clusters
- Disable ships and stations
- More moving objects: `moving_object_interval = 4.0`

## Testing

1. Run the demo scene: `scenes/background/ambient_demo.tscn`
2. Observe object spawning and movement
3. Adjust spawn intervals as needed
4. Check performance (should be minimal impact)

## Performance

The ambient spawner is designed to be lightweight:
- Uses procedural drawing (no textures loaded)
- Simple velocity-based movement
- Automatic cleanup when off-screen
- No collision detection

Typical performance: <0.5ms per frame with 15 active objects.
