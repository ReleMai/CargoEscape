# Loading Screen Documentation

## Overview
The loading screen provides a smooth transition between game scenes with visual feedback and gameplay tips.

## Features
- **Progress Bar**: Displays loading progress from 0-100%
- **Random Gameplay Tips**: Shows one of 15+ helpful tips during loading
- **Animated Spinner**: Rotating spinner animation for visual interest
- **Fade Transitions**: Smooth fade in/out effects

## Usage

The loading screen is automatically available as a singleton/autoload named `LoadingScreen`.

### Basic Usage

Replace direct scene changes:
```gdscript
# Old way
get_tree().change_scene_to_file("res://scenes/main.tscn")

# New way
LoadingScreen.start_transition("res://scenes/main.tscn")
```

### Advanced Usage

Connect to signals for custom behavior:
```gdscript
func _ready():
    LoadingScreen.transition_started.connect(_on_loading_started)
    LoadingScreen.transition_finished.connect(_on_loading_finished)

func _on_loading_started():
    print("Loading started!")

func _on_loading_finished():
    print("Loading complete!")
```

## Implementation Details

### Asynchronous Loading
The loading screen uses Godot's `ResourceLoader.load_threaded_request()` to load scenes asynchronously without freezing the game.

### Progress Animation
The progress bar fills smoothly over approximately 0.67 seconds, providing visual feedback even for fast loads.

### Tips System
Tips are selected randomly from the `GAMEPLAY_TIPS` array. To add more tips, edit the array in `scripts/ui/loading_screen.gd`.

## Files
- **Scene**: `scenes/ui/loading_screen.tscn`
- **Script**: `scripts/ui/loading_screen.gd`
- **Autoload Name**: `LoadingScreen`

## Customization

### Adding More Tips
Edit the `GAMEPLAY_TIPS` array in `scripts/ui/loading_screen.gd`:
```gdscript
const GAMEPLAY_TIPS: Array[String] = [
    "Your new tip here",
    # ... existing tips
]
```

### Adjusting Timing
Modify these values in the script:
- Fade speed: Line ~97 (`fade_alpha += delta * 2.0`)
- Progress speed: Line ~113 (`progress += delta * 150.0`)
- Spinner rotation speed: Line ~100 (`spinner_rotation += delta * 360.0`)
- Display delay: Line ~237 (`await get_tree().create_timer(0.3).timeout`)

### Styling
Modify the scene in Godot editor:
- Background color: `Background` ColorRect
- Spinner appearance: `SpinnerContainer/Spinner` node
- Progress bar style: `ProgressContainer/ProgressBar` theme
- Text styling: `TipLabel` and `LoadingLabel` font properties
