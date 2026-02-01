# Ship Decoration System Documentation

## Overview

The ship decoration system provides a comprehensive solution for placing decorative objects in procedurally generated ship interiors. It enhances the visual appeal and atmosphere of ships while respecting faction themes, room types, and ship conditions.

## Architecture

The decoration system consists of three main components:

### 1. DecorationData (`resources/decorations/decoration_data.gd`)

This is a data-only class that defines all available decoration types and their properties.

**Decoration Categories:**
- **Functional**: Computer screens, control panels, pipes, vents, lights
- **Atmospheric**: Posters, plants, personal items, cargo stacks, tool racks  
- **Damage/Wear**: Scorch marks, cracks, flickering lights, sparks, blood stains

**Key Classes:**
- `Decoration`: Defines a decoration type with properties like size, color, layer, and room tags
- `DecorationPlacement`: Represents a placed decoration instance with position, rotation, and tint
- `DecorationPool`: Groups decorations for specific factions or room types

**Usage Example:**
```gdscript
# Get all functional decorations
var functional_decos = DecorationData.get_decorations_by_category(
    DecorationData.Category.FUNCTIONAL
)

# Get decorations suitable for a bridge
var bridge_decos = DecorationData.get_decorations_for_room("bridge")

# Get specific decoration
var screen = DecorationData.get_decoration(
    DecorationData.Type.COMPUTER_SCREEN
)
```

### 2. ShipDecorator (`scripts/boarding/ship_decorator.gd`)

The DecorationPlacer class that generates decoration placements based on room type, faction, and ship tier.

**Key Features:**
- Room-type specific decoration density
- Faction-themed decoration selection
- Automatic wear level calculation based on ship tier
- Category mix ratios per room type
- Smart placement avoiding overlaps

**Density Settings:**
Configurable per room type (0.0 to 1.0):
- Bridge: 0.8
- Engine Room: 0.9
- Cargo Bay: 0.6
- Corridor: 0.4
- etc.

**Category Mix:**
Each room type has a mix ratio for different decoration categories:
- Engine Room: 80% functional, 10% atmospheric, 10% damage
- Crew Quarters: 30% functional, 65% atmospheric, 5% damage
- etc.

**Usage Example:**
```gdscript
var decorator = ShipDecorator.new()

# Generate decorations for a single room
var decorations = decorator.generate_room_decorations(
    Rect2(100, 100, 400, 300),  # room_rect
    "bridge",                    # room_type
    Factions.Type.NEX,          # faction
    3,                          # ship_tier
    12345                       # seed
)

# Generate for multiple rooms
var rooms = [
    {"rect": Rect2(100, 100, 400, 300), "type": "bridge"},
    {"rect": Rect2(500, 100, 300, 400), "type": "engine_room"}
]
var all_decorations = decorator.generate_ship_decorations(
    rooms,
    Factions.Type.GDF,
    4,
    54321
)

# Manual wear level
decorator.set_wear_level(0.7)  # Heavily damaged
```

### 3. ShipDecorations (`scripts/boarding/ship_decorations.gd`)

The rendering component that draws decorations on screen. Enhanced to support both legacy and new decoration systems.

**Key Features:**
- Layered rendering (floor to ceiling)
- Animation support for flickering lights and sparks
- Faction color tinting
- Glow effects for lights and screens
- Damage visualization

**Usage Example:**
```gdscript
# Create decorations node
var decorations_node = ShipDecorations.new()
add_child(decorations_node)

# Set faction colors
decorations_node.set_colors(
    floor_color,
    wall_color,
    accent_color
)

# Add enhanced decorations from decorator
decorations_node.set_enhanced_decorations(placements)

# Or add legacy decorations
decorations_node.generate_for_room(
    room_rect,
    "cargo_bay",
    seed
)
```

## Integration with Ship Generator

The `ShipGenerator` class now automatically generates decorations for all rooms during ship generation:

```gdscript
# Generate a ship (decorations are automatically included)
var layout = ShipGenerator.generate(
    tier: 3,
    faction_type: Factions.Type.CCG,
    seed: 98765
)

# Access decoration placements
for room_idx in layout.decoration_placements:
    var decos = layout.decoration_placements[room_idx]
    print("Room %d has %d decorations" % [room_idx, decos.size()])
```

The `GeneratedLayout` class now includes:
- `decoration_placements: Dictionary` - Maps room index to array of DecorationPlacement objects

Each `RoomInstance` also stores its decorations:
- `decoration_placements: Array` - Array of DecorationPlacement for the room

## Decoration Types Reference

### Functional Decorations (16 types)
- Computer screens (static and animated)
- Control panels (small and large)
- Pipes (horizontal, vertical, corner, junction)
- Ventilation (shafts and vents)
- Lights (ceiling, wall, floor, glow)
- Conduits and wiring

### Atmospheric Decorations (24 types)
- Posters (generic, warning, motivational, faction-specific)
- Signs (exit, caution, restricted)
- Plants (small, large, dead)
- Personal items (photos, mementos, lockers)
- Cargo (crate stacks, barrel groups)
- Tools (racks, boxes)
- Safety equipment (fire extinguishers, medkits)

### Damage/Wear Decorations (15 types)
- Scorch marks (small, large)
- Cracks (wall, floor, ceiling)
- Electrical damage (flickering lights, sparking electronics/wires)
- Blood stains (small, large, splatter)
- Corrosion (rust patches)
- Structural damage (dents, broken panels, leaking pipes)

## Faction-Themed Decorations

Each faction has specific posters:
- CCG: Civilian Commerce Guild posters
- NEX: Nexus Corporation posters
- GDF: Galactic Defense Force posters
- SYN: Shadow Syndicate posters
- IND: Independent Traders posters

The decorator automatically selects appropriate faction posters based on the ship's faction type.

## Room Type Tags

Decorations can be tagged for specific room types to ensure appropriate placement:

Common room tags:
- `bridge`, `engine_room`, `cargo_bay`, `storage`
- `crew_quarters`, `med_bay`, `armory`, `lab`
- `server_room`, `corridor`, `entry_airlock`, `exit_airlock`
- `vault`, `executive_suite`, `conference`, `barracks`
- `supply_room`, `contraband_hold`

## Customization

### Adding New Decoration Types

1. Add enum value to `DecorationData.Type`
2. Create decoration instance in `_define_decorations()`
3. Add rendering logic in `ShipDecorations._draw_enhanced_decoration()`

Example:
```gdscript
# In decoration_data.gd
enum Type {
    # ... existing types ...
    MY_NEW_DECORATION
}

# In _define_decorations()
var my_deco = Decoration.new(
    Type.MY_NEW_DECORATION,
    Category.ATMOSPHERIC,
    "My Decoration",
    Vector2(30, 30),
    "Description"
)
my_deco.room_type_tags = ["cargo_bay", "storage"]
_decorations[Type.MY_NEW_DECORATION] = my_deco

# In ship_decorations.gd _draw_atmospheric_decoration()
DecorationDataClass.Type.MY_NEW_DECORATION:
    _draw_my_decoration(pos, size, mod_color)
```

### Adjusting Density

Modify `ROOM_DENSITY_SETTINGS` in `ship_decorator.gd`:

```gdscript
const ROOM_DENSITY_SETTINGS = {
    "my_custom_room": 0.75,  # Add your room type
    # ... existing settings ...
}
```

### Adjusting Category Mix

Modify `ROOM_CATEGORY_MIX` in `ship_decorator.gd`:

```gdscript
const ROOM_CATEGORY_MIX = {
    "my_custom_room": {
        "functional": 0.6,
        "atmospheric": 0.3,
        "damage": 0.1
    },
    # ... existing settings ...
}
```

## Performance Considerations

- Decorations are generated once during ship generation
- Drawing is layered and optimized
- Animations are only processed when enhanced decorations are present
- Placement uses spatial hashing to avoid overlaps efficiently

## Best Practices

1. **Use appropriate density**: Don't overload small rooms
2. **Respect room themes**: Use room tags to filter decorations
3. **Consider faction**: Use faction-specific decorations for immersion
4. **Balance categories**: Mix functional, atmospheric, and damage decorations
5. **Seed consistency**: Use consistent seeds for reproducible layouts
6. **Test visually**: Preview decorations in different room types

## Testing

A validation script is provided: `validate_decoration_system.gd`

Run with Godot:
```bash
godot --headless --script validate_decoration_system.gd
```

This validates:
- DecorationData initialization
- ShipDecorator generation
- Full ship generation with decorations
- Density and category distribution

## Future Enhancements

Potential additions to the system:
- Dynamic decoration based on ship state (damaged/pristine)
- Interactive decorations (screens showing data, switches)
- Decoration-based storytelling (crew personal items)
- Seasonal/event decorations
- Procedural decoration variations
- Physics-based decorations (hanging cables, floating debris)
