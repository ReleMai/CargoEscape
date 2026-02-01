#!/usr/bin/env python3
"""
Update item_database.gd to use new PNG sprites in category directories.

This script updates all "icon" paths from:
  res://assets/sprites/items/item_name.svg
to:
  res://assets/sprites/items/category/item_name.png
"""

import re
from pathlib import Path

# Item to category mapping
ITEM_CATEGORIES = {
    # Cargo
    'scrap_metal': 'cargo',
    'scrap_plastics': 'cargo',
    'scrap_electronics': 'cargo',
    'scrap_mechanical': 'cargo',
    'wire_bundle': 'cargo',
    'hull_fragment': 'cargo',
    'corroded_pipe': 'cargo',
    'broken_lens': 'cargo',
    'copper_wire': 'cargo',
    'coolant_tube': 'cargo',
    
    # Tech
    'data_chip': 'tech',
    'encrypted_drive': 'tech',
    'processor_unit': 'tech',
    'quantum_cpu': 'tech',
    'nav_computer': 'tech',
    'nav_beacon': 'tech',
    'targeting_array': 'tech',
    'quantum_core': 'tech',
    'fusion_cell': 'tech',
    'fuel_cell': 'tech',
    'plasma_coil': 'tech',
    
    # Weapons
    'weapon_core': 'weapons',
    
    # Medical
    'med_kit': 'medical',
    'cryo_sample': 'medical',
    'oxygen_canister': 'medical',
    
    # Contraband
    'dark_matter_vial': 'contraband',
    
    # Luxury
    'gold_bar': 'luxury',
    'singularity_gem': 'luxury',
    'ancient_relic': 'luxury',
    'alien_artifact': 'luxury',
    'captains_log': 'luxury',
    'rare_alloy': 'luxury',
    'void_shard': 'luxury',
    
    # Faction
    'module_engine_booster': 'faction',
    'module_laser_amp': 'faction',
    'module_scanner': 'faction',
    'module_shield': 'faction',
    'module_targeting': 'faction',
    'module_thrusters': 'faction',
    'stealth_plating': 'faction',
    'gravity_dampener': 'faction',
    'prototype_engine': 'faction',
}

def update_icon_path(line):
    """Update a line containing an icon path."""
    # Pattern: "icon": "res://assets/sprites/items/ITEMNAME.svg"
    pattern = r'"icon":\s*"res://assets/sprites/items/([^/]+)\.svg"'
    
    def replace_func(match):
        item_name = match.group(1)
        category = ITEM_CATEGORIES.get(item_name)
        if category:
            return f'"icon": "res://assets/sprites/items/{category}/{item_name}.png"'
        else:
            # Item not in mapping, leave as is or warn
            print(f"  ⚠ Warning: {item_name} not in category mapping")
            return match.group(0)
    
    return re.sub(pattern, replace_func, line)

def main():
    """Main execution."""
    script_dir = Path(__file__).parent.parent
    database_file = script_dir / 'scripts' / 'loot' / 'item_database.gd'
    
    if not database_file.exists():
        print(f"Error: {database_file} not found")
        return
    
    print("Updating item_database.gd icon paths...")
    
    # Read the file
    with open(database_file, 'r') as f:
        lines = f.readlines()
    
    # Update lines
    updated_lines = []
    changes = 0
    for line in lines:
        if '"icon":' in line and '.svg"' in line:
            new_line = update_icon_path(line)
            if new_line != line:
                changes += 1
                # Extract item name for reporting
                match = re.search(r'/([^/]+)\.png"', new_line)
                if match:
                    item_name = match.group(1)
                    category_match = re.search(r'/items/([^/]+)/', new_line)
                    category = category_match.group(1) if category_match else 'unknown'
                    print(f"  ✓ {item_name} -> {category}/")
            updated_lines.append(new_line)
        else:
            updated_lines.append(line)
    
    # Write back
    with open(database_file, 'w') as f:
        f.writelines(updated_lines)
    
    print(f"\nUpdated {changes} icon paths in item_database.gd")

if __name__ == '__main__':
    main()
