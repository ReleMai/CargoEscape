# Tutorial System - Quick Reference

## Tutorial Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Game Start (First Time)                   │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
          ┌───────────────────────────────┐
          │  SaveManager.should_show_     │
          │  tutorial() returns true      │
          └───────────────┬───────────────┘
                          │
                          ▼
          ┌───────────────────────────────┐
          │  Boarding Scene Loads         │
          │  Entrance animation plays     │
          └───────────────┬───────────────┘
                          │
                          ▼
          ┌───────────────────────────────┐
          │  TutorialManager.start_       │
          │  tutorial() called            │
          └───────────────┬───────────────┘
                          │
                          ▼
          ┌───────────────────────────────┐
          │  TutorialOverlay UI loads     │
          │  (Layer 100, on top)          │
          └───────────────┬───────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │                                   │
        ▼                                   ▼
┌───────────────┐                  ┌────────────────┐
│  Skip Button  │                  │  Step 1: Move  │
│  (anytime)    │                  └────────┬───────┘
└───────┬───────┘                           │
        │                                   ▼
        │                          Player moves (WASD)
        │                                   │
        │                                   ▼
        │                    ┌──────────────────────────┐
        │                    │ Step 2: Container Search │
        │                    └──────────┬───────────────┘
        │                               │
        │                               ▼
        │                     Press E on container
        │                               │
        │                               ▼
        │                    ┌──────────────────────┐
        │                    │ Step 3: Inventory    │
        │                    └──────────┬───────────┘
        │                               │
        │                               ▼
        │                     Press I/TAB to open
        │                               │
        │                               ▼
        │                    ┌──────────────────────┐
        │                    │ Step 4: Timer        │
        │                    │ (Auto-advances)      │
        │                    └──────────┬───────────┘
        │                               │
        │                               ▼
        │                    ┌──────────────────────┐
        │                    │ Step 5: Exit         │
        │                    └──────────┬───────────┘
        │                               │
        │                               ▼
        │                     Reach exit and press E
        │                               │
        ├───────────────────────────────┤
        │                               │
        ▼                               ▼
┌───────────────┐            ┌──────────────────────┐
│ Tutorial      │            │ Station Scene Loads  │
│ Skipped       │            └──────────┬───────────┘
└───────┬───────┘                       │
        │                               ▼
        │                    ┌──────────────────────┐
        │                    │ Step 6: Selling      │
        │                    └──────────┬───────────┘
        │                               │
        │                               ▼
        │                     Click "Sell All" button
        │                               │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │  Tutorial Completed!          │
        │  - Overlay disappears         │
        │  - Saved to save_data.cfg     │
        │  - Won't show again           │
        └───────────────────────────────┘
```

## Component Interaction

```
┌──────────────────┐
│  SaveManager     │◄──────── Loads/saves tutorial state
│  (Autoload)      │
└────────┬─────────┘
         │ provides state
         ▼
┌──────────────────┐         controls        ┌──────────────────┐
│ TutorialManager  │────────────────────────►│ TutorialOverlay  │
│  (Autoload)      │                         │  (UI CanvasLayer)│
└────────┬─────────┘                         └──────────────────┘
         │
         │ receives events from
         │
    ┌────┴────┬──────────┬────────────┐
    │         │          │            │
    ▼         ▼          ▼            ▼
┌─────────┐ ┌──────┐ ┌──────┐ ┌──────────┐
│Boarding │ │Board.│ │Exit  │ │ Station  │
│Manager  │ │Player│ │Point │ │          │
└─────────┘ └──────┘ └──────┘ └──────────┘
```

## Key Files Summary

| File | Purpose | Lines | Type |
|------|---------|-------|------|
| `scripts/core/save_manager.gd` | Save/load system | 143 | Autoload |
| `scripts/core/tutorial_manager.gd` | Tutorial controller | 274 | Autoload |
| `scripts/ui/tutorial_overlay.gd` | UI overlay logic | 218 | Script |
| `scenes/ui/tutorial_overlay.tscn` | UI overlay scene | 71 | Scene |
| `TUTORIAL_TESTING.md` | Test guide | 247 | Docs |
| `TUTORIAL_SYSTEM_DOCS.md` | Dev docs | 242 | Docs |

**Total new code:** ~947 lines
**Files modified:** 4
**Files created:** 6

## Tutorial Steps Reference

| # | ID | Title | Action | Auto? |
|---|----|----|--------|-------|
| 1 | movement | Movement Controls | Move with WASD | No |
| 2 | container_interaction | Interacting with Containers | Press E on container | No |
| 3 | inventory | Managing Inventory | Press I/TAB | No |
| 4 | timer | Understanding the Timer | None (info) | Yes (4s) |
| 5 | exit | Finding the Exit | Reach exit + E | No |
| 6 | selling | Selling Loot at Station | Click Sell button | No |

## Highlighted Elements

| Step | Element | Find Method |
|------|---------|-------------|
| 2 | Container | Group: "containers" |
| 3 | Inventory Panel | Name: "InventoryPanel" |
| 4 | Timer Label | Name: "TimerLabel" |
| 5 | Exit Point | Group: "exit_point" |
| 6 | Sell Button | Name: "SellButton" |

## Save File Structure

```ini
[tutorial]
completed=false
first_time=true
steps={"movement": false, "container_interaction": false, ...}

[settings]
master_volume=1.0
music_volume=0.8
sfx_volume=1.0
show_tutorial=true
```

## Testing Quick Commands

```bash
# Delete save file (Linux/Mac)
rm ~/.local/share/godot/app_userdata/Cargo\ Escape/save_data.cfg

# Reset tutorial from GDScript console
SaveManager.reset_tutorial()

# Check if tutorial will show
print(SaveManager.should_show_tutorial())

# Skip tutorial programmatically
TutorialManager.skip_tutorial()
```

## Performance Impact

- **Memory**: ~50KB (UI overlay + textures)
- **CPU**: Minimal (updates once per frame when active)
- **Rendering**: 1 CanvasLayer (layer 100)
- **File I/O**: Save on step completion (~1KB writes)

## Future Improvements

1. ☐ Tutorial for space combat phase
2. ☐ Multi-language support (i18n)
3. ☐ Tutorial replay option in settings
4. ☐ Video/GIF demonstrations
5. ☐ Voice-over support
6. ☐ Adaptive hints based on player behavior
7. ☐ Achievement for completing tutorial

---

**Status:** ✅ Complete and ready for testing
**Version:** 1.0.0
**Date:** 2026-02-01
