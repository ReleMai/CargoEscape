# ==============================================================================
# TEST SCRIPT FOR NEW SHIP ASSETS AND INTERIOR DESIGNS
# ==============================================================================
# This script validates that all new room types and decorations are properly
# defined and can be generated without errors.
# ==============================================================================

extends Node

const RoomTypesClass = preload("res://scripts/data/room_types.gd")
const ShipTypesClass = preload("res://scripts/data/ship_types.gd")
const ShipDecorationsClass = preload("res://scripts/boarding/ship_decorations.gd")


func _ready() -> void:
	print("=== Testing New Ship Assets and Interior Designs ===\n")
	
	test_new_room_types()
	test_ship_hull_variants()
	test_decoration_generation()
	
	print("\n=== All Tests Complete ===")
	# Exit after tests
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()


func test_new_room_types() -> void:
	print("Testing New Room Types:")
	print("-" * 50)
	
	var new_room_types = [
		# Tier 1
		RoomTypesClass.Type.MAINTENANCE_BAY,
		RoomTypesClass.Type.PILOT_CABIN,
		RoomTypesClass.Type.FUEL_STORAGE,
		# Tier 2
		RoomTypesClass.Type.GALLEY,
		RoomTypesClass.Type.HYDROPONIC_BAY,
		RoomTypesClass.Type.COMMUNICATIONS,
		RoomTypesClass.Type.RECREATION_ROOM,
		# Tier 3
		RoomTypesClass.Type.BOARDROOM,
		RoomTypesClass.Type.EXECUTIVE_BEDROOM,
		RoomTypesClass.Type.PRIVATE_BAR,
		RoomTypesClass.Type.ART_GALLERY,
		RoomTypesClass.Type.SPA,
		# Tier 4
		RoomTypesClass.Type.TACTICAL_OPERATIONS,
		RoomTypesClass.Type.BRIG,
		RoomTypesClass.Type.TRAINING_ROOM,
		RoomTypesClass.Type.DRONE_BAY,
		RoomTypesClass.Type.MESS_HALL,
		# Tier 5
		RoomTypesClass.Type.INTERROGATION,
		RoomTypesClass.Type.SPECIMEN_LAB,
		RoomTypesClass.Type.SECURE_COMMS,
		RoomTypesClass.Type.EXPERIMENTAL_WEAPONS,
		RoomTypesClass.Type.ESCAPE_PODS
	]
	
	var success_count = 0
	var fail_count = 0
	
	for room_type in new_room_types:
		var room_data = RoomTypesClass.get_room(room_type)
		if room_data:
			print("  ✓ %s: %s" % [room_data.display_name, room_data.description])
			
			# Validate room has containers assigned
			if room_data.max_containers > 0:
				print("    - Containers: %d-%d" % [room_data.min_containers, room_data.max_containers])
			
			# Validate decoration tags
			if not room_data.decoration_tags.is_empty():
				print("    - Decorations: %s" % [", ".join(room_data.decoration_tags)])
			
			success_count += 1
		else:
			print("  ✗ Failed to load room type: %s" % room_type)
			fail_count += 1
	
	print("\nRoom Types Test: %d passed, %d failed\n" % [success_count, fail_count])


func test_ship_hull_variants() -> void:
	print("Testing Ship Hull Variants:")
	print("-" * 50)
	
	var tiers = [
		ShipTypesClass.Tier.CARGO_SHUTTLE,
		ShipTypesClass.Tier.FREIGHT_HAULER,
		ShipTypesClass.Tier.CORPORATE_TRANSPORT,
		ShipTypesClass.Tier.MILITARY_FRIGATE,
		ShipTypesClass.Tier.BLACK_OPS_VESSEL
	]
	
	for tier in tiers:
		var ship_data = ShipTypesClass.get_ship(tier)
		if ship_data:
			print("  %s:" % ship_data.display_name)
			if not ship_data.hull_variants.is_empty():
				print("    Variants: %d" % ship_data.hull_variants.size())
				for variant in ship_data.hull_variants:
					print("      - %s" % variant.variant_name)
			else:
				print("    ✗ No variants defined")
	
	print()


func test_decoration_generation() -> void:
	print("Testing Decoration Generation:")
	print("-" * 50)
	
	var decorations = ShipDecorationsClass.new()
	decorations.set_colors(Color.DIM_GRAY, Color.DARK_GRAY, Color.GRAY)
	
	var test_rooms = [
		"maintenance_bay",
		"pilot_cabin",
		"fuel_storage",
		"galley",
		"hydroponic_bay",
		"communications",
		"recreation_room",
		"boardroom",
		"executive_bedroom",
		"private_bar",
		"art_gallery",
		"spa",
		"tactical_operations",
		"brig",
		"training_room",
		"drone_bay",
		"mess_hall",
		"interrogation",
		"specimen_lab",
		"secure_comms",
		"experimental_weapons",
		"escape_pods"
	]
	
	var test_rect = Rect2(0, 0, 200, 150)
	
	for room_name in test_rooms:
		decorations.clear_decorations()
		decorations.generate_for_room(test_rect, room_name, 12345)
		
		var decoration_count = decorations._decorations.size()
		if decoration_count > 0:
			print("  ✓ %s: %d decorations" % [room_name, decoration_count])
		else:
			print("  - %s: No decorations (may be intentional)" % room_name)
	
	print()
