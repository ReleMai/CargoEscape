# Accessibility Features Documentation

## Overview

Cargo Escape includes comprehensive accessibility options designed to make the game playable for a wider audience. All accessibility settings are persistent and automatically saved.

## How to Access

From the main menu, click the **ACCESSIBILITY** button to open the settings menu.

## Available Features

### 1. Colorblind Modes

Support for three types of color vision deficiency:

- **Deuteranopia** (Red-Green, most common - affects ~6% of males)
- **Protanopia** (Red-Green, affects ~1% of males)  
- **Tritanopia** (Blue-Yellow, rare - affects ~0.001% of population)

#### Technical Implementation
- Uses scientifically-based color transformation matrices based on research from Brettel, Viénot and Mollon (1997) and Machado, Oliveira and Fernandes (2009)
- Real-time shader filtering using Godot's SCREEN_TEXTURE
- Applied as a post-processing effect via CanvasLayer with BackBufferCopy

### 2. High Contrast Mode

Enhances UI visibility by:
- Increasing text color contrast to pure white
- Brightening progress bars and UI elements
- Improving readability for players with low vision

### 3. Text Size Options

Three text size settings:
- **Normal**: Default size (1.0x)
- **Large**: 30% larger (1.3x)
- **Extra Large**: 60% larger (1.6x)

Applies to:
- All menu text
- HUD elements (health, score, speed, distance)
- Button labels
- All UI components

#### Technical Implementation
- Stores base font sizes to prevent compounding scaling issues
- Dynamically scales all Label, Button, CheckBox, and OptionButton nodes
- Maintains consistent scaling across scene changes

### 4. Reduce Motion

Disables animations and visual transitions, useful for:
- Players sensitive to motion
- Reducing motion sickness
- Improving performance on lower-end systems

Affects:
- Menu fade-in/fade-out animations
- Transition effects
- All tween-based animations

### 5. Custom Control Remapping

Allows players to remap any game control to their preferred keys:

**Remappable Actions:**
- Movement (up, down, left, right)
- Brake
- Fire/Attack
- Interact
- Inventory

#### Features:
- Visual feedback showing current key bindings
- Support for keyboard and mouse inputs
- Reset individual controls or all controls to defaults
- Proper handling of physical_keycode with fallback to keycode

### 6. Screen Reader Mode

Announces important UI changes to support screen reader users:
- Menu navigation
- Settings changes
- Important game events

#### Current Implementation:
- Console-based announcements
- Extensible architecture for OS-level screen reader integration

#### Future Enhancements:
- TTS (Text-to-Speech) integration
- Platform-specific screen reader support
- ARIA-like semantic annotations

## Settings Persistence

All accessibility settings are automatically saved to:
```
user://accessibility_settings.cfg
```

Settings include:
- Colorblind mode selection
- High contrast state
- Text size preference
- Reduce motion state
- Screen reader mode
- Custom key bindings

## Architecture

### Core Components

1. **AccessibilityManager** (`scripts/core/accessibility_manager.gd`)
   - Autoload singleton
   - Centralized settings management
   - Signal-based updates
   - Settings persistence

2. **Colorblind Shader** (`scripts/core/shaders/colorblind_filter.gdshader`)
   - Screen-space shader for color transformation
   - Unshaded rendering mode
   - Matrix-based color correction

3. **Colorblind Overlay** (`scripts/core/colorblind_overlay.gd`)
   - CanvasLayer-based overlay
   - Manages shader application
   - Listens for accessibility changes

4. **Accessibility Menu** (`scripts/ui/accessibility_menu.gd`)
   - Main settings interface
   - Real-time preview of settings
   - Navigation to controls menu

5. **Controls Menu** (`scripts/ui/controls_menu.gd`)
   - Key remapping interface
   - Visual feedback for current bindings
   - Input capture for remapping

### Integration Points

- **HUD** (`scripts/ui/hud.gd`): Text sizing and high contrast
- **Main Menu** (`scripts/ui/main_menu.gd`): Reduce motion, accessibility button
- **Project Settings** (`project.godot`): AccessibilityManager autoload

## Best Practices Implemented

1. **Non-Destructive**: All accessibility features are optional and don't affect gameplay
2. **Persistent**: Settings save automatically and load on game start
3. **Real-time**: Changes apply immediately with visual feedback
4. **Reversible**: All settings can be reset to defaults
5. **Documented**: Comprehensive comments in all source files
6. **Modular**: Easy to extend with new accessibility features

## Testing Recommendations

1. **Colorblind Modes**: Test with actual colorblind users or simulation tools
2. **Text Scaling**: Verify readability at all sizes and resolutions
3. **Input Remapping**: Test with various keyboard layouts and input devices
4. **High Contrast**: Ensure sufficient contrast ratios (WCAG AA minimum)
5. **Reduce Motion**: Verify all animations are properly disabled

## Future Enhancements

Possible additions:
- Audio cues for important events
- Customizable color schemes
- Adjustable game speed
- Button mashing assistance
- Dyslexia-friendly fonts
- Language/localization support

## Compliance

These features help meet:
- **WCAG 2.1** (Web Content Accessibility Guidelines)
- **CVAA** (21st Century Communications and Video Accessibility Act)
- **Game Accessibility Guidelines** by AbleGamers, SpecialEffect, and others

## Resources

- [Game Accessibility Guidelines](http://gameaccessibilityguidelines.com/)
- [Colorblind Research Papers](https://www.color-blindness.com/)
- [Godot Accessibility Documentation](https://docs.godotengine.org/en/stable/tutorials/accessibility/)
