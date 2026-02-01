# Item Rarity Visual Effects

This document describes the visual effects system for item rarities in Cargo Escape.

## Rarity Tiers and Effects

### Common (Rarity 0)
- **Effect**: None
- **Description**: Basic items with no special visual effects

### Uncommon (Rarity 1)
- **Effect**: Subtle glow
- **Implementation**: Shader-based glow effect with gentle pulsing
- **Shader**: `resources/shaders/glow_effect.gdshader`
- **Features**:
  - Gentle pulsing animation
  - Edge-based glow (stronger at edges)
  - Green tint by default

### Rare (Rarity 2)
- **Effect**: Blue shimmer effect
- **Implementation**: Shader-based shimmer animation
- **Shader**: `resources/shaders/shimmer_effect.gdshader`
- **Features**:
  - Horizontal shimmer wave moving across the item
  - Diagonal shimmer for visual interest
  - Blue tint by default

### Epic (Rarity 3)
- **Effect**: Purple pulsing glow
- **Implementation**: AnimationPlayer-based alpha animation
- **Features**:
  - Smooth pulsing between 0.2 and 0.5 alpha
  - 2-second loop cycle
  - Purple tint by default

### Legendary (Rarity 4)
- **Effect**: Gold particle effect with shine
- **Implementation**: GPUParticles2D + AnimationPlayer
- **Features**:
  - Gold particles floating upward
  - Background glow with pulsing shine effect
  - 20 particles with 2-second lifetime
  - 3-second shine animation cycle
  - Gold tint by default

## Technical Implementation

### File Structure
```
resources/shaders/
  - glow_effect.gdshader      # Uncommon glow shader
  - shimmer_effect.gdshader   # Rare shimmer shader

scripts/loot/
  - item_visuals.gd           # Main visual effects logic
  - item_data.gd              # Rarity definitions
  - loot_item.gd              # Item display logic
```

### Key Functions in item_visuals.gd

1. `_add_rarity_effects(container, width, height, color, rarity)` - Main dispatcher
2. `_add_uncommon_glow(container, width, height, color)` - Uncommon shader effect
3. `_add_rare_shimmer(container, width, height, color)` - Rare shimmer shader
4. `_add_epic_pulse(container, width, height, color)` - Epic animation
5. `_add_legendary_particles(container, width, height, color)` - Legendary particles
6. `_create_particle_texture()` - Helper to create particle texture

### Customization

To adjust effect parameters:
- **Shader uniforms**: Edit shader files in `resources/shaders/`
- **Animation timing**: Modify keyframes in `_add_epic_pulse()` and `_add_legendary_particles()`
- **Particle count/lifetime**: Adjust values in `_add_legendary_particles()`
- **Colors**: Modify RARITY_COLORS in `item_visuals.gd` or set custom colors in ItemData

## Performance Considerations

- Shaders are GPU-accelerated and very efficient
- AnimationPlayer has minimal CPU overhead
- Legendary particles (20 per item) are kept low for performance
- All effects use Control.MOUSE_FILTER_IGNORE to avoid input overhead

## Compatibility

- Requires Godot 4.x (tested with 4.5)
- Uses canvas_item shaders (2D)
- All effects are additive and don't modify item data
