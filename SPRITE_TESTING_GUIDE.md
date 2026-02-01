# Item Sprite Testing Guide

## Quick Verification Checklist

### 1. Visual Inspection
Open the `sprite_showcase.html` file in a web browser to view all sprites organized by rarity:
```bash
# From the project root
open sprite_showcase.html
# or
firefox sprite_showcase.html
# or
chrome sprite_showcase.html
```

### 2. Godot Editor Verification

#### Method 1: Direct Import Test
1. Open the project in Godot 4.x
2. Navigate to `assets/sprites/items/` in FileSystem
3. Check that all PNG files display correctly
4. Verify `.import` files were created automatically
5. Check that sprites show proper transparency

#### Method 2: ItemData Resource Test
1. In Godot editor, create a new test scene
2. Add a Sprite2D node
3. Try loading different category sprites:
   ```gdscript
   # In the Texture property, select:
   res://assets/sprites/items/cargo/scrap_metal.png
   res://assets/sprites/items/tech/fusion_cell.png
   res://assets/sprites/items/luxury/singularity_gem.png
   ```
4. Verify sprites are 64x64 and display correctly

#### Method 3: Database Integration Test
1. Open `scripts/loot/item_database.gd`
2. Run the game in debug mode
3. Spawn loot containers
4. Verify items display with correct sprites and rarity effects

### 3. File System Verification

Run these commands to verify all sprites are in place:

```bash
# Count total PNG sprites (should be 57)
find assets/sprites/items -name "*.png" | wc -l

# Verify each category has correct count
for dir in assets/sprites/items/*/; do 
    echo "$(basename $dir): $(ls -1 $dir/*.png 2>/dev/null | wc -l) items"
done

# Check all PNG files are 64x64
file assets/sprites/items/*/*.png | grep -v "64 x 64"
# (should return nothing if all are correct size)

# Verify import files exist
find assets/sprites/items -name "*.png.import" | wc -l
# (should match PNG count: 57)
```

### 4. Rarity Effect Verification

Check that rarity effects are visible in sprites:

**Common (No border):**
- `cargo/scrap_metal.png`
- `cargo/scrap_plastics.png`

**Uncommon (Green glow):**
- `tech/data_chip.png`
- `medical/med_kit.png`

**Rare (Blue border + glow):**
- `tech/encrypted_drive.png`
- `weapons/weapon_core.png`

**Epic (Purple border + glow):**
- `tech/fusion_cell.png`
- `contraband/dark_matter_vial.png`

**Legendary (Gold border + sparkles):**
- `luxury/singularity_gem.png`
- `faction/prototype_engine.png`

### 5. Database Path Verification

Verify all item database entries use correct PNG paths:

```bash
# Check that all icon paths now point to PNG files
grep '"icon":' scripts/loot/item_database.gd | grep -c '\.png"'
# Should return: 42

# Verify no SVG references remain
grep '"icon":' scripts/loot/item_database.gd | grep -c '\.svg"'
# Should return: 0

# Check that paths include category directories
grep '"icon":' scripts/loot/item_database.gd | grep -c 'items/[a-z]*/'
# Should return: 42
```

### 6. Performance Test

In Godot:
1. Create a test scene with 50+ Sprite2D nodes
2. Load different item sprites on each
3. Run the scene and check:
   - FPS remains stable (60 FPS target)
   - No texture loading warnings in console
   - Sprites render correctly at various scales
   - Transparency works properly

### 7. Integration Test

Test the complete loot system:
1. Start a game session
2. Board a ship / access loot phase
3. Open containers
4. Verify:
   - Items display with correct sprites
   - Rarity effects are visible
   - Items can be dragged to inventory
   - Tooltips show correct item images
   - No missing texture warnings

## Expected Results

### Successful Implementation
✅ 57 PNG sprites created (exceeds minimum 50)
✅ All sprites are 64x64 pixels with transparency
✅ Sprites organized in 7 category directories
✅ Rarity visual effects applied correctly
✅ Item database updated with PNG paths
✅ Godot import files generated for all sprites
✅ No build or import errors in Godot

### Common Issues and Solutions

#### Issue: Sprites appear blurry
**Solution:** Check import settings - `filter` should be `false` for pixel art

#### Issue: Missing transparency
**Solution:** Verify PNG files have alpha channel (RGBA format)

#### Issue: Rarity effects not visible
**Solution:** Check sprite generation script parameters, regenerate if needed

#### Issue: "Can't open file" errors
**Solution:** Verify file paths in item_database.gd match actual file locations

#### Issue: Import files missing
**Solution:** Open project in Godot editor - it will auto-generate import files

## Regenerating Sprites

If sprites need to be regenerated:

```bash
# Regenerate all PNG sprites with rarity effects
python3 scripts/generate_item_sprites.py

# Regenerate Godot import files
python3 scripts/generate_import_files.py

# Update database paths
python3 scripts/update_database_paths.py
```

## Adding New Sprites

To add new item sprites:

1. Edit `scripts/generate_item_sprites.py`
2. Add item to `new_items` list:
   ```python
   ('item_name', 'category', 'rarity'),
   ```
3. Run the generator script
4. Add item data to `item_database.gd`

## Visual Quality Checklist

For each sprite, verify:
- [ ] Correct size (64x64 pixels)
- [ ] Transparent background
- [ ] Proper rarity border/glow
- [ ] Clear, recognizable icon
- [ ] Matches category theme
- [ ] Consistent art style

## Documentation

- `assets/sprites/items/README.md` - Sprite system overview
- `assets/sprites/items/SPRITE_MANIFEST.txt` - Complete sprite listing
- `sprite_showcase.html` - Visual sprite gallery

## Support

If issues persist:
1. Check console for specific error messages
2. Verify Godot version compatibility (4.x required)
3. Review LOOT_SYSTEM_DOCS.md for system architecture
4. Check item_database.gd for correct icon paths
