# Cargo Escape - Asset Folder Structure

This folder contains all game assets organized by type.

## Folder Structure

```
assets/
├── sprites/           # All image files
│   ├── player/        # Player rocket ship sprites
│   ├── enemies/       # Asteroid and enemy sprites
│   └── background/    # Star fields and space backgrounds
│
├── audio/             # Sound files (future)
│   ├── sfx/           # Sound effects
│   └── music/         # Background music
│
└── fonts/             # Custom fonts (future)
```

## Adding Your Own Sprites

### Player Sprite
1. Create or download a rocket ship image (PNG recommended)
2. Recommended size: 60x40 pixels (or proportional)
3. Save to `assets/sprites/player/rocket.png`
4. In Godot, open `scenes/player.tscn`
5. Select the `Sprite2D` node
6. Drag your image to the `Texture` property in Inspector
7. Delete the `Placeholder` ColorRect node

### Enemy Sprites
1. Create or download asteroid images (PNG)
2. Recommended size: 50x50 pixels
3. Save to `assets/sprites/enemies/asteroid.png`
4. In Godot, open `scenes/enemy.tscn`
5. Select the `Sprite2D` node
6. Drag your image to the `Texture` property
7. Delete the `Placeholder` ColorRect node

### Background Stars
For the parallax background, you'll want:
- `stars_far.png` - Small, dim stars (tileable)
- `stars_mid.png` - Medium stars (tileable)
- `stars_close.png` - Larger, brighter stars (tileable)

Recommended size: 1920x1080 pixels or larger

## Free Asset Resources

Here are some places to find free game assets:

- **Kenney.nl** - Free game assets (CC0 license)
- **OpenGameArt.org** - Community game assets
- **itch.io** - Many free asset packs
- **Pixabay** - Free images and illustrations

## Creating Simple Placeholder Art

You can create simple sprites in:
- **Piskel** (free, online pixel art editor)
- **Aseprite** (paid, excellent for pixel art)
- **GIMP** (free, full-featured image editor)
- **Paint.NET** (free, Windows only)

Tips:
- Use PNG format with transparency
- Keep sprites small for retro look (32x32 to 64x64)
- Use limited color palettes for cohesive look
