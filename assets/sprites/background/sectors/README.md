# Sector Background Assets

This directory contains sector-specific background visual assets for different game sectors.

## Sector Types

### Trading Hub (CCG Territory)
- **Theme**: Warm, commercial, busy
- **Colors**: Orange, yellow, gold
- **Elements**: Cargo containers, station silhouettes, ship traffic
- **Mood**: Warm and active

### Danger Zone (NEX Territory)
- **Theme**: Dangerous, hostile
- **Colors**: Red, crimson, dark red
- **Elements**: Debris fields, destroyed ship wrecks, weapons fire
- **Mood**: Hostile and threatening

### Military Sector (GDF Territory)
- **Theme**: Clean, structured, organized
- **Colors**: Blue, white, cool tones
- **Elements**: Patrol ships, beacon lights, structured formations
- **Mood**: Clinical and orderly

### Tech Nexus (SYN Territory)
- **Theme**: High-tech, mysterious
- **Colors**: Cyan, teal, electric blue
- **Elements**: Satellite arrays, digital artifacts/glitches, energy streams
- **Mood**: Mysterious and technological

### Frontier (IND Territory)
- **Theme**: Chaotic, desolate
- **Colors**: Mixed colors, gray-green, dusty browns
- **Elements**: Asteroid belts, old equipment, sparse traffic
- **Mood**: Lonely and vast

## Asset Guidelines

When creating visual assets for sectors:

1. **Sprites**: Use PNG format with transparency
2. **Naming**: Use format `{sector}_{element}.png` (e.g., `ccg_cargo_container.png`)
3. **Size**: Keep sprites reasonably sized (typically 32x32 to 256x256)
4. **Color**: Match the sector's color palette defined in `sector_themes.gd`

## Usage

The `sector_themes.gd` script defines all color palettes and visual parameters.
Background scripts can use `SectorThemes.apply_theme_to_background()` to apply sector themes.

## Current Implementation

The sector themes are currently implemented procedurally (generated in code) using the `sector_themes.gd` script.
This directory is reserved for future sprite-based assets that can enhance the procedural backgrounds.

Future assets might include:
- Station silhouettes
- Ship sprites (various sizes)
- Debris pieces
- Asteroid sprites
- Cargo container sprites
- Satellite/beacon sprites
- Weapon fire effects
- Energy stream textures
