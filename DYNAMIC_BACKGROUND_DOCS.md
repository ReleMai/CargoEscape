# Dynamic Space Background System

## Overview

The Dynamic Space Background System is a high-performance, multi-layered parallax scrolling system designed for space-themed games in Godot 4.x. It uses GPU shaders for efficient rendering and provides extensive customization options.

## Architecture

### Core Components

1. **DynamicBackground** (`scripts/background/dynamic_background.gd`)
   - Main manager class that orchestrates all background layers
   - Handles theme switching, scrolling, and random events
   - Manages 6 distinct parallax layers

2. **ParallaxLayer** (`scripts/background/parallax_layer.gd`)
   - Individual scrolling layer with shader support
   - Configurable speed multiplier for parallax effect
   - Runtime parameter updates

3. **StarFieldShader** (`shaders/star_field.gdshader`)
   - GPU-accelerated procedural star generation
   - Twinkling animation
   - Parallax scrolling support
   - Color theming

## The 6 Layers

1. **Far Stars** (0.1x speed)
   - Barely moving background stars
   - Smallest size, lowest density
   - Creates depth perception

2. **Nebula** (0.2x speed)
   - Slow color-shifting clouds
   - Colored transparent overlays
   - Theme-based colors

3. **Mid Stars** (0.5x speed)
   - Main parallax star layer
   - Medium density and size
   - Most visible layer

4. **Planets** (0.3x speed)
   - Occasional large celestial objects
   - Procedurally placed
   - Adds visual interest

5. **Near Particles** (1.0x speed)
   - Fast-moving dust/debris
   - Creates motion feeling
   - Higher density

6. **Foreground Effects** (1.5x speed)
   - Asteroids, ships, etc.
   - Fastest moving layer
   - Optional events

## Features

### Parallax Scrolling
- Based on player movement or auto-scroll
- Each layer moves at different speed
- Configurable scroll direction
- Smooth, continuous motion

### Procedural Star Placement
- GPU-based generation using noise functions
- No texture files required
- Infinite variation
- Twinkling animation

### Color Themes
5 built-in color themes per sector/area:
- **Blue**: Classic space (default)
- **Purple**: Mysterious nebula region
- **Orange**: Near-star systems
- **Green**: Exotic alien space
- **Red**: Danger zones

### Day/Night Cycle Simulation
- Gradual lighting shifts
- Configurable cycle duration
- Affects all layers simultaneously

### Random Events
- Comet flyby
- Distant explosion
- Ship silhouette
- Configurable frequency

### Performance Optimizations
- **Shader-based stars**: GPU rendering for thousands of stars
- **Object pooling**: Reuse particle objects
- **LOD support**: Reduce detail for distant objects
- **Efficient wrapping**: Seamless layer tiling

## Usage

### Basic Setup

```gdscript
# Create a new DynamicBackground instance
var background = DynamicBackground.new()
add_child(background)

# Configure basic settings
background.base_scroll_speed = 50.0
background.auto_scroll = true
background.color_theme = "Blue"
```

### In a Scene (TSCN)

```
[node name="DynamicBackground" type="Node2D"]
script = ExtResource("path/to/dynamic_background.gd")
base_scroll_speed = 50.0
auto_scroll = true
color_theme = "Blue"
enable_far_stars = true
enable_nebula = true
enable_mid_stars = true
enable_planets = true
enable_near_particles = true
enable_foreground = true
```

### Runtime Control

```gdscript
# Change theme
background.change_theme("Purple")

# Set scroll speed from player movement
background.set_scroll_speed(player_velocity.x)

# Toggle day/night cycle
background.enable_day_night_cycle = true
background.cycle_duration = 120.0  # 2 minutes

# Enable/disable layers
background.set_layer_enabled("nebula", false)

# Reset everything
background.reset()
```

### Signals

```gdscript
# Listen for events
background.theme_changed.connect(_on_theme_changed)
background.random_event_triggered.connect(_on_random_event)

func _on_theme_changed(theme_name: String) -> void:
    print("Theme changed to: ", theme_name)

func _on_random_event(event_type: String) -> void:
    print("Random event: ", event_type)
    # Could trigger sound effects, visual effects, etc.
```

## Integration with Existing Systems

### With Game Manager

```gdscript
# In your main game scene
var background = DynamicBackground.new()
add_child(background)

# Link to player movement
func _process(delta):
    var player_speed = player.velocity.length()
    background.set_scroll_speed(player_speed * 0.5)
```

### With Space Scrolling Manager

```gdscript
# Replace or complement existing background
func _ready():
    var old_background = $Background
    if old_background:
        old_background.queue_free()
    
    var new_background = DynamicBackground.new()
    add_child(new_background)
    
    # Sync with scrolling manager
    new_background.set_scroll_speed(space_scrolling_manager.get_scroll_speed())
```

## Customization

### Creating Custom Themes

```gdscript
# Add to COLOR_THEMES dictionary in dynamic_background.gd
const COLOR_THEMES = {
    # ... existing themes ...
    "Custom": {
        "far_stars": Color(1.0, 0.5, 0.5),      # Reddish far stars
        "nebula": Color(0.5, 0.1, 0.1, 0.15),   # Red nebula
        "mid_stars": Color(1.0, 0.7, 0.7),      # Pink-ish stars
        "ambient": Color(0.15, 0.05, 0.05)      # Dark red ambient
    }
}
```

### Custom Shader Parameters

```gdscript
# Access layer and modify shader
var mid_star_layer = background.layers["mid_stars"]
if mid_star_layer is ParallaxLayer:
    mid_star_layer.set_star_density(100.0)  # More stars
    mid_star_layer.twinkle_speed = 5.0      # Faster twinkling
```

### Adding Custom Events

```gdscript
# Extend _trigger_random_event() in dynamic_background.gd
func _trigger_random_event() -> void:
    var events = ["comet", "explosion", "ship_flyby", "asteroid_field"]
    var event_type = events[randi() % events.size()]
    
    match event_type:
        "asteroid_field":
            _spawn_asteroid_field()
        # ... other cases ...
```

## Performance Considerations

### Recommended Settings

**Low-end devices:**
```gdscript
background.use_shaders = false  # Fallback to procedural
background.enable_planets = false
background.enable_foreground = false
background.star_density = 30.0  # Lower density
```

**High-end devices:**
```gdscript
background.use_shaders = true
background.enable_lod = true
# All layers enabled
background.star_density = 80.0  # Higher density
background.enable_random_events = true
```

### Optimization Tips

1. **Use shaders when possible** - GPU rendering is much faster
2. **Disable unused layers** - Don't enable layers you don't need
3. **Adjust density** - Fewer stars = better performance
4. **LOD for distant objects** - Automatically reduces detail
5. **Pool particles** - Reuse objects instead of creating new ones

## Testing

A test scene is provided at `scenes/background/dynamic_background_test.tscn`

### Test Controls:
- **1-5**: Change color theme
- **SPACE**: Toggle auto-scroll
- **UP/DOWN**: Adjust scroll speed
- **T**: Toggle day/night cycle
- **E**: Trigger random event
- **R**: Reset background

## API Reference

### DynamicBackground

#### Properties
- `base_scroll_speed: float` - Base scrolling speed in pixels/second
- `auto_scroll: bool` - Enable automatic scrolling
- `scroll_direction: Vector2` - Direction of scroll (normalized)
- `color_theme: String` - Current color theme name
- `enable_day_night_cycle: bool` - Enable day/night lighting cycle
- `cycle_duration: float` - Duration of day/night cycle in seconds
- `enable_random_events: bool` - Enable random background events
- `event_interval: float` - Average time between events in seconds
- `use_shaders: bool` - Use GPU shaders for star rendering
- `enable_lod: bool` - Enable level-of-detail optimizations

#### Methods
- `set_scroll_speed(speed: float)` - Set scroll speed from external source
- `use_auto_scroll()` - Return to automatic scrolling mode
- `get_current_speed() -> float` - Get current effective scroll speed
- `change_theme(theme_name: String)` - Change color theme
- `apply_theme(theme_name: String)` - Apply theme (internal)
- `reset()` - Reset all layers to initial state
- `set_layer_enabled(layer_name: String, enabled: bool)` - Enable/disable layer
- `resize_to_viewport()` - Resize to match viewport

#### Signals
- `theme_changed(theme_name: String)` - Emitted when theme changes
- `random_event_triggered(event_type: String)` - Emitted on random events

### ParallaxLayer

#### Properties
- `speed_multiplier: float` - Speed relative to base scroll speed
- `draw_order: int` - Z-index for layer ordering
- `opacity: float` - Layer opacity (0-1)
- `content_type: String` - Type of content ("Stars", "Nebula", etc.)
- `use_shader: bool` - Use shader for rendering
- `star_density: float` - Star density for shader
- `star_color: Color` - Base star color

#### Methods
- `update_scroll(delta_position: Vector2)` - Update scroll by delta
- `set_scroll_offset(offset: Vector2)` - Set absolute scroll offset
- `reset_scroll()` - Reset scroll to zero
- `set_layer_opacity(opacity: float)` - Set layer opacity
- `get_scroll_offset() -> Vector2` - Get current scroll offset
- `set_star_density(density: float)` - Update star density
- `set_star_color(color: Color)` - Update star color
- `resize_to_viewport()` - Resize to viewport

## File Structure

```
CargoEscape/
├── scripts/
│   └── background/
│       ├── dynamic_background.gd     # Main manager
│       ├── parallax_layer.gd         # Layer component
│       └── test_controller.gd        # Test scene controller
├── shaders/
│   └── star_field.gdshader           # Star field shader
└── scenes/
    └── background/
        └── dynamic_background_test.tscn  # Test scene
```

## License

Part of the CargoEscape project. Use according to project license.
