# ==============================================================================
# QUICK START GUIDE - GETTING THE GAME RUNNING
# ==============================================================================

## Step 1: Open the Project in Godot

1. Open Godot 4.5
2. Click "Import"
3. Navigate to this folder and select `project.godot`
4. Click "Import & Edit"

## Step 2: Verify the Autoload

The GameManager needs to be set up as an Autoload:

1. Go to **Project > Project Settings**
2. Click the **Autoload** tab
3. Verify "GameManager" is listed pointing to `res://scripts/game_manager.gd`
4. If not, click the folder icon, select the script, name it "GameManager", click "Add"

## Step 3: Run the Game

1. Press **F5** or click the Play button
2. The game should start with:
   - Dark space background
   - Cyan rectangle (player placeholder) on the left
   - Orange squares (enemy placeholders) spawning from the right
   - HUD showing lives and score

## Controls

### Movement
- **W / Up Arrow** - Move up
- **S / Down Arrow** - Move down  
- **A / Left Arrow** - Move left
- **D / Right Arrow** - Move right

### Inventory Management (Loot Phase)
- **1-9** - Quick select inventory slots 1-9
- **Q** - Drop selected item
- **E** - Use/equip selected item (or interact)
- **Tab** - Toggle inventory view
- **Escape** - Close menus

## Troubleshooting

### "GameManager not found" error
- Make sure the Autoload is set up (Step 2 above)

### Player doesn't move
- Check Project Settings > Input Map has the move_up/down/left/right actions

### Enemies don't spawn
- Make sure `enemy_scene` is set in Main scene's Inspector
- Check the SpawnTimer is configured correctly

### Collision doesn't work
- Verify collision layers are set correctly:
  - Player: Layer 1, Mask 2
  - Enemy: Layer 2, Mask 1

## Next Steps

1. **Add your own sprites** - See `assets/README.md` for instructions
2. **Tweak values** - Select nodes in scenes and adjust @export variables
3. **Read the code** - Every script has detailed comments explaining how it works
4. **Experiment!** - Try changing speeds, spawn rates, etc.

## File Overview

| File | Purpose |
|------|---------|
| `scripts/game_manager.gd` | Global game state (lives, score) |
| `scripts/player.gd` | Player movement and collision |
| `scripts/enemy.gd` | Enemy movement |
| `scripts/main.gd` | Game loop and spawning |
| `scripts/background.gd` | Parallax scrolling |
| `scripts/ui/hud.gd` | Lives and score display |

## Learning Path

1. Start with `scripts/player.gd` - most heavily commented
2. Then `scripts/enemy.gd` - simpler, builds on player concepts
3. Then `scripts/main.gd` - see how pieces connect
4. Finally `scripts/game_manager.gd` - understand global state

Happy learning! 🚀
