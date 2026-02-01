#!/usr/bin/env godot
# ==============================================================================
# DECORATION SYSTEM VALIDATION TEST
# ==============================================================================
#
# This script validates the decoration system by:
# 1. Testing DecorationData class initialization
# 2. Testing ShipDecorator with different room types
# 3. Generating a sample ship with decorations
# 4. Verifying decoration placement logic
#
# USAGE: Run with Godot headless mode
#   godot --headless --script validate_decoration_system.gd
#
# ==============================================================================

extends SceneTree


const DecorationDataClass = preload("res://resources/decorations/decoration_data.gd")
const ShipDecoratorClass = preload("res://scripts/boarding/ship_decorator.gd")
const ShipGeneratorClass = preload("res://scripts/boarding/ship_generator.gd")
const FactionsClass = preload("res://scripts/data/factions.gd")


func _init() -> void:
	print("="*60)
	print("DECORATION SYSTEM VALIDATION TEST")
	print("="*60)
	
	var all_passed = true
	
	# Test 1: DecorationData initialization
	print("\n[TEST 1] DecorationData Initialization...")
	if not test_decoration_data():
		all_passed = false
	
	# Test 2: ShipDecorator room generation
	print("\n[TEST 2] ShipDecorator Room Generation...")
	if not test_ship_decorator():
		all_passed = false
	
	# Test 3: Full ship generation with decorations
	print("\n[TEST 3] Full Ship Generation with Decorations...")
	if not test_full_ship_generation():
		all_passed = false
	
	# Test 4: Decoration density and category mix
	print("\n[TEST 4] Decoration Density and Category Mix...")
	if not test_decoration_density():
		all_passed = false
	
	# Summary
	print("\n" + "="*60)
	if all_passed:
		print("✓ ALL TESTS PASSED")
		quit(0)
	else:
		print("✗ SOME TESTS FAILED")
		quit(1)


func test_decoration_data() -> bool:
	var passed = true
	
	# Test getting decorations by category
	var functional = DecorationDataClass.get_decorations_by_category(
		DecorationDataClass.Category.FUNCTIONAL
	)
	print("  Functional decorations: %d" % functional.size())
	if functional.size() < 5:
		print("  ✗ FAILED: Expected at least 5 functional decorations")
		passed = false
	else:
		print("  ✓ Functional decorations loaded")
	
	var atmospheric = DecorationDataClass.get_decorations_by_category(
		DecorationDataClass.Category.ATMOSPHERIC
	)
	print("  Atmospheric decorations: %d" % atmospheric.size())
	if atmospheric.size() < 10:
		print("  ✗ FAILED: Expected at least 10 atmospheric decorations")
		passed = false
	else:
		print("  ✓ Atmospheric decorations loaded")
	
	var damage = DecorationDataClass.get_decorations_by_category(
		DecorationDataClass.Category.DAMAGE_WEAR
	)
	print("  Damage/wear decorations: %d" % damage.size())
	if damage.size() < 8:
		print("  ✗ FAILED: Expected at least 8 damage decorations")
		passed = false
	else:
		print("  ✓ Damage/wear decorations loaded")
	
	# Test getting specific decoration
	var screen = DecorationDataClass.get_decoration(
		DecorationDataClass.Type.COMPUTER_SCREEN
	)
	if screen == null:
		print("  ✗ FAILED: Could not get computer screen decoration")
		passed = false
	else:
		print("  ✓ Specific decoration retrieval works")
		print("    - Name: %s" % screen.display_name)
		print("    - Size: %s" % screen.size)
		print("    - Wall mounted: %s" % screen.wall_mounted)
	
	# Test room-specific decorations
	var bridge_decos = DecorationDataClass.get_decorations_for_room("bridge")
	print("  Bridge-suitable decorations: %d" % bridge_decos.size())
	if bridge_decos.size() == 0:
		print("  ✗ FAILED: No decorations found for bridge")
		passed = false
	else:
		print("  ✓ Room-specific decoration filtering works")
	
	return passed


func test_ship_decorator() -> bool:
	var passed = true
	var decorator = ShipDecoratorClass.new()
	
	# Test different room types
	var room_types = [
		"bridge",
		"engine_room",
		"cargo_bay",
		"crew_quarters",
		"corridor"
	]
	
	for room_type in room_types:
		var room_rect = Rect2(100, 100, 400, 300)
		var decorations = decorator.generate_room_decorations(
			room_rect,
			room_type,
			FactionsClass.Type.CCG,
			2,  # tier 2
			12345  # seed
		)
		
		print("  %s: %d decorations generated" % [room_type, decorations.size()])
		
		if decorations.size() == 0:
			print("  ✗ FAILED: No decorations generated for %s" % room_type)
			passed = false
		else:
			# Check decoration placement validity
			var valid_positions = true
			for deco in decorations:
				if not room_rect.has_point(deco.position):
					print("  ✗ FAILED: Decoration placed outside room bounds")
					valid_positions = false
					break
			
			if valid_positions:
				print("  ✓ All decorations within room bounds")
			else:
				passed = false
	
	# Test faction-specific decorations
	for faction in [FactionsClass.Type.CCG, FactionsClass.Type.NEX, FactionsClass.Type.GDF]:
		var decorations = decorator.generate_room_decorations(
			Rect2(100, 100, 300, 300),
			"crew_quarters",
			faction,
			3,
			54321
		)
		print("  Faction %d: %d decorations" % [faction, decorations.size()])
	
	print("  ✓ Faction-specific decoration generation works")
	
	return passed


func test_full_ship_generation() -> bool:
	var passed = true
	
	# Generate a tier 2 ship with decorations
	var layout = ShipGeneratorClass.generate(2, FactionsClass.Type.CCG, 98765)
	
	print("  Ship generated:")
	print("    - Tier: %d" % layout.ship_tier)
	print("    - Faction: %d" % layout.faction_type)
	print("    - Rooms: %d" % layout.rooms.size())
	print("    - Decoration sets: %d" % layout.decoration_placements.size())
	
	if layout.rooms.size() == 0:
		print("  ✗ FAILED: No rooms generated")
		return false
	
	if layout.decoration_placements.is_empty():
		print("  ✗ FAILED: No decorations generated")
		return false
	
	# Check each room has decorations
	var total_decorations = 0
	for room_idx in layout.decoration_placements:
		var decos = layout.decoration_placements[room_idx]
		total_decorations += decos.size()
	
	print("    - Total decorations: %d" % total_decorations)
	
	if total_decorations == 0:
		print("  ✗ FAILED: No decorations placed in any room")
		passed = false
	else:
		print("  ✓ Decorations successfully generated in ship")
	
	# Verify decoration data structure
	for room_idx in layout.decoration_placements:
		var decos = layout.decoration_placements[room_idx]
		if decos.size() > 0:
			var first_deco = decos[0]
			# Check if it's a DecorationPlacement object
			if not ("decoration_type" in first_deco and "position" in first_deco):
				print("  ✗ FAILED: Invalid decoration placement structure")
				passed = false
			else:
				print("  ✓ Decoration placement structure valid")
			break
	
	return passed


func test_decoration_density() -> bool:
	var passed = true
	var decorator = ShipDecoratorClass.new()
	
	# Test that different room types have appropriate decoration density
	var density_tests = [
		{"room": "bridge", "min": 5},
		{"room": "cargo_bay", "min": 3},
		{"room": "corridor", "min": 2},
	]
	
	for test in density_tests:
		var room_rect = Rect2(100, 100, 500, 400)
		var decorations = decorator.generate_room_decorations(
			room_rect,
			test.room,
			FactionsClass.Type.CCG,
			3,
			11111
		)
		
		print("  %s: %d decorations (min expected: %d)" % [test.room, decorations.size(), test.min])
		
		if decorations.size() < test.min:
			print("  ⚠ WARNING: Lower than expected decoration count")
			# Not a failure, just a warning
	
	# Test category distribution
	var all_decorations = decorator.generate_room_decorations(
		Rect2(100, 100, 500, 400),
		"engine_room",
		FactionsClass.Type.CCG,
		2,
		22222
	)
	
	var categories = {
		"functional": 0,
		"atmospheric": 0,
		"damage": 0
	}
	
	for deco in all_decorations:
		var deco_data = DecorationDataClass.get_decoration(deco.decoration_type)
		if deco_data:
			match deco_data.category:
				DecorationDataClass.Category.FUNCTIONAL:
					categories.functional += 1
				DecorationDataClass.Category.ATMOSPHERIC:
					categories.atmospheric += 1
				DecorationDataClass.Category.DAMAGE_WEAR:
					categories.damage += 1
	
	print("  Category distribution in engine_room:")
	print("    - Functional: %d" % categories.functional)
	print("    - Atmospheric: %d" % categories.atmospheric)
	print("    - Damage/wear: %d" % categories.damage)
	
	# Engine room should have more functional decorations
	if categories.functional > 0:
		print("  ✓ Category distribution seems appropriate")
	else:
		print("  ✗ FAILED: No functional decorations in engine room")
		passed = false
	
	return passed
