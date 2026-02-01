# Escape Cutscene System - Implementation Documentation

## Overview

The escape cutscene system provides a cinematic sequence when the player successfully escapes from a boarded ship. It enhances the game feel by replacing the instant transition with a multi-phase animated sequence that varies based on the player's performance.

---

## Files

| File | Purpose |
|------|---------|
| `scripts/boarding/escape_cutscene.gd` | Main cutscene controller script |
| `scenes/boarding/escape_cutscene.tscn` | Cutscene UI scene with all phases |
| `scripts/boarding/boarding_manager.gd` | Integration - tracks containers and triggers cutscene |

---

## Cutscene Phases

### Phase 1: Rush to Exit (0.5s)

**Visual Elements:**
- Full-screen green flash effect
- Large "ESCAPING!" text that scales and fades in
- Quick, intense feeling to convey urgency

**Implementation:**
```gdscript
# Green flash fades from 0% to 70% then to 0%
# Label scales from 80% to 120% while fading in
```

### Phase 2: Undocking (1.5s)

**Visual Elements:**
- Airlock door slams shut (animated downward)
- Clamps on left and right sides release (animated outward)
- Status text displays: "AIRLOCK SEALED" → "CLAMPS RELEASING..." → "UNDOCKING COMPLETE"
- Space background

**Implementation:**
```gdscript
# Airlock slam: 0.3s animation with EASE_OUT + TRANS_BACK
# Clamps release: 0.5s after slam, both clamps move outward
# Status updates: 0.5s between each message
```

### Phase 3: Getaway (2s)

**Visual Elements:**
- Player ship accelerates away (moves right and scales down)
- Enemy ship remains in background
- Star field background
- Optional explosion effect if timer ran out

**Variations:**
- **Close Call**: Red pulsing background, alarm atmosphere
- **Clean Escape**: Normal space background
- **Perfect Run**: Special lighting effects (future enhancement)

**Implementation:**
```gdscript
# Player ship: 2s tween moving right with EASE_IN
# Ship explosion: Triggers at 60% through phase if timer == 0
# Flash effect on explosion
```

### Phase 4: Loot Summary (transition)

**Visual Elements:**
- Panel fades in showing collected items
- Title changes based on variation (see below)
- List of top 5 items collected
- Total value display
- Bonus message for variations

**Implementation:**
```gdscript
# Fade in: 0.8s
# Auto-continue after 3s
# Transitions to undocking scene
```

---

## Escape Variations

The cutscene adapts based on player performance:

### Clean Escape
**Trigger:** `time_remaining >= 10 seconds`

**Effects:**
- Green success title: "ESCAPE SUCCESSFUL"
- Normal space background
- No special effects

### Close Call
**Trigger:** `time_remaining < 10 seconds`

**Effects:**
- Orange warning title: "CLOSE CALL!"
- Red pulsing background during getaway
- Bonus message: "Close call! (X seconds left)"
- Ship explodes if `time_remaining <= 0`

### Perfect Run
**Trigger:** `containers_searched >= total_containers` (all containers searched)

**Effects:**
- Golden title: "PERFECT RUN!"
- Bonus message: "All containers searched! +25% bonus"
- Takes priority over Close Call if both conditions met
- Future: Golden glow effects, special fanfare sound

---

## Integration with Boarding Manager

### Container Tracking

The boarding manager now tracks:
```gdscript
var containers_searched: int = 0
var total_containers: int = 0
```

**Tracking Logic:**
1. `total_containers` increments when each container is spawned
2. `containers_searched` increments when a container is opened (via `container_opened` signal)

### Triggering the Cutscene

When the player reaches the exit:
```gdscript
func _start_escape_cutscene() -> void:
    var cutscene = EscapeCutsceneScene.instantiate()
    add_child(cutscene)
    
    var cutscene_data = {
        "time_remaining": time_remaining,
        "total_loot_value": total_loot_value,
        "collected_items": collected_items,
        "containers_searched": containers_searched,
        "total_containers": total_containers
    }
    
    cutscene.start_cutscene(cutscene_data)
```

---

## Scene Structure

```
EscapeCutscene (CanvasLayer, layer 100)
├── RushContainer (Control)
│   ├── EscapingFlash (ColorRect)
│   └── EscapingLabel (Label)
├── UndockingContainer (Control)
│   ├── Background (ColorRect)
│   ├── AirlockPanel (Panel)
│   │   ├── AirlockFrame (ColorRect)
│   │   └── AirlockDoor (ColorRect) - Animated
│   ├── ClampLeft (ColorRect) - Animated
│   ├── ClampRight (ColorRect) - Animated
│   └── UndockingStatus (Label)
├── GetawayContainer (Control)
│   ├── SpaceBackground (ColorRect)
│   ├── Stars (Control with star ColorRects)
│   ├── EnemyShip (ColorRect)
│   ├── PlayerShip (ColorRect) - Animated
│   └── ExplosionParticles (GPUParticles2D)
└── LootSummaryContainer (Control)
    └── LootSummaryPanel (Panel)
        └── VBox (VBoxContainer)
            ├── LootTitle (Label)
            ├── ItemsLabel (Label)
            ├── LootItemsList (VBoxContainer) - Populated dynamically
            ├── TotalValueLabel (Label)
            └── BonusLabel (Label)
```

---

## Key Features

### 1. Automatic Phase Progression
Each phase has a timer that automatically advances to the next phase:
- Rush: 0.5s → Undocking
- Undocking: 1.5s → Getaway
- Getaway: 2.0s → Loot Summary
- Loot Summary: 3.0s → Undocking scene

### 2. Variation Detection
The cutscene determines which variation to show based on the data:
```gdscript
func _determine_variation() -> void:
    # Perfect run takes priority
    if total_containers > 0 and containers_searched >= total_containers:
        escape_variation = EscapeVariation.PERFECT_RUN
        return
    
    # Close call
    if time_remaining < close_call_threshold:
        escape_variation = EscapeVariation.CLOSE_CALL
        ship_explodes = time_remaining <= 0.0
        return
    
    # Clean escape (default)
    escape_variation = EscapeVariation.CLEAN
```

### 3. Dynamic Loot Summary
The loot summary shows:
- Top 5 items by order collected
- "... and X more items" if more than 5
- Total value in credits
- Contextual bonus message

---

## Future Enhancements

### Visual
- [ ] Particle effects for perfect run (gold sparkles)
- [ ] More detailed ship models instead of colored rectangles
- [ ] Camera shake during explosion
- [ ] Screen flash effects
- [ ] Animated item icons in loot summary

### Audio
- [ ] Airlock slam sound effect
- [ ] Clamp release mechanical sounds
- [ ] Engine acceleration sound
- [ ] Explosion sound and rumble
- [ ] Success fanfare for perfect run
- [ ] Close call alarm sounds

### Gameplay
- [ ] Skip functionality (hold Space to skip)
- [ ] Bonus credits for perfect run (+25%)
- [ ] Statistics screen (containers searched, time taken, etc.)
- [ ] Achievement unlocks shown in cutscene

---

## Testing Scenarios

To test the escape cutscene, create these scenarios in the boarding scene:

### Test 1: Clean Escape
1. Board a ship
2. Search 1-2 containers (not all)
3. Escape with > 10 seconds remaining
4. **Expected**: "ESCAPE SUCCESSFUL" with normal background

### Test 2: Close Call
1. Board a ship
2. Wait until < 10 seconds remaining
3. Escape quickly
4. **Expected**: "CLOSE CALL!" with red pulsing background and time remaining message

### Test 3: Perfect Run
1. Board a ship with few containers
2. Search ALL containers
3. Escape (any time remaining)
4. **Expected**: "PERFECT RUN!" with golden title and bonus message

### Test 4: Explosion Escape
1. Board a ship
2. Wait until timer expires (0 seconds)
3. Escape at the last moment
4. **Expected**: Close call cutscene with ship explosion during getaway phase

---

## Code Examples

### Triggering from Custom Code
```gdscript
# From any scene that has escape logic
var cutscene = preload("res://scenes/boarding/escape_cutscene.tscn").instantiate()
add_child(cutscene)

cutscene.start_cutscene({
    "time_remaining": 45.0,
    "total_loot_value": 1500,
    "collected_items": my_items_array,
    "containers_searched": 4,
    "total_containers": 5
})

# Connect to completion signal if needed
cutscene.cutscene_completed.connect(_on_cutscene_done)
```

### Listening to Phase Changes
```gdscript
cutscene.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase_name: String) -> void:
    match phase_name:
        "RUSH_TO_EXIT":
            print("Player rushing to exit!")
        "UNDOCKING":
            print("Undocking sequence started")
        "GETAWAY":
            print("Player ship getting away")
        "LOOT_SUMMARY":
            print("Showing loot summary")
```

---

## Performance Notes

- Cutscene runs on a CanvasLayer at layer 100 (above all game elements)
- All animations use Godot's Tween system for smooth performance
- Scene unloads automatically when transitioning to undocking scene
- No persistent resources after completion

---

## Troubleshooting

### Cutscene doesn't start
- Check that `EscapeCutsceneScene` is properly preloaded in boarding_manager
- Verify `containers_searched` and `total_containers` are being tracked
- Ensure cutscene data dictionary has all required keys

### Wrong variation shown
- Check `time_remaining` value being passed
- Verify `containers_searched` vs `total_containers` logic
- Debug with: `print("Variation: ", escape_variation)`

### Visual elements missing
- Verify all nodes have `unique_name_in_owner = true` in the scene
- Check that node names match between scene and script
- Ensure CanvasLayer is visible and at correct layer

### Cutscene doesn't advance
- Check phase timer values (`rush_duration`, etc.)
- Verify `is_active` is true
- Look for errors in `_update_*_phase()` functions
