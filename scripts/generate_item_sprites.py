#!/usr/bin/env python3
"""
Generate 64x64 PNG item sprites with rarity visual effects.

This script:
1. Converts existing SVG sprites to PNG format
2. Adds rarity-based visual effects (borders, glows)
3. Organizes sprites into category directories
4. Creates additional sprites to reach minimum 50 items
"""

import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import cairosvg

# Rarity definitions matching ItemData.gd
RARITY_EFFECTS = {
    'common': {
        'color': (180, 180, 180, 255),  # Gray
        'border': False,
        'glow': False
    },
    'uncommon': {
        'color': (77, 204, 77, 255),  # Green
        'border': False,
        'glow': True,
        'glow_strength': 3
    },
    'rare': {
        'color': (77, 128, 255, 255),  # Blue
        'border': True,
        'glow': True,
        'glow_strength': 4
    },
    'epic': {
        'color': (179, 77, 230, 255),  # Purple
        'border': True,
        'glow': True,
        'glow_strength': 5
    },
    'legendary': {
        'color': (255, 204, 51, 255),  # Gold
        'border': True,
        'glow': True,
        'glow_strength': 6,
        'sparkle': True
    }
}

# Item categorization based on item_database.gd
ITEM_CATEGORIES = {
    'cargo': [
        'scrap_metal', 'scrap_plastics', 'scrap_electronics', 'scrap_mechanical',
        'hull_fragment', 'corroded_pipe', 'wire_bundle', 'copper_wire',
        'broken_lens', 'coolant_tube'
    ],
    'tech': [
        'data_chip', 'encrypted_drive', 'processor_unit', 'quantum_cpu',
        'nav_computer', 'targeting_array', 'nav_beacon', 'quantum_core',
        'fusion_cell', 'fuel_cell', 'plasma_coil'
    ],
    'weapons': [
        'weapon_core'
    ],
    'medical': [
        'med_kit', 'cryo_sample', 'oxygen_canister'
    ],
    'contraband': [
        'dark_matter_vial'
    ],
    'luxury': [
        'gold_bar', 'singularity_gem', 'ancient_relic', 'alien_artifact',
        'captains_log', 'rare_alloy', 'void_shard'
    ],
    'faction': [
        'module_engine_booster', 'module_laser_amp', 'module_scanner',
        'module_shield', 'module_targeting', 'module_thrusters',
        'stealth_plating', 'gravity_dampener', 'prototype_engine'
    ]
}

# Rarity assignment for existing items
ITEM_RARITIES = {
    # Common (0)
    'scrap_metal': 'common',
    'scrap_plastics': 'common',
    'scrap_electronics': 'common',
    'scrap_mechanical': 'common',
    'wire_bundle': 'common',
    'hull_fragment': 'common',
    'corroded_pipe': 'common',
    'broken_lens': 'common',
    
    # Uncommon (1)
    'copper_wire': 'uncommon',
    'coolant_tube': 'uncommon',
    'data_chip': 'uncommon',
    'fuel_cell': 'uncommon',
    'med_kit': 'uncommon',
    'oxygen_canister': 'uncommon',
    'nav_beacon': 'uncommon',
    
    # Rare (2)
    'encrypted_drive': 'rare',
    'processor_unit': 'rare',
    'plasma_coil': 'rare',
    'cryo_sample': 'rare',
    'nav_computer': 'rare',
    'targeting_array': 'rare',
    'weapon_core': 'rare',
    'rare_alloy': 'rare',
    'stealth_plating': 'rare',
    
    # Epic (3)
    'quantum_cpu': 'epic',
    'fusion_cell': 'epic',
    'quantum_core': 'epic',
    'gravity_dampener': 'epic',
    'module_engine_booster': 'epic',
    'module_laser_amp': 'epic',
    'module_scanner': 'epic',
    'module_shield': 'epic',
    'module_targeting': 'epic',
    'module_thrusters': 'epic',
    'gold_bar': 'epic',
    'dark_matter_vial': 'epic',
    
    # Legendary (4)
    'prototype_engine': 'legendary',
    'singularity_gem': 'legendary',
    'ancient_relic': 'legendary',
    'alien_artifact': 'legendary',
    'void_shard': 'legendary',
    'captains_log': 'legendary'
}


def add_rarity_effect(image, rarity):
    """Add visual effects based on rarity level."""
    effects = RARITY_EFFECTS.get(rarity, RARITY_EFFECTS['common'])
    width, height = image.size
    
    # Create a new image with alpha channel
    result = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    
    # Add glow effect
    if effects.get('glow'):
        glow_strength = effects.get('glow_strength', 3)
        color = effects['color']
        
        # Create glow layer
        glow = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow)
        
        # Draw a soft glow around the edges
        for i in range(glow_strength):
            alpha = int(60 - (i * 15))  # Fade out the glow
            glow_color = (color[0], color[1], color[2], alpha)
            glow_draw.rectangle([i, i, width-i-1, height-i-1], 
                               outline=glow_color, width=1)
        
        # Blur the glow for smoother effect
        glow = glow.filter(ImageFilter.GaussianBlur(radius=2))
        result.paste(glow, (0, 0), glow)
    
    # Paste the original image on top
    result.paste(image, (0, 0), image)
    
    # Add border effect
    if effects.get('border'):
        border_draw = ImageDraw.Draw(result)
        color = effects['color']
        border_color = (color[0], color[1], color[2], 255)
        
        # Draw 2px border
        border_draw.rectangle([0, 0, width-1, height-1], 
                             outline=border_color, width=2)
        border_draw.rectangle([1, 1, width-2, height-2], 
                             outline=border_color, width=1)
    
    # Add sparkle effect for legendary
    if effects.get('sparkle'):
        sparkle_draw = ImageDraw.Draw(result)
        color = effects['color']
        sparkle_color = (255, 255, 255, 200)
        
        # Add small sparkle points
        sparkles = [(10, 10), (width-10, 10), (width-10, height-10), (10, height-10)]
        for x, y in sparkles:
            sparkle_draw.ellipse([x-2, y-2, x+2, y+2], fill=sparkle_color)
    
    return result


def svg_to_png(svg_path, png_path, size=(64, 64)):
    """Convert SVG to PNG with specified size."""
    try:
        # Convert SVG to PNG using cairosvg
        cairosvg.svg2png(url=str(svg_path), write_to=str(png_path),
                        output_width=size[0], output_height=size[1])
        return True
    except Exception as e:
        print(f"Error converting {svg_path}: {e}")
        return False


def create_placeholder_sprite(name, category, rarity, output_path):
    """Create a simple placeholder sprite for new items."""
    # Create a 64x64 base image with transparency
    image = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    # Category-specific colors and shapes
    category_styles = {
        'cargo': {'color': (139, 90, 43), 'shape': 'box'},
        'tech': {'color': (70, 130, 180), 'shape': 'circuit'},
        'weapons': {'color': (178, 34, 34), 'shape': 'sharp'},
        'medical': {'color': (50, 205, 50), 'shape': 'cross'},
        'contraband': {'color': (220, 20, 60), 'shape': 'vial'},
        'luxury': {'color': (218, 165, 32), 'shape': 'gem'},
        'faction': {'color': (138, 43, 226), 'shape': 'emblem'}
    }
    
    style = category_styles.get(category, {'color': (128, 128, 128), 'shape': 'box'})
    base_color = style['color']
    
    # Draw shape based on category
    if style['shape'] == 'box':
        # Isometric box
        draw.polygon([(32, 15), (50, 25), (50, 45), (32, 55), (14, 45), (14, 25)],
                    fill=base_color, outline=(0, 0, 0))
    elif style['shape'] == 'circuit':
        # Circuit board pattern
        draw.rectangle([15, 20, 49, 44], fill=base_color, outline=(0, 0, 0))
        draw.line([20, 25, 44, 25], fill=(255, 215, 0), width=2)
        draw.line([20, 32, 44, 32], fill=(255, 215, 0), width=2)
        draw.line([20, 39, 44, 39], fill=(255, 215, 0), width=2)
    elif style['shape'] == 'sharp':
        # Blade/weapon shape
        draw.polygon([(32, 10), (40, 30), (35, 54), (29, 54), (24, 30)],
                    fill=base_color, outline=(0, 0, 0))
    elif style['shape'] == 'cross':
        # Medical cross
        draw.rectangle([28, 15, 36, 49], fill=base_color, outline=(0, 0, 0))
        draw.rectangle([18, 25, 46, 33], fill=base_color, outline=(0, 0, 0))
    elif style['shape'] == 'vial':
        # Container/vial
        draw.ellipse([24, 18, 40, 24], fill=(100, 100, 100), outline=(0, 0, 0))
        draw.rectangle([26, 22, 38, 50], fill=base_color, outline=(0, 0, 0))
        draw.ellipse([26, 46, 38, 52], fill=base_color, outline=(0, 0, 0))
    elif style['shape'] == 'gem':
        # Diamond/gem
        draw.polygon([(32, 15), (45, 28), (38, 50), (26, 50), (19, 28)],
                    fill=base_color, outline=(0, 0, 0))
    elif style['shape'] == 'emblem':
        # Shield emblem
        draw.polygon([(32, 12), (48, 20), (48, 42), (32, 52), (16, 42), (16, 20)],
                    fill=base_color, outline=(0, 0, 0))
    
    # Add highlight
    lighter = tuple(min(c + 40, 255) for c in base_color)
    if style['shape'] in ['box', 'gem', 'emblem']:
        draw.polygon([(32, 18), (38, 22), (38, 28), (32, 24)],
                    fill=lighter)
    
    # Add rarity effects
    result = add_rarity_effect(image, rarity)
    result.save(output_path)
    return True


def main():
    """Main script execution."""
    script_dir = Path(__file__).parent.parent
    assets_dir = script_dir / 'assets' / 'sprites' / 'items'
    
    print("=" * 70)
    print("ITEM SPRITE GENERATOR - 64x64 PNG with Rarity Effects")
    print("=" * 70)
    
    # Process existing SVG items
    print("\n1. Converting existing SVG items to PNG...")
    converted_count = 0
    
    for category, items in ITEM_CATEGORIES.items():
        category_dir = assets_dir / category
        category_dir.mkdir(exist_ok=True)
        
        for item_name in items:
            svg_file = assets_dir / f"{item_name}.svg"
            if svg_file.exists():
                # Convert to PNG
                temp_png = assets_dir / f"{item_name}_temp.png"
                png_file = category_dir / f"{item_name}.png"
                
                if svg_to_png(svg_file, temp_png):
                    # Load the PNG and add rarity effects
                    img = Image.open(temp_png)
                    rarity = ITEM_RARITIES.get(item_name, 'common')
                    result_img = add_rarity_effect(img, rarity)
                    result_img.save(png_file)
                    temp_png.unlink()  # Remove temporary file
                    
                    converted_count += 1
                    print(f"  ✓ {item_name} ({rarity}) -> {category}/")
    
    print(f"\nConverted {converted_count} existing items to PNG")
    
    # Create additional items to reach 50+
    print("\n2. Creating new placeholder items...")
    new_items = [
        # Cargo items
        ('supply_crate', 'cargo', 'common'),
        ('cargo_barrel', 'cargo', 'common'),
        ('shipping_container', 'cargo', 'uncommon'),
        
        # Tech items
        ('ai_chip', 'tech', 'rare'),
        ('hologram_projector', 'tech', 'rare'),
        
        # Weapons
        ('plasma_pistol', 'weapons', 'uncommon'),
        ('laser_rifle', 'weapons', 'rare'),
        ('ion_blade', 'weapons', 'epic'),
        
        # Medical
        ('stim_pack', 'medical', 'uncommon'),
        ('nano_bandages', 'medical', 'rare'),
        
        # Contraband
        ('neural_stims', 'contraband', 'rare'),
        ('black_market_chip', 'contraband', 'epic'),
        
        # Luxury
        ('nebula_wine', 'luxury', 'rare'),
        ('star_sapphire', 'luxury', 'epic'),
        ('ancient_scroll', 'luxury', 'legendary'),
    ]
    
    new_count = 0
    for item_name, category, rarity in new_items:
        category_dir = assets_dir / category
        png_file = category_dir / f"{item_name}.png"
        
        if not png_file.exists():
            create_placeholder_sprite(item_name, category, rarity, png_file)
            new_count += 1
            print(f"  ✓ {item_name} ({rarity}) -> {category}/")
    
    total_items = converted_count + new_count
    print(f"\n" + "=" * 70)
    print(f"COMPLETED: {total_items} total item sprites created")
    print(f"  - {converted_count} converted from SVG")
    print(f"  - {new_count} new placeholder sprites")
    print("=" * 70)
    
    # Create a summary file
    summary_file = assets_dir / 'SPRITE_MANIFEST.txt'
    with open(summary_file, 'w') as f:
        f.write("ITEM SPRITE MANIFEST\n")
        f.write("=" * 70 + "\n\n")
        f.write(f"Total Items: {total_items}\n")
        f.write(f"Format: 64x64 PNG with transparency\n")
        f.write(f"Rarity Effects: Borders and glows applied\n\n")
        
        for category, items in ITEM_CATEGORIES.items():
            f.write(f"\n{category.upper()}/\n")
            f.write("-" * 40 + "\n")
            category_dir = assets_dir / category
            if category_dir.exists():
                png_files = sorted(category_dir.glob("*.png"))
                for png_file in png_files:
                    item_name = png_file.stem
                    rarity = ITEM_RARITIES.get(item_name, 'common')
                    f.write(f"  - {item_name}.png ({rarity})\n")
    
    print(f"\nManifest created: {summary_file}")


if __name__ == '__main__':
    main()
