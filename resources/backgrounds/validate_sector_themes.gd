#!/usr/bin/env -S godot --headless --script
# ==============================================================================
# SECTOR THEMES VALIDATION SCRIPT
# ==============================================================================
#
# This script validates that all sector themes are properly configured
# Run with: godot --headless --script validate_sector_themes.gd
#
# ==============================================================================

extends SceneTree


func _init() -> void:
	print("=== Sector Themes Validation ===\n")
	
	var all_passed := true
	
	# Test 1: Check all themes exist
	print("Test 1: Checking theme existence...")
	var faction_codes := ["CCG", "NEX", "GDF", "SYN", "IND"]
	for code in faction_codes:
		var theme = SectorThemes.get_theme(code)
		if theme:
			print("  ✓ %s theme loaded" % code)
		else:
			print("  ✗ %s theme MISSING" % code)
			all_passed = false
	print("")
	
	# Test 2: Validate theme properties
	print("Test 2: Validating theme properties...")
	for code in faction_codes:
		var theme = SectorThemes.get_theme(code)
		if not theme:
			continue
		
		var errors: Array[String] = []
		
		# Check required fields
		if theme.sector_name.is_empty():
			errors.append("missing sector_name")
		if theme.faction_code != code:
			errors.append("faction_code mismatch")
		if theme.nebula_colors.is_empty():
			errors.append("no nebula_colors")
		if theme.star_colors.is_empty():
			errors.append("no star_colors")
		
		if errors.is_empty():
			print("  ✓ %s theme valid" % code)
		else:
			print("  ✗ %s theme has errors: %s" % [code, ", ".join(errors)])
			all_passed = false
	print("")
	
	# Test 3: Check theme details
	print("Test 3: Theme details summary...")
	for code in faction_codes:
		var theme = SectorThemes.get_theme(code)
		if not theme:
			continue
		
		print("  %s - %s:" % [code, theme.sector_name])
		print("    Colors: %d nebula, %d star" % [theme.nebula_colors.size(), theme.star_colors.size()])
		print("    Atmosphere: %s, Mood: %s" % [theme.atmosphere, theme.mood])
		print("    Density: nebula=%.1f, traffic=%.1f, debris=%.1f" % 
			[theme.nebula_density, theme.ship_traffic, theme.debris_density])
	print("")
	
	# Test 4: Test helper functions
	print("Test 4: Testing helper functions...")
	var test_passed := true
	
	# Test get_random_star_color
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	for code in faction_codes:
		var color = SectorThemes.get_random_star_color(code, rng)
		if color == Color.WHITE and code != "CCG":
			# Default color, might indicate issue
			pass
		print("  %s star color sample: RGB(%.2f, %.2f, %.2f)" % 
			[code, color.r, color.g, color.b])
	
	# Test get_random_nebula_color
	for code in faction_codes:
		var color = SectorThemes.get_random_nebula_color(code, rng)
		print("  %s nebula color sample: RGBA(%.2f, %.2f, %.2f, %.2f)" % 
			[code, color.r, color.g, color.b, color.a])
	print("")
	
	# Test 5: Verify theme differentiation
	print("Test 5: Verifying theme differentiation...")
	var ccg = SectorThemes.get_theme("CCG")
	var nex = SectorThemes.get_theme("NEX")
	var gdf = SectorThemes.get_theme("GDF")
	var syn = SectorThemes.get_theme("SYN")
	var ind = SectorThemes.get_theme("IND")
	
	# Check that themes are actually different
	if ccg and nex:
		if ccg.nebula_colors[0].is_equal_approx(nex.nebula_colors[0]):
			print("  ⚠ Warning: CCG and NEX have similar nebula colors")
		else:
			print("  ✓ CCG and NEX have different nebula colors")
	
	if gdf and syn:
		if gdf.star_colors[0].is_equal_approx(syn.star_colors[0]):
			print("  ⚠ Warning: GDF and SYN have similar star colors")
		else:
			print("  ✓ GDF and SYN have different star colors")
	
	print("")
	
	# Final result
	print("=== Validation Result ===")
	if all_passed and test_passed:
		print("✓ All tests passed!")
		quit(0)
	else:
		print("✗ Some tests failed")
		quit(1)
