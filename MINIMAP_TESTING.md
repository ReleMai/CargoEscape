# Minimap Testing Guide

## Manual Testing Checklist

### Basic Functionality
- [ ] Launch the game and start a boarding mission
- [ ] Verify minimap appears in top-right corner
- [ ] Check that minimap has a border (PanelContainer)
- [ ] Confirm minimap renders inside the panel

### Room Layout
- [ ] Verify rooms appear on the minimap
- [ ] Check that unexplored rooms are covered by dark fog
- [ ] Move around and confirm rooms reveal as you explore
- [ ] Test with different ship tiers (1-5) to ensure all layouts work

### Player Indicator
- [ ] Verify green triangle appears on minimap
- [ ] Move the player and confirm triangle updates position
- [ ] Check that triangle position matches player location relative to rooms

### Container Markers
- [ ] Find containers and verify they appear on minimap
- [ ] Check unsearched containers are yellow/gold colored
- [ ] Open a container and verify it turns gray on the minimap
- [ ] Confirm containers only appear in explored areas

### Exit Point
- [ ] Navigate to the exit point
- [ ] Verify cyan diamond appears when exit area is explored
- [ ] Check that the exit marker pulses (animated)

### Fog of War
- [ ] Start mission and verify entire ship is dark/fogged
- [ ] Move around and watch fog clear as you explore
- [ ] Return to starting area and confirm it stays revealed
- [ ] Test exploration radius feels appropriate (200 units)

### Different Ship Tiers
Test each tier to ensure minimap scales appropriately:
- [ ] Tier 1 (Cargo Shuttle) - Small, simple layout
- [ ] Tier 2 (Freight Hauler) - Medium size, cargo bays
- [ ] Tier 3 (Corporate Transport) - Larger, office layout
- [ ] Tier 4 (Military Frigate) - Complex, tactical layout
- [ ] Tier 5 (Black Ops Vessel) - Largest, maze-like

### Performance
- [ ] Check minimap doesn't cause lag/stuttering
- [ ] Verify memory doesn't grow excessively over time
- [ ] Confirm SubViewport renders smoothly

### Edge Cases
- [ ] Test with extremely small rooms
- [ ] Test with extremely large ships
- [ ] Verify behavior when containers are very close together
- [ ] Check minimap when player is at ship boundaries

## Expected Visual Appearance

### Minimap Colors
- **Dark blue-gray fog**: Unexplored areas
- **Light gray-blue rooms**: Explored rooms
- **Light borders**: Room walls
- **Green triangle**: Player position
- **Yellow circles**: Unsearched containers
- **Gray circles**: Searched containers
- **Cyan diamond** (pulsing): Exit point

### Minimap Size
- **Width**: 210 pixels
- **Height**: 200 pixels
- **Position**: Top-right corner, 10px from edge, 60px from top

### Animation
- Exit point should pulse smoothly
- Player indicator should update every frame
- Fog should reveal smoothly as player moves

## Known Limitations
- Minimap is always oriented north-up (doesn't rotate with player)
- Very small rooms (< 80x80) may not render clearly at default scale
- Maximum 1000 explored positions stored (old positions forgotten)
- Containers must be in explored areas to be visible

## Debug Commands
If you need to test specific scenarios:
1. Set `forced_ship_tier` in BoardingManager to test specific tiers
2. Adjust `exploration_radius` in MinimapRenderer for faster/slower fog reveal
3. Modify `minimap_scale` to zoom in/out on the ship layout
