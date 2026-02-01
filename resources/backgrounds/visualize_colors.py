#!/usr/bin/env python3
"""
Sector Theme Color Visualization
Generates a visual representation of the color palettes for each sector theme.
"""

def rgb_to_hex(r, g, b):
    """Convert RGB (0-1 float) to hex color"""
    return f"#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}"

def color_block(color_name, r, g, b, a=1.0):
    """Print a colored block (ANSI terminal colors)"""
    # ANSI 256 color approximation
    r_val = int(r * 5)
    g_val = int(g * 5)
    b_val = int(b * 5)
    color_code = 16 + (36 * r_val) + (6 * g_val) + b_val
    hex_code = rgb_to_hex(r, g, b)
    alpha_str = f" (α={a:.2f})" if a < 1.0 else ""
    return f"\033[48;5;{color_code}m   \033[0m {hex_code}{alpha_str} {color_name}"

print("=" * 80)
print("SECTOR THEME COLOR PALETTES")
print("=" * 80)
print()

# CCG - Trading Hub
print("🟠 TRADING HUB (CCG Territory)")
print("  Warm orange/yellow nebula, busy with ship traffic")
print()
print("  Nebula Colors:")
print("    " + color_block("Dark orange-brown", 0.4, 0.25, 0.1, 0.15))
print("    " + color_block("Orange", 0.5, 0.35, 0.15, 0.18))
print("    " + color_block("Light orange", 0.6, 0.45, 0.2, 0.12))
print("    " + color_block("Yellow-orange", 0.55, 0.5, 0.25, 0.1))
print()
print("  Star Colors:")
print("    " + color_block("Warm white", 1.0, 0.95, 0.8))
print("    " + color_block("Yellow-white", 1.0, 0.9, 0.7))
print("    " + color_block("Orange-white", 1.0, 0.85, 0.6))
print("    " + color_block("Golden", 0.95, 0.8, 0.5))
print()
print("  Ambient: " + color_block("Warm dark", 0.06, 0.04, 0.02))
print("  Glow: " + color_block("Gold glow", 1.0, 0.84, 0.0, 0.3))
print()

# NEX - Danger Zone
print("🔴 DANGER ZONE (NEX Territory)")
print("  Red/crimson nebula, debris fields, destroyed ship wrecks")
print()
print("  Nebula Colors:")
print("    " + color_block("Dark red", 0.4, 0.05, 0.05, 0.2))
print("    " + color_block("Crimson", 0.6, 0.1, 0.1, 0.18))
print("    " + color_block("Red-orange", 0.7, 0.15, 0.1, 0.15))
print("    " + color_block("Dark crimson", 0.5, 0.08, 0.15, 0.12))
print()
print("  Star Colors:")
print("    " + color_block("Slightly red white", 1.0, 0.9, 0.9))
print("    " + color_block("Pink-white", 1.0, 0.8, 0.8))
print("    " + color_block("Red-orange", 1.0, 0.7, 0.6))
print("    " + color_block("Red", 0.9, 0.6, 0.6))
print()
print("  Ambient: " + color_block("Red-tinted dark", 0.08, 0.02, 0.02))
print("  Glow: " + color_block("Red glow", 0.8, 0.2, 0.2, 0.4))
print()

# GDF - Military Sector
print("🔵 MILITARY SECTOR (GDF Territory)")
print("  Blue/white clean space, patrol ships visible, structured formations")
print()
print("  Nebula Colors (Low Density):")
print("    " + color_block("Dark blue", 0.1, 0.15, 0.3, 0.08))
print("    " + color_block("Blue", 0.15, 0.2, 0.35, 0.1))
print("    " + color_block("Light blue", 0.2, 0.25, 0.4, 0.06))
print("    " + color_block("Navy blue", 0.12, 0.18, 0.32, 0.05))
print()
print("  Star Colors:")
print("    " + color_block("Cool white", 0.9, 0.95, 1.0))
print("    " + color_block("Blue-white", 0.85, 0.9, 1.0))
print("    " + color_block("Light blue", 0.8, 0.85, 0.95))
print("    " + color_block("Bright white", 0.95, 0.98, 1.0))
print()
print("  Ambient: " + color_block("Blue-tinted dark", 0.02, 0.03, 0.06))
print("  Glow: " + color_block("Blue glow", 0.3, 0.5, 1.0, 0.25))
print()

# SYN - Tech Nexus
print("🔷 TECH NEXUS (SYN Territory)")
print("  Cyan/teal glow, digital artifacts/glitches, satellite arrays")
print()
print("  Nebula Colors:")
print("    " + color_block("Dark teal", 0.05, 0.2, 0.25, 0.15))
print("    " + color_block("Teal", 0.1, 0.3, 0.35, 0.18))
print("    " + color_block("Cyan", 0.15, 0.35, 0.4, 0.12))
print("    " + color_block("Deep cyan", 0.08, 0.25, 0.3, 0.1))
print()
print("  Star Colors:")
print("    " + color_block("Cyan-white", 0.7, 0.9, 1.0))
print("    " + color_block("Bright cyan", 0.5, 0.85, 0.95))
print("    " + color_block("Electric cyan", 0.6, 1.0, 1.0))
print("    " + color_block("Deep cyan", 0.4, 0.8, 0.9))
print()
print("  Ambient: " + color_block("Cyan-tinted dark", 0.01, 0.03, 0.04))
print("  Glow: " + color_block("Cyan glow", 0.0, 0.85, 0.88, 0.35))
print()

# IND - Frontier
print("🟢 FRONTIER (IND Territory)")
print("  Mixed colors chaotic, asteroid belts, old equipment floating")
print()
print("  Nebula Colors:")
print("    " + color_block("Brown-gray", 0.25, 0.2, 0.15, 0.12))
print("    " + color_block("Green-gray", 0.2, 0.25, 0.2, 0.1))
print("    " + color_block("Purple-gray", 0.3, 0.25, 0.3, 0.08))
print("    " + color_block("Mixed gray-green", 0.25, 0.3, 0.25, 0.1))
print("    " + color_block("Dusty brown", 0.35, 0.3, 0.2, 0.12))
print()
print("  Star Colors:")
print("    " + color_block("Dusty white", 0.9, 0.9, 0.85))
print("    " + color_block("Green-white", 0.85, 0.9, 0.8))
print("    " + color_block("Warm white", 0.9, 0.85, 0.8))
print("    " + color_block("Gray-white", 0.8, 0.85, 0.85))
print("    " + color_block("Off-white", 0.95, 0.9, 0.85))
print()
print("  Ambient: " + color_block("Neutral dark", 0.04, 0.04, 0.03))
print("  Glow: " + color_block("Green glow", 0.5, 0.8, 0.5, 0.2))
print()

print("=" * 80)
print("THEME COMPARISON TABLE")
print("=" * 80)
print()
print("┌──────────┬─────────────┬──────────────┬──────────────┬──────────────┐")
print("│ Faction  │ Nebula      │ Stars        │ Atmosphere   │ Traffic      │")
print("├──────────┼─────────────┼──────────────┼──────────────┼──────────────┤")
print("│ CCG      │ Orange/Gold │ Warm tones   │ Busy         │ High (0.8)   │")
print("│ NEX      │ Red/Crimson │ Red-tinted   │ Dangerous    │ None         │")
print("│ GDF      │ Blue (low)  │ Cool white   │ Structured   │ Medium (0.5) │")
print("│ SYN      │ Cyan/Teal   │ Electric     │ Mysterious   │ Low (0.3)    │")
print("│ IND      │ Mixed/Dust  │ Neutral      │ Chaotic      │ Low (0.2)    │")
print("└──────────┴─────────────┴──────────────┴──────────────┴──────────────┘")
print()

print("=" * 80)
print("ENVIRONMENTAL FEATURES")
print("=" * 80)
print()
features_table = {
    "CCG": ["Ships ✓", "Stations ✓", "Cargo ✓"],
    "NEX": ["Debris ✓", "Wrecks ✓", "Weapons Fire ✓"],
    "GDF": ["Patrols ✓", "Beacons ✓"],
    "SYN": ["Satellites ✓", "Energy Streams ✓"],
    "IND": ["Debris ✓", "Asteroids ✓", "Cargo ✓"],
}

for faction, features in features_table.items():
    print(f"  {faction:3s}: {', '.join(features)}")

print()
print("=" * 80)
print("✓ All 5 sector themes implemented with unique visual identities")
print("=" * 80)
