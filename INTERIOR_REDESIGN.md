# Ship Interior Redesign Plan

## Overview

This document outlines the phased approach to improving ship interiors for better gameplay, NPC combat, and visual variety.

---

## Phase 1: Fix Core Layout Issues (Priority: HIGH)

### Problem: Walkable Area Gaps
- Corridors don't properly connect to room edges
- Wall collision sometimes blocks valid paths
- Doors may spawn in non-walkable areas

### Solution:
1. **Corridor Generation Improvements**
   - Extend corridor cells to overlap with room edges
   - Add door cells at corridor-room intersections
   - Validate complete pathfinding before finalizing layout

2. **Wall Collision Fixes**
   - Generate wall collisions from walkable grid inverse
   - Use expanded room bounds for collision (not exact edges)
   - Add debug visualization option

### Files to Modify:
- `scripts/boarding/ship_generator.gd` - Corridor generation
- `scripts/boarding/ship_interior_renderer.gd` - Wall collision creation
- `scripts/boarding/door.gd` - Door placement validation

---

## Phase 2: Keycard/Lock System (Priority: MEDIUM-HIGH)

### Current State:
- Door.gd has `LockType` enum (KEYCARD, HACK, SECURITY)
- No keycard items exist
- No door unlocking logic

### Implementation Plan:

1. **Add Keycard Items**
   - Create keycard item resources (Tier 1-3)
   - Add keycards to container loot tables
   - Visual indicator for keycard tier

2. **Door Locking Logic**
   - Locked doors block player movement
   - Check player inventory for matching keycard
   - UI prompt: "Requires Security Keycard Tier 2"
   - Audio/visual feedback on unlock

3. **Level Design Integration**
   - Guarantee at least one keycard spawns before locked door
   - Higher tier ships have more locked doors
   - Optional: Hackable doors for skilled players

### New Files:
- `resources/items/keycards/keycard_tier1.tres`
- `resources/items/keycards/keycard_tier2.tres`
- `resources/items/keycards/keycard_tier3.tres`

### Files to Modify:
- `scripts/boarding/door.gd` - Unlock logic
- `scripts/boarding/ship_generator.gd` - Keycard placement
- `scripts/loot/item_db.gd` - Keycard items

---

## Phase 3: Container Placement Intelligence (Priority: MEDIUM)

### Current State:
- Random positions within room bounds
- No consideration for room type
- No "points of interest"

### Improvements:

1. **Room-Aware Placement**
   - Cargo Bay: Containers near walls in rows
   - Bridge: Container near console area
   - Storage: Dense grid of containers
   - Armory: Weapon racks in specific spots

2. **Points of Interest (POI) System**
   ```gdscript
   class RoomPOI:
       var position: Vector2
       var type: String  # "container", "terminal", "cover"
       var required: bool
   ```

3. **Container Type by Location**
   - Wall-adjacent: Crates, lockers
   - Center: Cargo containers
   - Near doors: Emergency supplies

### Files to Modify:
- `scripts/data/room_types.gd` - Add POI definitions
- `scripts/boarding/ship_generator.gd` - Use POIs for placement

---

## Phase 4: Decoration Variety (Priority: MEDIUM-LOW)

### Current State:
- Basic procedural decorations in `ship_decorations.gd`
- Limited object types

### Additions:

1. **New Decoration Types**
   - Computer terminals
   - Pipes/conduits
   - Cargo netting
   - Tool racks
   - Warning signs
   - Screens/displays
   - Barrels/tanks
   - Light fixtures

2. **Room-Specific Decorations**
   ```gdscript
   const ROOM_DECORATIONS = {
       BRIDGE: ["terminal", "display", "chair", "console"],
       ENGINE_ROOM: ["pipes", "conduit", "barrel", "warning_sign"],
       CARGO_BAY: ["netting", "crate_stack", "forklift"],
   }
   ```

3. **Faction-Specific Theming**
   - CCG: Industrial, functional
   - Corporate: Clean, luxurious
   - Pirate: Makeshift, damaged

---

## Phase 5: NPC/Combat Preparation (Priority: FUTURE)

### Required Infrastructure:

1. **Spawn Points**
   - Marked positions for enemy spawning
   - Away from entry point
   - Cover nearby

2. **Patrol Paths**
   - Waypoint system between rooms
   - Guard routes along corridors

3. **Cover Positions**
   - Crates, walls, doorways marked as cover
   - Half-cover vs full-cover

4. **Sight Lines**
   - Areas with clear line-of-sight
   - Ambush positions

### Data Structures:
```gdscript
class CombatLayout:
    var spawn_points: Array[Vector2]
    var patrol_paths: Array[PackedVector2Array]
    var cover_positions: Array[CoverPoint]
    var sight_lines: Array[LineSegment]
```

---

## Implementation Order

1. ✅ Fix crash bug (item_name → name)
2. ✅ Fix settings persistence
3. ✅ Phase 1: Walkable area fixes (corridor connections improved)
4. ✅ Phase 2: Keycard system (fully implemented)
5. Phase 3: Container intelligence
6. Phase 4: Decoration variety
7. Phase 5: NPC preparation

---

## Completed Implementation Details

### Keycard System (Phase 2) - COMPLETE

**New Files Created:**
- `resources/items/keycards/keycard_tier1.tres` - Green keycard
- `resources/items/keycards/keycard_tier2.tres` - Blue keycard  
- `resources/items/keycards/keycard_tier3.tres` - Red keycard
- `assets/sprites/items/keycard_green.svg`
- `assets/sprites/items/keycard_blue.svg`
- `assets/sprites/items/keycard_red.svg`

**Files Modified:**
- `scripts/boarding/door.gd` - Added keycard unlock logic
- `scripts/boarding/ship_generator.gd` - Locked door and keycard placement
- `scripts/boarding/ship_interior_renderer.gd` - Lock tier from layout data
- `scripts/boarding/boarding_manager.gd` - Keycard injection into containers
- `scripts/boarding/ship_container.gd` - `add_guaranteed_item()` method
- `scripts/boarding/ship_layout.gd` - `locked_doors` and `keycard_spawns` fields
- `resources/items/item_database.gd` - Keycard item definitions

**How It Works:**
1. ShipGenerator marks rooms as locked based on tier
2. For each locked room, a keycard spawns in an accessible room
3. ShipInteriorRenderer creates locked doors at room entrances
4. Doors show lock status and required keycard color
5. Player must find keycard in container to unlock door
6. Higher tier keycards can open lower tier locks

### Debug Visualization - COMPLETE

**New exports in ship_interior_renderer.gd:**
- `debug_show_grid: bool` - Shows walkable cells (green) vs walls (red)
- `debug_show_collisions: bool` - Shows collision shape outlines (orange)

---

## Testing Checklist

- [ ] Player can walk from entry to exit on all tier layouts
- [ ] No invisible walls blocking valid paths
- [ ] Doors properly open/close
- [ ] Locked doors require keycards
- [ ] Containers spawn in accessible locations
- [ ] Visual decorations don't block movement
- [ ] Performance acceptable with all features enabled

---

*Document created: February 2, 2026*
