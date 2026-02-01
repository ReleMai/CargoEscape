# Testing Guide for Item Rarity Visual Effects

This guide will help you verify that the rarity visual effects are working correctly.

## Quick Test in Godot Editor

1. **Open the project in Godot 4.x**
   ```bash
   godot project.godot
   ```

2. **Create a test scene** (or use existing loot scene):
   - Open `scenes/loot/loot_scene.tscn`
   - Or create a new scene with a Control node

3. **Add test script** to manually verify each rarity:
   ```gdscript
   extends Control
   
   func _ready():
       # Test all rarity levels
       test_rarity_visuals()
   
   func test_rarity_visuals():
       var ItemDatabase = load("res://scripts/loot/item_database.gd")
       var x_offset = 100
       
       # Create one item of each rarity
       var test_items = [
           ItemDatabase.create_item("scrap_metal"),      # Common (0)
           ItemDatabase.create_item("copper_wire"),      # Uncommon (1)
           ItemDatabase.create_item("gold_bar"),         # Rare (2)
           ItemDatabase.create_item("alien_artifact"),   # Epic (3)
           ItemDatabase.create_item("quantum_core")      # Legendary (4)
       ]
       
       for i in range(test_items.size()):
           var item_data = test_items[i]
           if item_data:
               var loot_item = preload("res://scenes/loot/loot_item.tscn").instantiate()
               loot_item.initialize(item_data)
               loot_item.position = Vector2(x_offset * (i + 1), 200)
               add_child(loot_item)
               loot_item.setup_revealed()
   ```

## Expected Visual Effects

### Common (Rarity 0) - Scrap Metal
- ✅ **No special effects**
- Should display the basic item icon without any glow, shimmer, or particles

### Uncommon (Rarity 1) - Copper Wire
- ✅ **Subtle green glow**
- Gentle pulsing animation
- Edge-based glow (stronger at edges)
- Green tint (can be customized via item data)

### Rare (Rarity 2) - Gold Bar
- ✅ **Blue shimmer effect**
- Horizontal shimmer wave moving across the item
- Diagonal shimmer for visual interest
- Blue tint (can be customized via item data)
- Animated continuously

### Epic (Rarity 3) - Alien Artifact
- ✅ **Purple pulsing glow**
- Smooth alpha animation between 0.2 and 0.5
- 2-second loop cycle
- Purple tint (can be customized via item data)
- Continuous pulsing effect

### Legendary (Rarity 4) - Quantum Core
- ✅ **Gold particle effect with shine**
- Gold particles floating upward from the item
- Background glow with pulsing shine effect
- 20 particles visible at any time
- 2-second particle lifetime
- 3-second shine animation cycle
- Gold tint (can be customized via item data)

## Manual Testing Checklist

- [ ] Open the project in Godot 4.x
- [ ] Navigate to a loot scene or create a test scene
- [ ] Place items of each rarity on screen
- [ ] Verify Common items have no effects
- [ ] Verify Uncommon items have subtle pulsing glow
- [ ] Verify Rare items have animated shimmer effect
- [ ] Verify Epic items have smooth pulsing animation
- [ ] Verify Legendary items have particles and shine effect
- [ ] Test that effects don't interfere with item dragging
- [ ] Test that effects don't cause performance issues
- [ ] Verify effects work with both procedural and sprite-based items

## Performance Verification

1. **Open the profiler** (Debug > Profiler)
2. **Run a loot scene** with multiple legendary items
3. **Verify**:
   - GPU shader processing is efficient
   - Particle systems don't cause FPS drops
   - AnimationPlayer has minimal CPU overhead

## Troubleshooting

### Shaders not loading
- Check that shader files exist in `resources/shaders/`
- Verify shader syntax is correct (Godot 4.x canvas_item shaders)
- Look for errors in the Output panel

### Animations not playing
- Verify AnimationPlayer is added as a child
- Check that NodePath targets are correct
- Ensure animation library is properly configured

### Particles not visible
- Verify GPUParticles2D emitting property is true
- Check that particle texture is created successfully
- Ensure particles are added to the scene tree

### No effects showing
- Verify item rarity is set correctly (0-4)
- Check that `_add_rarity_effects()` is being called
- Look for errors in console related to shader loading

## Integration Testing

To verify the effects work in the actual game:

1. **Launch the game**
2. **Navigate to the loot/boarding phase**
3. **Open containers** and observe items
4. **Check that**:
   - All rarity effects display correctly
   - Effects don't interfere with gameplay
   - Tooltip still works
   - Drag and drop still functions
   - Items can be placed in inventory

## Visual Reference

The effects are designed to be:
- **Subtle for low rarities** (uncommon has gentle glow)
- **Noticeable for mid rarities** (rare has shimmer)
- **Impressive for high rarities** (epic pulses, legendary sparkles)
- **Performance-friendly** (GPU shaders, limited particles)

## Known Limitations

1. Particles on legendary items are limited to 20 to maintain performance
2. Shader effects require GPU support (should work on all modern systems)
3. Effects are rendered on top of the item icon, not integrated into the icon itself
