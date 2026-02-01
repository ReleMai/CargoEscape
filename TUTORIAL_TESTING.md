# Tutorial System Testing Guide

This document describes how to test the interactive tutorial system for new players.

## Prerequisites

- Godot 4.5+ installed
- Project opened in Godot Editor

## Test Setup

1. **Reset Tutorial State**
   - Delete the save file at: `user://save_data.cfg`
   - On Linux/Mac: `~/.local/share/godot/app_userdata/Cargo Escape/save_data.cfg`
   - On Windows: `%APPDATA%\Godot\app_userdata\Cargo Escape\save_data.cfg`
   - This ensures the tutorial will show for a "first-time" player

2. **Launch the Game**
   - Press F5 in Godot Editor or click the Play button
   - Navigate through intro/menu to start a boarding mission

## Tutorial Flow Test Cases

### Test 1: Movement Tutorial (Step 1)
**Expected Behavior:**
- After entrance animation completes (~1.5 seconds)
- Tutorial overlay appears with tooltip
- Tooltip shows: "Movement Controls" title
- Description: "Use WASD or Arrow Keys to move around the ship. Try moving in all directions!"
- Skip button visible in top-right corner

**Action:**
- Move the player using WASD or arrow keys

**Expected Result:**
- Tutorial progresses to next step automatically
- Movement step marked as complete in save file

### Test 2: Container Interaction (Step 2)
**Expected Behavior:**
- Tooltip updates to "Interacting with Containers"
- Description: "Approach a container and press E to search it. Containers contain valuable loot!"
- First container in scene is highlighted with yellow border
- Pulsing highlight animation visible

**Action:**
- Approach a container
- Press E to interact

**Expected Result:**
- Loot menu opens
- Tutorial progresses to inventory step

### Test 3: Inventory Management (Step 3)
**Expected Behavior:**
- Tooltip updates to "Managing Inventory"
- Description: "Press I or TAB to open your inventory. Drag items to manage your loot."
- Inventory panel highlighted

**Action:**
- Close loot menu (ESC)
- Press I or TAB to open inventory

**Expected Result:**
- Inventory panel opens
- Tutorial progresses to timer step

### Test 4: Timer Understanding (Step 4)
**Expected Behavior:**
- Tooltip updates to "Understanding the Timer"
- Description explains time limit
- Timer label at top of screen is highlighted
- Auto-progresses after 4 seconds (no action required)

**Expected Result:**
- Tutorial automatically advances to exit step

### Test 5: Finding the Exit (Step 5)
**Expected Behavior:**
- Tooltip updates to "Finding the Exit"
- Description: "Find the exit marker and reach it before time runs out."
- Exit point is highlighted with yellow border

**Action:**
- Navigate to the exit point
- Press E to escape

**Expected Result:**
- Boarding phase ends
- Player transitions to hideout/station scene
- Tutorial continues to selling step

### Test 6: Selling Loot (Step 6)
**Expected Behavior:**
- At station scene, after animation (~0.5 seconds)
- Tooltip shows "Selling Loot at Station"
- Description: "At the station, you can sell your loot for credits. Click on items to sell them."
- Sell button is highlighted

**Action:**
- Click the "Sell All" button

**Expected Result:**
- Items are sold for credits
- Tutorial completes
- Tutorial overlay disappears
- Tutorial marked as complete in save file

## Test 7: Skip Tutorial
**Starting Point:** Any tutorial step

**Action:**
- Click "Skip Tutorial" button in top-right

**Expected Result:**
- Tutorial overlay immediately disappears
- Tutorial marked as complete in save file
- Player can continue playing normally
- On next run, tutorial does not appear

## Test 8: Tutorial Not Showing for Returning Players
**Setup:**
- Complete tutorial once (or skip it)
- Restart the game

**Expected Behavior:**
- Tutorial overlay does NOT appear
- Player proceeds directly to gameplay
- No tutorial tooltips or highlights

**Action to Re-enable:**
- Delete save file or
- Edit save file and set `tutorial/completed = false`

## Validation Checklist

- [ ] All 6 tutorial steps trigger in correct order
- [ ] Tooltips display correct text for each step
- [ ] UI elements are properly highlighted
- [ ] Highlight animations are smooth and visible
- [ ] Skip button works at any step
- [ ] Tutorial completion is saved to disk
- [ ] Tutorial doesn't show on subsequent playthroughs
- [ ] Player can interact with game during tutorial
- [ ] Tutorial overlay is on top of all other UI (layer 100)
- [ ] No errors in console during tutorial flow

## Known Limitations

1. Tutorial only supports the boarding-to-station flow
2. Tutorial doesn't cover the space combat phase
3. If player skips directly to combat, selling tutorial won't trigger
4. Tutorial overlay doesn't prevent player from doing other actions

## Save File Format

The tutorial state is saved in `user://save_data.cfg`:

```ini
[tutorial]
completed=false
first_time=true
steps={"movement": false, "container_interaction": false, "inventory": false, "timer": false, "exit": false, "selling": false}

[settings]
show_tutorial=true
```

## Debugging

### Enable Debug Output
- Check console for messages starting with `[TutorialManager]`, `[SaveManager]`, or `[TutorialOverlay]`

### Common Issues

**Tutorial not starting:**
- Check that autoloads are configured in Project Settings
- Verify save file doesn't have `completed=true`
- Check console for initialization messages

**Highlights not showing:**
- Verify target nodes exist in scene
- Check node names match expected values
- Ensure nodes are in correct groups (containers, exit_point)

**Steps not progressing:**
- Verify player actions are triggering tutorial events
- Check that TutorialManager.on_player_action() is being called
- Look for signal connections in boarding_manager

## Performance Notes

- Tutorial overlay updates position every frame when highlighting is active
- Node searching uses optimized `find_child()` method
- Minimal performance impact expected
