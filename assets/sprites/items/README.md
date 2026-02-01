# Item Sprites - 64x64 PNG Assets

This directory contains all item sprite assets for the CargoEscape game.

## 📊 Statistics

- **Total Items:** 57 unique sprites
- **Format:** 64x64 PNG with transparency
- **Style:** Pixel art with rarity visual effects
- **Categories:** 7 item types

## 📁 Directory Structure

```
items/
├── cargo/          (13 items) - Trade goods, scrap, containers
├── tech/           (13 items) - Electronics, chips, devices
├── weapons/        (4 items)  - Guns, blades, weapon components
├── medical/        (5 items)  - Med-kits, stims, medical supplies
├── contraband/     (3 items)  - Illegal items (red tint)
├── luxury/         (10 items) - Wine, art, jewelry, valuables
└── faction/        (9 items)  - Faction-specific modules
```

## ✨ Rarity Visual Effects

Sprites include visual indicators for rarity levels:

### Common (0)
- **Visual:** No border
- **Color:** Gray (180, 180, 180)
- **Items:** Scrap materials, basic cargo

### Uncommon (1)
- **Visual:** Subtle green glow
- **Color:** Green (77, 204, 77)
- **Glow Strength:** 3px
- **Items:** Standard components, basic equipment

### Rare (2)
- **Visual:** Blue border + glow
- **Color:** Blue (77, 128, 255)
- **Glow Strength:** 4px
- **Items:** Advanced tech, rare materials

### Epic (3)
- **Visual:** Purple border + glow
- **Color:** Purple (179, 77, 230)
- **Glow Strength:** 5px
- **Items:** High-tech modules, valuable goods

### Legendary (4)
- **Visual:** Gold border + glow + sparkles
- **Color:** Gold (255, 204, 51)
- **Glow Strength:** 6px
- **Special:** Corner sparkle effects
- **Items:** Unique artifacts, prototype equipment

## 🎨 Item Categories

### Cargo (cargo/)
Common trade goods and salvage materials:
- Scrap metal, plastics, electronics
- Hull fragments, wire bundles
- Shipping containers, barrels, crates

### Tech (tech/)
Electronic components and devices:
- Data chips, processors
- Quantum cores, AI chips
- Nav computers, targeting arrays
- Fuel cells, plasma coils

### Weapons (weapons/)
Combat equipment and weapon systems:
- Plasma pistol, laser rifle
- Ion blade
- Weapon cores and components

### Medical (medical/)
Health and medical supplies:
- Med-kits, stim packs
- Cryo samples, nano bandages
- Oxygen canisters

### Contraband (contraband/)
Illegal or restricted items:
- Dark matter vials
- Neural stims
- Black market chips

### Luxury (luxury/)
High-value collectibles and valuables:
- Gold bars, rare alloys
- Singularity gems, star sapphires
- Alien artifacts, ancient relics
- Nebula wine, ancient scrolls

### Faction (faction/)
Faction-specific equipment and modules:
- Engine boosters, thrusters
- Laser amplifiers, targeting systems
- Shield modules, scanners
- Stealth plating, gravity dampeners
- Prototype engines

## 🔧 Technical Specifications

### Image Format
- **Size:** 64x64 pixels
- **Format:** PNG with alpha transparency
- **Color Depth:** 32-bit RGBA
- **DPI:** 72 (standard screen resolution)

### Rarity Effects Applied
1. **Glow Effect:** Gaussian blur with fade-out gradient
2. **Border:** 2-3px outline in rarity color
3. **Sparkles:** (Legendary only) 4 corner highlights

### File Naming Convention
- Lowercase with underscores: `item_name.png`
- Descriptive names: `plasma_pistol.png`, `scrap_metal.png`
- No spaces or special characters

## 🛠️ Generation

Sprites were generated using the automated script:
```bash
python3 scripts/generate_item_sprites.py
```

The script:
1. Converts existing SVG sprites to 64x64 PNG
2. Applies rarity-based visual effects
3. Organizes sprites into category directories
4. Creates placeholder sprites for new items

## 📝 Usage in Godot

To use these sprites in your ItemData resources:

```gdscript
# In Godot editor or code:
@export var sprite: Texture2D = preload("res://assets/sprites/items/tech/data_chip.png")
```

Example ItemData configuration:
```gdscript
var item = ItemData.new()
item.name = "Data Chip"
item.sprite = load("res://assets/sprites/items/tech/data_chip.png")
item.rarity = 1  # Uncommon
item.category = ItemCategory.COMPONENT
```

## 📋 Manifest

See `SPRITE_MANIFEST.txt` for a complete list of all sprites with their categories and rarity levels.

## 🎮 Viewing Sprites

Open `sprite_showcase.html` in a web browser to view all sprites organized by rarity level with visual examples.

## 🔄 Adding New Sprites

To add new item sprites:

1. **Manual Creation:**
   - Create 64x64 PNG sprite with transparency
   - Save to appropriate category folder
   - Follow naming convention

2. **Automated Creation:**
   - Edit `scripts/generate_item_sprites.py`
   - Add item to `new_items` list with category and rarity
   - Run script to generate

3. **Update References:**
   - Update `item_database.gd` with new item data
   - Update manifest if needed

## 📄 License

These sprites are part of the CargoEscape game project. See main project LICENSE for details.
