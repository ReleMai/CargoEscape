# Achievement System Documentation

## Overview

The achievement system tracks player progress and rewards them with unlockable trophies for completing various milestones in the game.

## Architecture

### Core Components

1. **AchievementData** (`scripts/data/achievement_data.gd`)
   - Resource class defining individual achievements
   - Properties: id, title, description, achievement_type, required_value, tier
   - Visual data: icons (locked/unlocked), tier colors

2. **AchievementManager** (`scripts/achievement_manager.gd`)
   - Autoload singleton managing all achievements
   - Tracks persistent stats across play sessions
   - Handles achievement unlocking logic
   - Saves/loads achievement progress to `user://achievements.save`

3. **PopupManager** (`scripts/popup_manager.gd`)
   - Autoload singleton for UI notifications
   - Displays achievement unlock popups
   - Positioned at top-right of screen

4. **UI Components**
   - **AchievementPopup** (`scenes/ui/achievement_popup.tscn`) - Unlock notification
   - **AchievementGallery** (`scenes/ui/achievement_gallery.tscn`) - Full gallery screen
   - **AchievementItem** (`scenes/ui/achievement_item.tscn`) - Single achievement display

## Achievements

### 1. First Haul (Bronze)
- **Description:** Complete your first boarding
- **Trigger:** Complete any boarding successfully
- **Tracking:** `stats["boardings_completed"] >= 1`

### 2. Big Spender (Silver)
- **Description:** Earn 10,000 total credits
- **Trigger:** Total credits earned reaches 10,000
- **Tracking:** `stats["total_credits_earned"] >= 10000`

### 3. Lucky Find (Gold)
- **Description:** Find a legendary item
- **Trigger:** Find an item with rarity 4 (Legendary)
- **Tracking:** `stats["legendary_items_found"] >= 1`

### 4. Speed Runner (Silver)
- **Description:** Complete a boarding in under 60 seconds
- **Trigger:** Finish boarding with time < 60s
- **Tracking:** `boarding_time <= 60.0`

### 5. Completionist (Silver)
- **Description:** Search every container on a ship
- **Trigger:** Search all containers in a single boarding
- **Tracking:** `containers_searched >= total_containers`

### 6. Faction Hunter (Gold)
- **Description:** Board ships from all 5 factions
- **Trigger:** Board ships from CCG, NEX, GDF, SYN, and IND
- **Tracking:** `stats["factions_boarded"].size() >= 5`

## Integration Points

### BoardingManager
Tracks achievement-related events during boarding:
- Boarding start/completion
- Container searches
- Legendary item finds
- Faction tracking
- Completion time

### GameManager
Tracks credits earned for Big Spender achievement.

### Main Menu
Provides access to Achievement Gallery via "ACHIEVEMENTS" button.

## Persistent Stats

Stats are saved to `user://achievements.save` and include:

```gdscript
{
  "boardings_completed": int,
  "total_credits_earned": int,
  "legendary_items_found": int,
  "fastest_boarding_time": float,
  "factions_boarded": Array[String],
  "current_containers_searched": int,
  "current_total_containers": int
}
```

## API Usage

### Triggering Achievement Checks

```gdscript
# In game code:
AchievementManager.on_boarding_completed(time_taken, faction_code)
AchievementManager.on_credits_earned(amount)
AchievementManager.on_legendary_item_found()
AchievementManager.on_container_searched()
```

### Querying Achievement State

```gdscript
# Check if unlocked
var unlocked = AchievementManager.is_achievement_unlocked("first_haul")

# Get all achievements
var all = AchievementManager.get_all_achievements()

# Get completion percentage
var percent = AchievementManager.get_completion_percentage()

# Get stat value
var boardings = AchievementManager.get_stat("boardings_completed")
```

### Opening Achievement Gallery

```gdscript
# From any scene:
var gallery = preload("res://scenes/ui/achievement_gallery.tscn").instantiate()
add_child(gallery)
```

## Achievement Tiers

- **Bronze (0):** Common achievements, basic milestones
- **Silver (1):** Moderate difficulty, skill-based
- **Gold (2):** Challenging, rare accomplishments  
- **Platinum (3):** Reserved for future ultra-rare achievements

## Future Enhancements

Potential additions:
- Steam/platform integration
- More achievements (combo chains, perfect runs, etc.)
- Achievement rewards (cosmetics, credits, modules)
- Leaderboards for Speed Runner times
- Secret/hidden achievements
