#!/usr/bin/env python3
"""
Generate Godot .import files for PNG item sprites.

This ensures all PNG sprites are properly configured in Godot 4.x
with correct settings for pixel art (no filtering, no mipmaps).
"""

import os
import hashlib
from pathlib import Path

def generate_uid():
    """Generate a random UID for Godot."""
    import random
    # Format: uid://dxxxxxxxxxx where x is base36
    chars = '0123456789abcdefghijklmnopqrstuvwxyz'
    uid_part = ''.join(random.choice(chars) for _ in range(13))
    return f"uid://{uid_part}"

def create_import_file(png_path, category):
    """Create a .import file for a PNG sprite."""
    png_file = Path(png_path)
    import_file = png_file.with_suffix(png_file.suffix + '.import')
    
    # Generate unique hash for this file
    file_hash = hashlib.md5(str(png_file).encode()).hexdigest()
    
    # Relative path from project root
    rel_path = png_file.relative_to(png_file.parents[4])  # Go up to project root
    godot_path = f"res://{rel_path.as_posix()}"
    
    # Import file content
    import_content = f"""[remap]

importer="texture"
type="CompressedTexture2D"
uid="{generate_uid()}"
path="res://.godot/imported/{png_file.name}-{file_hash}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="{godot_path}"
dest_files=["res://.godot/imported/{png_file.name}-{file_hash}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
filter=false
"""
    
    with open(import_file, 'w') as f:
        f.write(import_content)
    
    return import_file

def main():
    """Main execution."""
    script_dir = Path(__file__).parent.parent
    items_dir = script_dir / 'assets' / 'sprites' / 'items'
    
    print("Generating Godot .import files for PNG sprites...")
    
    categories = ['cargo', 'tech', 'weapons', 'medical', 'contraband', 'luxury', 'faction']
    total_imports = 0
    
    for category in categories:
        category_dir = items_dir / category
        if not category_dir.exists():
            continue
            
        png_files = list(category_dir.glob('*.png'))
        for png_file in png_files:
            import_file = create_import_file(png_file, category)
            print(f"  ✓ {category}/{png_file.name}")
            total_imports += 1
    
    print(f"\nGenerated {total_imports} .import files")

if __name__ == '__main__':
    main()
