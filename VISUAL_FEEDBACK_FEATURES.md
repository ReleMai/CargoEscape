# Visual Feedback for Container States

This document describes the visual feedback features added to containers in Cargo Escape.

## Overview

Enhanced visual feedback has been added to both UI containers (CargoContainer) and 2D boarding containers (ShipContainer) to provide clear, intuitive feedback about container states and interactions.

## Features

### 1. Hover Highlight Effect

**What it does:**
- Containers now show a subtle highlight overlay when the mouse hovers over them
- Smooth fade-in animation (0.15s) when mouse enters
- Smooth fade-out animation (0.15s) when mouse exits
- Pulsing glow effect on the highlight for visual interest

**Where it works:**
- CargoContainer (UI loot containers in the loot scene)
- ShipContainer (2D containers in boarding scenes)

**How to see it:**
- Move your mouse over any container that can be interacted with
- The container will glow slightly with a pulsing effect

### 2. Search Animation

**What it does:**
- Containers show a pulsing blue glow overlay when items inside are being searched
- The glow pulses continuously to indicate active searching
- Automatically activates when any item inside the container is being searched
- Automatically deactivates when searching stops

**Where it works:**
- CargoContainer - shows a full-container overlay during search
- ShipContainer - modulates the container color with pulsing effect

**How to see it:**
- Open a container with hidden items
- Click and hold on a hidden item (with "?" mark) to start searching
- The container will pulse with a blue glow while searching

### 3. Visual State Changes

**What it does:**
- Enhanced color transitions between different container states
- States: CLOSED, SEARCHING, OPEN, EMPTY
- Smooth color modulation during state transitions
- Pulsing color effect during SEARCHING state

**Container States:**
- **CLOSED** - Default color, shows item count
- **SEARCHING** - Pulsing blue/purple color, shows "Searching..." label
- **OPEN** - Green-tinted color, ready for looting
- **EMPTY** - Dimmed color with reduced opacity

**How to see it:**
- Observe container color changes as you interact with them
- Searching state has the most dramatic pulsing effect

### 4. Progress Indicator

**What it does:**
- Individual items show search progress with a colored bar
- Progress bar appears at the bottom of hidden items during search
- Bar fills from left to right as search progresses
- Pulsing alpha effect on the progress bar for visual feedback

**Where it works:**
- LootItem components (individual items inside containers)
- ShipContainer has a SearchProgressBar showing overall search progress

**How to see it:**
- Click and hold on a hidden item with "?" mark
- A blue progress bar will appear at the bottom of the item
- The bar fills up as you hold down the mouse button
- Release before it's full to cancel, or hold until complete to reveal the item

## Implementation Details

### Search Mechanic for Items

**New click-and-hold system for LootItem:**
1. Hidden items (with "?") can now be searched by clicking and holding
2. Progress is tracked and displayed with a visual bar
3. Releasing early cancels the search
4. Completing the search reveals the item

**Default search time:** 1.5 seconds per item

### Performance Optimizations

All pulsing effects use delta time accumulation instead of system time calls:
- Reduces overhead from system calls every frame
- More consistent animation across different frame rates
- Better performance overall

### Code Structure

**Files modified:**
- `scripts/loot/container.gd` - Added hover and search animation to UI containers
- `scripts/loot/loot_item.gd` - Added search functionality and progress indicator
- `scripts/boarding/ship_container.gd` - Added hover effects and enhanced search visuals
- `scenes/boarding/ship_container.tscn` - Added SearchProgressBar node

## Usage Examples

### For Container Hover Effect
```gdscript
# Hover is automatic - just move mouse over any interactive container
# The container will show a highlight overlay
```

### For Item Search
```gdscript
# In LootItem.gd - search is triggered automatically
# Just click and hold on a hidden item
# Progress is shown automatically with a visual bar
```

### Customizing Search Duration
```gdscript
# In LootItem.gd, modify the search_duration variable
var search_duration: float = 2.0  # 2 seconds instead of default 1.5
```

## Testing the Features

1. **Test Hover Effect:**
   - Launch the game
   - Go to loot scene or boarding scene
   - Move mouse over containers
   - Verify highlight appears/disappears smoothly

2. **Test Search Animation:**
   - Open a container with items
   - Click and hold on a hidden item
   - Verify container shows pulsing glow
   - Verify progress bar appears and fills

3. **Test State Changes:**
   - Open a closed container
   - Search items to completion
   - Take all items
   - Observe color changes through each state

## Backwards Compatibility

All changes are fully backwards compatible:
- Existing containers work without modification
- New features activate automatically
- No breaking changes to existing APIs
- Signals are additive (search_started, search_completed)

## Future Enhancements

Potential improvements for future iterations:
- Sound effects for state transitions
- Particle effects for successful searches
- Customizable pulse speeds and colors
- Different highlight colors for different container types
- Animation for items being revealed (fade-in, scale-up, etc.)
