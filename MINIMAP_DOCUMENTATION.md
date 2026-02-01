# Minimap System Documentation

## Overview
The minimap provides real-time navigation assistance during ship boarding missions. It displays the ship's layout, player position, container locations, and the exit point.

## Components

### 1. MinimapRenderer (`scripts/boarding/minimap_renderer.gd`)
The core rendering logic for the minimap. This Node2D uses Godot's custom drawing API to render:
- Ship room layouts
- Player position (green triangle)
- Container locations (yellow = unsearched, gray = searched)
- Exit point (cyan pulsing diamond)
- Fog of war (dark areas that haven't been explored)

**Key Features:**
- Automatic scaling to fit different ship sizes
- Fog of war reveals areas as the player explores
- Real-time updates every frame
- Efficient memory management (limits explored positions to prevent growth)

### 2. Minimap Scene (`scenes/boarding/minimap.tscn`)
A UI component that packages the renderer in a SubViewport:
- **PanelContainer**: Provides visual border and background
- **SubViewport**: Renders the minimap independently from the main game view
- **MinimapRenderer**: The actual drawing logic

### 3. Integration with BoardingManager
The BoardingManager handles all minimap updates:
- `_setup_minimap()`: Initializes minimap with layout data during ship generation
- `_update_minimap()`: Updates player position every frame
- `_update_minimap_containers()`: Refreshes container states
- `_mark_container_searched()`: Marks containers as searched when opened

## Usage

### In the Scene
The minimap is positioned in the top-right corner of the UI in `boarding_scene.tscn`:
```
[node name="Minimap" parent="UI" instance=ExtResource("7_minimap")]
unique_name_in_owner = true
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -220.0
offset_top = 60.0
offset_right = -10.0
offset_bottom = 260.0
grow_horizontal = 0
```

### Customization
You can adjust minimap appearance through the MinimapRenderer's exported properties:
- `minimap_scale`: Zoom level (default: 0.08)
- `exploration_radius`: How far around the player is revealed (default: 200)
- `fog_color`: Color of unexplored areas
- `room_color`: Color of explored rooms
- `player_color`: Color of player indicator
- `exit_color`: Color of exit marker
- `container_unsearched_color`: Color for unsearched containers
- `container_searched_color`: Color for searched containers

## Technical Details

### Fog of War System
The fog of war uses a simple distance-based approach:
1. Player positions are stored as they move
2. Rooms are considered "explored" if any stored position is within `exploration_radius`
3. Only explored rooms and their contents are drawn
4. Player position is always visible

### Performance Optimization
- Explored positions are sampled (only stored if >20 units from last position)
- Maximum 1000 explored positions stored (oldest are removed)
- SubViewport renders independently, not impacting main game performance
- Drawing only happens when `queue_redraw()` is called

### Coordinate System
The minimap uses the same coordinate system as the game world but scaled down:
- All positions are multiplied by `minimap_scale` (default: 0.08)
- Layout offset is accounted for when updating player position
- Container positions are in local coordinates relative to the Containers node

## Future Enhancements
Potential improvements:
- Room names displayed on minimap
- Zoom in/out functionality
- Toggle minimap visibility with a key press
- Different markers for different container types
- Path highlighting to nearest unsearched container
- Minimap rotation to match player facing
