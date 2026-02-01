# Intro Sequence Testing Guide

## Overview
The intro sequence has been implemented with the following features:

### Sequence Phases (Total: ~12 seconds)

1. **Logo Phase (2s)**
   - Game logo "CARGO ESCAPE" fades in
   - Glowing effect pulses around the logo
   - Particle effects spawn and drift around the logo area
   - Golden/yellow color scheme

2. **Scene Setting Phase (5s)**
   - Space background with parallax stars
   - Text crawl displays three lines of text:
     - "In the lawless sectors of space..."
     - "Fortune favors the bold..."
     - "And the quick."
   - Each line fades in and out smoothly
   - Background pans across space

3. **Title Card Phase (2s)**
   - Main title "CARGO ESCAPE" appears with scale animation
   - Tagline "Loot. Escape. Survive." fades in below
   - Golden title with white tagline

4. **Transition Phase (3s)**
   - Player ship flies in from the left side
   - Ship grows larger as it approaches center
   - Camera follows the ship slightly
   - Engine glow effects visible
   - Fades to main menu (intro_scene.tscn)

## Features Implemented

### Skip Functionality
- After the first viewing, pressing SPACE or the fire key will skip to the menu
- Skip hint displays at the bottom when skipping is available
- First-time viewers must watch the full sequence

### Settings Integration
- Intro can be disabled on startup via project settings
- Setting: `intro/disable_on_startup` (boolean)
- Viewed state tracked: `intro/has_been_viewed` (boolean)

## How to Test

1. **First Run**
   - Launch the game (F5 in Godot)
   - Watch the full intro sequence (~12 seconds)
   - Sequence should flow: Logo → Text Crawl → Title Card → Ship → Menu

2. **Second Run**
   - Launch the game again
   - You should now see "Press SPACE to skip" at the bottom
   - Press SPACE to skip directly to menu

3. **Visual Elements to Check**
   - Logo glows and pulses
   - Particles drift around logo
   - Stars scroll in background
   - Text fades in/out smoothly
   - Ship has engine glow effects
   - All transitions are smooth

4. **Performance**
   - Sequence should run at 60 FPS
   - No stuttering or lag
   - Smooth animations throughout

## Expected Behavior

- **Total Duration**: ~12 seconds for complete sequence
- **Skip Available**: After first view only
- **Final Scene**: Transitions to `res://scenes/intro/intro_scene.tscn` (main menu)
- **Visual Style**: Space theme with golden/yellow accents for title

## Integration Notes

- Main scene set to: `res://scenes/intro/intro_sequence.tscn`
- Uses existing Control node architecture
- Custom drawing for visual effects
- No external assets required (all procedurally drawn)
- Compatible with existing game flow

## Future Enhancements (Not Implemented Yet)

- Music synchronization with visuals
- More advanced particle systems
- Voice-over for text crawl
- Additional camera effects
- Save/load settings UI for disable option
