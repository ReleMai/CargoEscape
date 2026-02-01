# Boarding System Overhaul - Design Document

## Overview

This document outlines the complete redesign of the boarding/looting system to create a more strategic, time-pressured gameplay experience with varied ship types, container mechanics, and rarity-based loot distribution.

---

## 1. Search Timer System

### Concept
Players must "search" containers before items become lootable. This creates tension between thoroughness and escape time.

### Search Mechanics

| Item Rarity | Base Search Time | Description |
|-------------|------------------|-------------|
| Common      | 0.5 - 1.0s       | Quick grab |
| Uncommon    | 1.0 - 1.5s       | Brief search |
| Rare        | 1.5 - 2.5s       | Careful examination |
| Epic        | 2.5 - 4.0s       | Hidden compartment |
| Legendary   | 4.0 - 6.0s       | Security bypass |

### Search Flow
```
[Container Closed] → [Player Interacts] → [Search Progress Bar] → [Items Revealed] → [Drag to Inventory]
```

### Visual Feedback
- **Progress Ring**: Circular progress indicator around item/container
- **Sound Cues**: Rummaging sounds during search, "found" sound on completion
- **Item Glow**: Items pulse/glow when search completes
- **Interrupt Warning**: If player moves during search, progress is lost

### Search Modifiers
- **Container Type**: Some containers modify search time (see Section 4)
- **Ship Danger Level**: Higher tier ships may have longer search times
- **Player Upgrades** (future): Scanner upgrades reduce search time

---

## 2. Ship Types & Layouts

### Ship Tier System

| Tier | Ship Type | Loot Quality | Time Limit | Size | Danger |
|------|-----------|--------------|------------|------|--------|
| 1 | Cargo Shuttle | Common-Uncommon | 90s | Small | Low |
| 2 | Freight Hauler | Uncommon-Rare | 75s | Medium | Medium |
| 3 | Corporate Transport | Rare-Epic | 60s | Medium | Medium |
| 4 | Military Frigate | Epic-Legendary | 50s | Large | High |
| 5 | Black Ops Vessel | Legendary | 40s | Large | Extreme |

### Ship Layouts

#### Tier 1: Cargo Shuttle
```
┌─────────────────────┐
│  [S]     [C]    [E] │
│       ████████      │
│  [C]  ████████  [C] │
│       ████████      │
│  [P]     [S]        │
└─────────────────────┘
[P]=Player Start  [E]=Exit  [S]=Scrap Pile  [C]=Cargo Crate
```
- **Shape**: Rectangular, simple
- **Containers**: 3-5 (mostly scrap piles and cargo crates)
- **Color Scheme**: Rust orange, industrial gray

#### Tier 2: Freight Hauler
```
┌───────────────────────────┐
│      [L]    ███    [E]    │
│  ██████████████████████   │
│  [C]  [C]  ████  [C]  [C] │
│  ██████████████████████   │
│      [S]    ███    [P]    │
└───────────────────────────┘
[L]=Locker  [C]=Cargo Crate  [S]=Scrap Pile
```
- **Shape**: Long rectangular with cargo hold
- **Containers**: 5-7 (mix of types, introduces lockers)
- **Color Scheme**: Blue-gray, corporate

#### Tier 3: Corporate Transport
```
┌─────────────────────────────────┐
│        [V]    ████    [E]       │
│    ██████████████████████████   │
│ [L]  ████  [L]  ████  [L]  [S]  │
│    ██████████████████████████   │
│        [C]    ████    [P]       │
└─────────────────────────────────┘
[V]=Vault  [L]=Locker
```
- **Shape**: Elegant, curved corridors
- **Containers**: 6-8 (introduces vaults)
- **Color Scheme**: White, gold accents

#### Tier 4: Military Frigate
```
┌─────────────────────────────────────────┐
│            [A]    ██████    [E]         │
│    ████████████████████████████████     │
│ [L]  ████  [V]  ████████  [V]  ████ [L] │
│    ████████████████████████████████     │
│ [S]  ████  [C]  ████████  [C]  ████ [A] │
│    ████████████████████████████████     │
│            [L]    ██████    [P]         │
└─────────────────────────────────────────┘
[A]=Armory
```
- **Shape**: Angular, military design
- **Containers**: 8-12 (introduces armories)
- **Color Scheme**: Dark gray, red warning stripes

#### Tier 5: Black Ops Vessel
```
┌───────────────────────────────────────────────┐
│              [X]    ████████    [E]           │
│      ████████████████████████████████████     │
│   [A]  ████  [V]  ██████████  [V]  ████  [A]  │
│      ████████████████████████████████████     │
│   [V]  ████  [X]  ██████████  [X]  ████  [V]  │
│      ████████████████████████████████████     │
│              [L]    ████████    [P]           │
└───────────────────────────────────────────────┘
[X]=Secure Cache (new container type)
```
- **Shape**: Sleek, minimal visibility
- **Containers**: 10-15 (secure caches, vaults, armories)
- **Color Scheme**: Black, cyan accents

### Ship Visual Design

Each ship tier should have distinct visual characteristics:

| Element | Tier 1 | Tier 2 | Tier 3 | Tier 4 | Tier 5 |
|---------|--------|--------|--------|--------|--------|
| Hull Color | Rust/Orange | Blue-Gray | White/Gold | Dark Gray | Black |
| Accent Color | Yellow | Light Blue | Gold | Red | Cyan |
| Interior | Industrial | Standard | Luxury | Military | High-Tech |
| Lighting | Warm | Neutral | Bright | Red Tint | Blue Tint |
| Condition | Worn | Used | Pristine | Battle-Ready | Stealth |

---

## 3. Rarity Spawn Weights

### Base Rarity Distribution

| Rarity | Weight | Spawn Chance |
|--------|--------|--------------|
| Common | 100 | ~50% |
| Uncommon | 60 | ~30% |
| Rare | 25 | ~12.5% |
| Epic | 10 | ~5% |
| Legendary | 5 | ~2.5% |

### Ship Tier Modifiers

Each ship tier modifies the base weights:

| Ship Tier | Common | Uncommon | Rare | Epic | Legendary |
|-----------|--------|----------|------|------|-----------|
| Tier 1    | ×1.5   | ×0.8     | ×0.3 | ×0.1 | ×0.0      |
| Tier 2    | ×1.2   | ×1.2     | ×0.6 | ×0.2 | ×0.05     |
| Tier 3    | ×0.8   | ×1.0     | ×1.2 | ×0.6 | ×0.2      |
| Tier 4    | ×0.5   | ×0.8     | ×1.0 | ×1.2 | ×0.6      |
| Tier 5    | ×0.2   | ×0.5     | ×0.8 | ×1.2 | ×1.5      |

### Effective Spawn Chances by Ship Tier

**Tier 1 - Cargo Shuttle:**
- Common: 73%, Uncommon: 23%, Rare: 4%, Epic: <1%, Legendary: 0%

**Tier 3 - Corporate Transport:**
- Common: 35%, Uncommon: 26%, Rare: 26%, Epic: 10%, Legendary: 3%

**Tier 5 - Black Ops:**
- Common: 8%, Uncommon: 12%, Rare: 26%, Epic: 24%, Legendary: 30%

---

## 4. Container Types

### Container Definitions

#### Scrap Pile (Common)
```
Visual: Messy pile of debris and parts
Search Time: ×0.7 (faster)
Item Slots: 2-4
```
| Rarity | Weight Modifier |
|--------|-----------------|
| Common | ×2.0 |
| Uncommon | ×1.0 |
| Rare | ×0.3 |
| Epic | ×0.1 |
| Legendary | ×0.0 |

**Loot Pool Focus**: Scrap items, basic components

---

#### Cargo Crate (Common)
```
Visual: Standard shipping container
Search Time: ×1.0 (normal)
Item Slots: 3-5
```
| Rarity | Weight Modifier |
|--------|-----------------|
| Common | ×1.2 |
| Uncommon | ×1.2 |
| Rare | ×0.8 |
| Epic | ×0.4 |
| Legendary | ×0.1 |

**Loot Pool Focus**: Mixed items, components, some valuables

---

#### Locker (Uncommon)
```
Visual: Personal storage locker
Search Time: ×1.2 (slightly longer)
Item Slots: 2-4
```
| Rarity | Weight Modifier |
|--------|-----------------|
| Common | ×0.8 |
| Uncommon | ×1.5 |
| Rare | ×1.2 |
| Epic | ×0.6 |
| Legendary | ×0.2 |

**Loot Pool Focus**: Personal items, valuables, modules

---

#### Supply Cabinet (Uncommon)
```
Visual: Wall-mounted cabinet
Search Time: ×1.0 (normal)
Item Slots: 2-3
```
| Rarity | Weight Modifier |
|--------|-----------------|
| Common | ×1.0 |
| Uncommon | ×1.5 |
| Rare | ×1.0 |
| Epic | ×0.3 |
| Legendary | ×0.1 |

**Loot Pool Focus**: Components, fuel cells, supplies

---

#### Vault (Rare)
```
Visual: Reinforced secure container
Search Time: ×1.8 (longer - security)
Item Slots: 3-6
```
| Rarity | Weight Modifier |
|--------|-----------------|
| Common | ×0.3 |
| Uncommon | ×0.6 |
| Rare | ×1.5 |
| Epic | ×1.5 |
| Legendary | ×0.8 |

**Loot Pool Focus**: Valuables, rare components, epic items

---

#### Armory (Rare)
```
Visual: Weapons/equipment storage
Search Time: ×1.5 (security locks)
Item Slots: 2-4
```
| Rarity | Weight Modifier |
|--------|-----------------|
| Common | ×0.5 |
| Uncommon | ×0.8 |
| Rare | ×1.2 |
| Epic | ×1.5 |
| Legendary | ×0.5 |

**Loot Pool Focus**: Modules (weapons, shields), military equipment

---

#### Secure Cache (Epic)
```
Visual: Hidden high-security container
Search Time: ×2.5 (encryption bypass)
Item Slots: 1-3 (fewer but better)
```
| Rarity | Weight Modifier |
|--------|-----------------|
| Common | ×0.1 |
| Uncommon | ×0.3 |
| Rare | ×0.8 |
| Epic | ×1.8 |
| Legendary | ×1.5 |

**Loot Pool Focus**: Epic/Legendary items, rare artifacts

---

### Container Visual Summary

| Container | Color | Icon | Glow |
|-----------|-------|------|------|
| Scrap Pile | Rust Brown | Debris | None |
| Cargo Crate | Gray | Box | None |
| Locker | Blue-Gray | Door | Subtle Blue |
| Supply Cabinet | White | Cabinet | None |
| Vault | Silver | Lock | Gold |
| Armory | Dark Red | Crosshairs | Red |
| Secure Cache | Black | Diamond | Cyan Pulse |

---

## 5. Item Categories by Container

### Category Affinity System

Each container type has affinity for certain item categories:

| Container | Scrap | Components | Valuables | Modules | Artifacts |
|-----------|-------|------------|-----------|---------|-----------|
| Scrap Pile | ★★★★★ | ★★☆☆☆ | ☆☆☆☆☆ | ☆☆☆☆☆ | ☆☆☆☆☆ |
| Cargo Crate | ★★★☆☆ | ★★★★☆ | ★★☆☆☆ | ★☆☆☆☆ | ☆☆☆☆☆ |
| Locker | ★☆☆☆☆ | ★★☆☆☆ | ★★★★☆ | ★★★☆☆ | ★☆☆☆☆ |
| Supply Cabinet | ★★☆☆☆ | ★★★★★ | ★☆☆☆☆ | ★★☆☆☆ | ☆☆☆☆☆ |
| Vault | ☆☆☆☆☆ | ★★☆☆☆ | ★★★★★ | ★★★☆☆ | ★★★★☆ |
| Armory | ☆☆☆☆☆ | ★★★☆☆ | ★☆☆☆☆ | ★★★★★ | ★★☆☆☆ |
| Secure Cache | ☆☆☆☆☆ | ★☆☆☆☆ | ★★★★☆ | ★★★★☆ | ★★★★★ |

---

## 6. Asset Requirements

### Player Character
```
File: assets/sprites/player/boarding_player.svg
Size: 32x32 pixels
States:
  - Idle (facing 4 directions)
  - Walking (4 directions, 4 frames each)
  - Searching (animation)
Design: Space suit with helmet, backpack for loot
```

### Ship Hulls (5 tiers)
```
Files: assets/sprites/ships/ship_tier_[1-5].svg
Size: Variable (see layout dimensions)
Include:
  - Hull exterior
  - Interior floor
  - Wall patterns
  - Doorway indicators
```

### Containers (7 types)
```
Files: assets/sprites/containers/
  - scrap_pile.svg (48x48)
  - cargo_crate.svg (48x48)
  - locker.svg (32x48)
  - supply_cabinet.svg (32x32)
  - vault.svg (48x48)
  - armory.svg (48x48)
  - secure_cache.svg (32x32)
States:
  - Closed/Unsearched
  - Open/Searched (optional: Empty)
```

### Exit Point
```
File: assets/sprites/environment/exit_point.svg
Size: 64x64 pixels
States:
  - Active (pulsing green glow)
  - Reached (bright flash)
Design: Airlock door with escape pod indicator
```

### UI Elements
```
Files: assets/sprites/ui/
  - search_progress_ring.svg (circular progress indicator)
  - container_highlight.svg (selection indicator)
  - timer_warning.svg (low time alert)
```

---

## 7. Implementation Phases

### Phase 1: Search System (Priority: HIGH)
1. Add `search_time` property to items
2. Create search progress UI (ring around container)
3. Implement search state machine in containers
4. Add search interruption on player movement
5. Visual/audio feedback for search states

### Phase 2: Container Types (Priority: HIGH)
1. Define ContainerType enum
2. Create container data class with:
   - Type, search time modifier, slot count
   - Rarity weight modifiers
   - Category affinities
3. Update container spawning to use types
4. Create placeholder sprites for each type

### Phase 3: Ship Types (Priority: MEDIUM)
1. Define ShipTier enum and data
2. Create ship layout system:
   - Wall placement
   - Container spawn points
   - Entry/exit positions
3. Implement tier-based loot modifiers
4. Create 5 ship layouts (can be simple initially)

### Phase 4: Custom Assets (Priority: MEDIUM)
1. Design and create player sprite
2. Design and create container sprites (7 types)
3. Design and create ship hull sprites (5 tiers)
4. Design exit point sprite
5. Create UI elements for search system

### Phase 5: Polish & Balance (Priority: LOW)
1. Tune search times for game feel
2. Balance loot distribution
3. Add sound effects
4. Add particle effects for searches
5. Playtest and iterate

---

## 8. Code Structure

### New/Modified Files

```
scripts/
├── boarding/
│   ├── boarding_manager.gd      # Modified: Ship tier handling
│   ├── ship_container.gd        # Modified: Container types, search system
│   ├── ship_layout.gd           # NEW: Ship layout definitions
│   └── search_system.gd         # NEW: Search mechanics
├── loot/
│   ├── item_database.gd         # Modified: Search time per item
│   ├── container_types.gd       # NEW: Container type definitions
│   └── loot_tables.gd           # NEW: Refactored loot generation
└── data/
    ├── ship_data.gd             # NEW: Ship tier data
    └── container_data.gd        # NEW: Container type data

scenes/
├── boarding/
│   ├── ships/
│   │   ├── ship_tier_1.tscn     # NEW: Cargo Shuttle layout
│   │   ├── ship_tier_2.tscn     # NEW: Freight Hauler layout
│   │   ├── ship_tier_3.tscn     # NEW: Corporate Transport layout
│   │   ├── ship_tier_4.tscn     # NEW: Military Frigate layout
│   │   └── ship_tier_5.tscn     # NEW: Black Ops layout
│   └── containers/
│       ├── scrap_pile.tscn      # NEW
│       ├── cargo_crate.tscn     # NEW
│       ├── locker.tscn          # NEW
│       ├── supply_cabinet.tscn  # NEW
│       ├── vault.tscn           # NEW
│       ├── armory.tscn          # NEW
│       └── secure_cache.tscn    # NEW

assets/sprites/
├── player/
│   └── boarding_player.svg      # NEW
├── ships/
│   ├── ship_tier_1.svg          # NEW
│   ├── ship_tier_2.svg          # NEW
│   ├── ship_tier_3.svg          # NEW
│   ├── ship_tier_4.svg          # NEW
│   └── ship_tier_5.svg          # NEW
├── containers/
│   ├── scrap_pile.svg           # NEW
│   ├── cargo_crate.svg          # NEW
│   ├── locker.svg               # NEW
│   ├── supply_cabinet.svg       # NEW
│   ├── vault.svg                # NEW
│   ├── armory.svg               # NEW
│   └── secure_cache.svg         # NEW
└── environment/
    └── exit_point.svg           # NEW
```

---

## 9. Data Schemas

### ItemData Additions
```gdscript
# Add to item_data.gd
@export var search_time: float = 1.0  # Base search time in seconds
```

### ContainerType Data
```gdscript
class_name ContainerTypeData

enum ContainerType {
    SCRAP_PILE,
    CARGO_CRATE,
    LOCKER,
    SUPPLY_CABINET,
    VAULT,
    ARMORY,
    SECURE_CACHE
}

var type: ContainerType
var display_name: String
var search_time_modifier: float  # Multiplier on item search times
var min_slots: int
var max_slots: int
var rarity_modifiers: Dictionary  # {rarity: float_multiplier}
var category_affinities: Dictionary  # {category: float_weight}
var sprite_path: String
var glow_color: Color
```

### ShipTier Data
```gdscript
class_name ShipTierData

enum ShipTier {
    CARGO_SHUTTLE,
    FREIGHT_HAULER,
    CORPORATE_TRANSPORT,
    MILITARY_FRIGATE,
    BLACK_OPS_VESSEL
}

var tier: ShipTier
var display_name: String
var time_limit: float
var size: Vector2  # Ship dimensions
var rarity_modifiers: Dictionary  # {rarity: float_multiplier}
var container_types: Array[ContainerType]  # Allowed container types
var container_count: Vector2i  # min, max containers
var hull_color: Color
var accent_color: Color
var layout_scene: PackedScene
```

---

## 10. Gameplay Loop Summary

```
1. SHIP SELECTION
   └─→ Based on distance from hideout / mission progress
   └─→ Higher tier = further from safety

2. BOARDING START
   └─→ Player spawns at entry point
   └─→ Timer starts (tier-based duration)
   └─→ Ship layout loads with containers

3. EXPLORATION
   └─→ Player moves through ship
   └─→ Containers visible but contents unknown
   └─→ Container type hints at possible loot

4. SEARCHING
   └─→ Player interacts with container
   └─→ Progress ring appears
   └─→ Items revealed one by one (search time each)
   └─→ Moving cancels search (progress lost)

5. LOOTING
   └─→ Revealed items can be dragged to inventory
   └─→ Strategic choice: grab and go vs. search more
   └─→ Time pressure increases

6. ESCAPE
   └─→ Player reaches exit point
   └─→ Loot value tallied
   └─→ Return to space / next ship

7. FAILURE (Timer expires)
   └─→ Captured / killed
   └─→ Lose all loot from this ship
   └─→ Continue from hideout
```

---

## 11. Risk/Reward Dynamics

| Decision | Risk | Reward |
|----------|------|--------|
| Search scrap pile | Low time (0.7x) | Mostly common items |
| Search secure cache | High time (2.5x) | Epic/Legendary chance |
| Grab first items | Miss better items deeper | Guaranteed loot |
| Search everything | Run out of time | Maximum value |
| Take Tier 1 ship | Lower value loot | Easy escape |
| Take Tier 5 ship | Very hard escape | Legendary items |

---

## 12. Future Considerations

### Potential Additions
- **Alarms**: Some containers trigger ship alerts, reducing remaining time
- **Locked Containers**: Require finding key cards
- **Hazards**: Damage zones, patrolling drones
- **Crew Members**: NPCs that can catch player
- **Scanner Upgrade**: Reveals item quality before searching
- **Quick Hands Upgrade**: Reduces search time
- **Bigger Backpack**: More inventory slots

### Multiplayer Potential
- Co-op looting with shared timer
- Competitive: Race to loot same ship
- Roles: One searches, one carries

---

## Summary

This system transforms looting from a simple grab-and-go into a strategic experience where:

1. **Time is the enemy** - Every search costs precious seconds
2. **Choices matter** - Which containers to search? Which items to take?
3. **Risk scales with reward** - Higher tier ships = better loot but harder escape
4. **Knowledge is power** - Learning container types helps prioritize
5. **Every run is different** - Procedural layouts and loot keep it fresh

The search timer system is the core mechanic that creates tension. Without it, players would just grab everything. With it, they must make meaningful choices under pressure.
