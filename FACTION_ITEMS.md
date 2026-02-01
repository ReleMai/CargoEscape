# Faction-Specific Unique Items

This document describes the faction-specific unique items feature added to CargoEscape.

## Overview

Each of the 5 factions now has 5 unique items that only spawn on ships belonging to that faction. This adds variety to the loot system and makes different factions feel more distinct.

## Factions and Their Unique Items

### CCG (Colonial Cargo Guild) - Trade Focus
Trade-focused items found on commercial vessels:

1. **Guild Trade License** (Rare) - Authenticated trade documentation, very valuable to merchants
2. **Bulk Cargo Manifest** (Uncommon) - Detailed cargo route logs revealing nearby shipment locations  
3. **Premium Fuel Reserves** (Uncommon) - High-grade refined ship fuel
4. **Trade Route Data** (Rare) - Encrypted navigation data with profitable trade routes
5. **Guild Master's Seal** (Legendary) - Symbol of authority within the CCG, priceless to collectors

### NEX (Nexus Syndicate) - Criminal Focus
Criminal/black market items found on syndicate vessels:

1. **Syndicate Cipher** (Rare) - Encrypted key unlocking black market locations
2. **Assassination Contract** (Epic) - Illegal hit contract, extremely valuable on black market
3. **Forged ID Chips** (Rare) - Professional identity forgery kit with biometric spoofing
4. **Syndicate Tribute** (Rare) - Cache of protection money from various sectors
5. **Crime Lord's Ledger** (Legendary) - Blackmail material containing secrets of the powerful

### GDF (Galactic Defense Force) - Military Focus
Military equipment and classified data:

1. **Military Rations (Premium)** (Uncommon) - High-quality, long-lasting military food
2. **Tactical Armor Plating** (Rare) - Advanced composite armor for ship upgrades
3. **Encrypted Orders** (Rare) - Classified military operation data
4. **Officer's Sidearm** (Epic) - Rare military-grade personal weapon, highly regulated
5. **Admiral's Medal** (Legendary) - Prestigious military honor, priceless collectible

### SYN (Synthetix Corp) - Tech Focus
Advanced technology and experimental items:

1. **Prototype Chip** (Epic) - Experimental processor technology, cutting-edge and unstable
2. **AI Core Fragment** (Epic) - Piece of advanced AI neural network
3. **Nanobot Swarm** (Epic) - Medical and repair nanobots in containment
4. **Holographic Projector** (Rare) - Advanced entertainment and presentation technology
5. **Quantum Processor** (Legendary) - One of the most advanced chips ever made

### IND (Independent) - Mixed/Salvage Focus
Eclectic items found on independent trader vessels:

1. **Salvage Rights Claim** (Uncommon) - Legal documentation for salvage operations
2. **Homemade Repairs** (Uncommon) - Jury-rigged parts that work surprisingly well
3. **Family Heirloom** (Rare) - Personal item with variable sentimental value
4. **Prospector's Map** (Rare) - Hand-drawn map pointing to valuable wreck locations
5. **Lucky Charm** (Legendary) - Talisman rumored to bring fortune to its owner

## How It Works

### Spawn Mechanics

- When a ship is generated, it is assigned a faction (CCG, NEX, GDF, SYN, or IND)
- When containers generate loot, there is a **20% chance per item** to spawn a faction-specific item
- Faction-specific items still respect rarity modifiers from ship tier and container type
- The remaining 80% of items come from the standard loot pool

### Implementation Details

1. **ItemData Class** - Added `faction_exclusive` field to store the faction code
2. **Item Database** - Added 5 new item dictionaries (one per faction) with 5 items each
3. **Loot Generation** - New `generate_container_loot_with_faction()` function
4. **Boarding Manager** - Tracks the current ship's faction and passes it to containers
5. **Ship Container** - Updated `generate_loot()` to accept and use faction parameter

## Code Usage

### Getting Faction-Specific Items

```gdscript
# Get all CCG-exclusive items
var ccg_items = ItemDB.get_faction_items("CCG")

# Get all non-faction items (common pool)
var common_items = ItemDB.get_common_pool_items()

# Generate loot with faction consideration
var items = ItemDB.generate_container_loot_with_faction(
    ship_tier,        # 1-5
    container_type,   # Container type ID
    item_count,       # Number of items to generate
    "GDF"            # Faction code
)
```

### Checking Item Faction

```gdscript
var item = ItemDB.create_item("guild_trade_license")
if item.faction_exclusive == "CCG":
    print("This is a CCG-exclusive item!")
```

## Visual Assets

Each faction-specific item has a unique SVG icon located in:
`assets/sprites/items/[item_name].svg`

All 25 icons have been created with faction-appropriate color schemes:
- **CCG**: Gold/brown (trade/commerce theme)
- **NEX**: Cyan/dark (criminal/tech theme)  
- **GDF**: Red/gray (military theme)
- **SYN**: Cyan/blue (advanced tech theme)
- **IND**: Green/varied (independent/salvage theme)

## Balance Considerations

- Legendary items are very rare (rarity 4) and valuable (1800-4200 credits)
- Epic items (rarity 3) are moderately rare (580-720 credits)
- Rare items (rarity 2) provide good value (280-650 credits)
- Uncommon items (rarity 1) are accessible early (180-320 credits)
- Higher tier ships have better chances of spawning higher rarity faction items
- The 20% faction item chance ensures variety without overwhelming the loot pool

## Testing

A test script is available at `scripts/test_faction_items.gd` that verifies:
- All 25 faction items can be created
- Items have correct faction_exclusive values
- Faction-aware loot generation works
- Faction filtering functions work correctly

## Future Enhancements

Potential improvements to consider:
- Faction-specific container types (e.g., "CCG Shipping Manifest")
- Faction reputation system affecting item prices
- Faction-exclusive quests or missions
- Crafting recipes using faction items
- Faction item sets with bonuses
