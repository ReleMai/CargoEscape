# Sector-Themed Background Variations

This implementation adds unique background themes for different game sectors, aligned with faction territories.

## Overview

The sector background system provides visual variety for different areas of the game, with each sector having a unique color palette, atmosphere, and environmental elements that match the controlling faction.

## Files Created

### Core Implementation

1. **`resources/backgrounds/sector_themes.gd`** (Main Implementation)
   - Defines 5 sector themes (CCG, NEX, GDF, SYN, IND)
   - Contains color palettes for nebulae and stars
   - Defines environmental elements and effects
   - Provides API for theme access and application

2. **`resources/backgrounds/sector_background.gd`** (Example/Usage)
   - Example background script that uses sector themes
   - Shows how to integrate themes with existing background systems
   - Procedurally generates stars and nebulae with theme colors

3. **`resources/backgrounds/sector_theme_demo.gd`** (Demo)
   - Demonstration script that cycles through all 5 themes
   - Useful for testing and showcasing the themes
   - Can be attached to a Node2D to see themes in action

4. **`resources/backgrounds/validate_sector_themes.gd`** (Validation)
   - Automated validation script for testing themes
   - Checks that all themes are properly configured
   - Verifies theme differentiation

### Documentation

5. **`assets/sprites/background/sectors/README.md`**
   - Documents the asset structure for sectors
   - Provides guidelines for future sprite assets
   - Explains the color palettes and design intent

## Sector Themes

### 1. Trading Hub (CCG Territory)
- **Colors**: Warm orange, yellow, gold (`#BF9B30`)
- **Nebula**: Dark orange-brown to light yellow-orange (4 color variations)
- **Stars**: Warm white to golden tones (4 color variations)
- **Atmosphere**: Busy, commercial
- **Mood**: Warm and active
- **Features**: High ship traffic (0.8), cargo containers, station silhouettes
- **Visual Intent**: Bustling commercial hub with warm lighting from trade activity

### 2. Danger Zone (NEX Territory)
- **Colors**: Red, crimson, dark red (`#CC3333`)
- **Nebula**: Dark red to crimson (4 color variations)
- **Stars**: Red-tinted white to red-orange (4 color variations)
- **Atmosphere**: Dangerous
- **Mood**: Hostile and threatening
- **Features**: Heavy debris (0.7), ship wrecks, occasional weapons fire
- **Visual Intent**: Hostile territory with battle damage and danger

### 3. Military Sector (GDF Territory)
- **Colors**: Blue, white, cool tones
- **Nebula**: Dark blue to light blue (4 color variations, low density)
- **Stars**: Cool white to blue-white (4 color variations)
- **Atmosphere**: Structured, organized
- **Mood**: Clinical and orderly
- **Features**: Patrol ships (0.5), beacon lights, structured formations
- **Visual Intent**: Clean, organized military space with minimal clutter

### 4. Tech Nexus (SYN Territory)
- **Colors**: Cyan, teal, electric blue (`#00D9E0`)
- **Nebula**: Dark teal to bright cyan (4 color variations)
- **Stars**: Cyan-white to electric cyan (4 color variations)
- **Atmosphere**: Structured, high-tech
- **Mood**: Mysterious and technological
- **Features**: Satellite arrays, energy streams, digital artifacts
- **Visual Intent**: High-tech zone with cyberpunk aesthetic

### 5. Frontier (IND Territory)
- **Colors**: Mixed (gray-green, dusty brown) (`#88CC88`, `#6B7080`)
- **Nebula**: Brown-gray to dusty mixed colors (5 color variations for chaos)
- **Stars**: Dusty white to off-white (5 color variations)
- **Atmosphere**: Chaotic
- **Mood**: Lonely and vast
- **Features**: Asteroid belts, old equipment, sparse traffic (0.2)
- **Visual Intent**: Desolate frontier with mixed debris and minimal activity

## Integration with Existing Code

### Faction Color Alignment

The themes are aligned with existing faction colors from `scripts/data/factions.gd`:

- **CCG**: Hull `#8C6B4F`, Accent `#BF9B30` → Warm orange/yellow theme
- **NEX**: Hull `#E8E8EC`, Accent `#D4AF37` → Red theme (danger zone)
- **GDF**: Hull `#40444C`, Accent `#CC3333` → Blue/white clean theme
- **SYN**: Hull `#141418`, Accent `#00D9E0` → Cyan/teal theme
- **IND**: Hull `#6B7080`, Accent `#88CC88` → Mixed gray-green theme

### Using Sector Themes

#### Option 1: With Existing Background Script

```gdscript
# In your background script
var theme = SectorThemes.get_theme("CCG")
SectorThemes.apply_theme_to_background(background_node, "CCG")
```

#### Option 2: With New Sector Background Script

```gdscript
# Create a Node2D with sector_background.gd
var bg = Node2D.new()
bg.set_script(load("res://resources/backgrounds/sector_background.gd"))
bg.set_sector_theme("NEX")  # Danger Zone theme
add_child(bg)
```

#### Option 3: Manual Color Access

```gdscript
# Get specific colors
var rng = RandomNumberGenerator.new()
var star_color = SectorThemes.get_random_star_color("GDF", rng)
var nebula_color = SectorThemes.get_random_nebula_color("SYN", rng)
```

## API Reference

### SectorThemes Static Methods

- `get_theme(faction_code: String) -> SectorTheme`
  - Returns theme for given faction code (CCG, NEX, GDF, SYN, IND)

- `get_all_themes() -> Dictionary`
  - Returns all themes as a dictionary

- `get_theme_names() -> Array[String]`
  - Returns array of sector names

- `apply_theme_to_background(background: Node, faction_code: String) -> void`
  - Applies theme to a background node (if it has compatible methods)

- `get_random_star_color(faction_code: String, rng: RandomNumberGenerator = null) -> Color`
  - Returns a random star color from the theme's palette

- `get_random_nebula_color(faction_code: String, rng: RandomNumberGenerator = null) -> Color`
  - Returns a random nebula color from the theme's palette

### SectorTheme Properties

- `sector_name: String` - Display name (e.g., "Trading Hub")
- `faction_code: String` - Faction code (CCG, NEX, GDF, SYN, IND)
- `nebula_colors: Array[Color]` - Palette of nebula colors
- `star_colors: Array[Color]` - Palette of star colors
- `ambient_color: Color` - Background ambient color
- `glow_color: Color` - Glow effect color
- `has_*: bool` - Feature flags (debris, ships, stations, etc.)
- `*_density: float` - Density values (0.0 to 1.0)
- `atmosphere: String` - Atmosphere type
- `mood: String` - Emotional mood

## Testing

### Manual Testing

1. Create a test scene with a Node2D
2. Attach `sector_theme_demo.gd` to it
3. Run the scene - it will cycle through all themes every 5 seconds
4. Press SPACE to manually cycle, or 1-5 to jump to specific themes

### Automated Validation

Run the validation script (requires Godot headless mode):
```bash
godot --headless --script resources/backgrounds/validate_sector_themes.gd
```

The validation checks:
- All themes exist
- Required properties are set
- Colors are different between themes
- Helper functions work correctly

## Future Enhancements

### Sprite Assets

The `assets/sprites/background/sectors/` directory is ready for sprite-based assets:
- Station silhouettes (for CCG)
- Debris pieces (for NEX, IND)
- Ship sprites (various factions)
- Asteroid sprites (for IND)
- Satellite sprites (for SYN)
- Beacon lights (for GDF)

### Environmental Effects

Future enhancements could include:
- Animated weapons fire particles (NEX)
- Moving patrol ship silhouettes (GDF)
- Energy stream particle effects (SYN)
- Floating cargo containers (CCG, IND)
- Glitch effects for digital artifacts (SYN)

### Dynamic Transitions

- Smooth color transitions when moving between sectors
- Blend zones at sector boundaries
- Distance-based theme intensity

## Design Philosophy

The implementation follows these principles:

1. **Procedural Generation**: Currently uses code-generated visuals for zero asset dependencies
2. **Extensible**: Easy to add sprite assets in the future
3. **Faction-Aligned**: Colors match existing faction themes
4. **Performance**: Lightweight procedural generation
5. **Modular**: Self-contained theme system that can be used anywhere

## Compatibility

- **Godot Version**: 4.x (uses typed GDScript syntax)
- **Dependencies**: None (self-contained)
- **Integration**: Works with existing background scripts via `apply_theme_to_background()`
