# ==============================================================================
# COMPREHENSIVE ITEM DATABASE TEST
# ==============================================================================
#
# This script tests the comprehensive item database system to ensure all
# features work correctly.
#
# Run this in Godot by attaching it to a Node and running the scene.
# ==============================================================================

extends Node


func _ready() -> void:
	print("\n" + "="*80)
	print("COMPREHENSIVE ITEM DATABASE TEST")
	print("="*80 + "\n")
	
	test_database_loading()
	test_item_creation()
	test_new_properties()
	test_tag_system()
	test_faction_system()
	test_value_system()
	test_helper_functions()
	test_resource_files()
	
	print("\n" + "="*80)
	print("ALL TESTS COMPLETED")
	print("="*80 + "\n")


func test_database_loading() -> void:
	print("TEST 1: Database Loading")
	print("-" * 40)
	
	var ComprehensiveDB = preload("res://resources/items/item_database.gd")
	
	var all_items = ComprehensiveDB.get_all_comprehensive_items()
	print("✓ Total items in database: %d" % all_items.size())
	
	var all_ids = ComprehensiveDB.get_all_item_ids()
	print("✓ Item IDs retrieved: %d" % all_ids.size())
	
	# Test category counts
	var scrap_count = 0
	var component_count = 0
	var valuable_count = 0
	var epic_count = 0
	var legendary_count = 0
	
	for item_id in all_items:
		var item_def = all_items[item_id]
		match item_def.get("rarity", 0):
			0: scrap_count += 1
			1: component_count += 1
			2: valuable_count += 1
			3: epic_count += 1
			4: legendary_count += 1
	
	print("  - Common items: %d" % scrap_count)
	print("  - Uncommon items: %d" % component_count)
	print("  - Rare items: %d" % valuable_count)
	print("  - Epic items: %d" % epic_count)
	print("  - Legendary items: %d" % legendary_count)
	print()


func test_item_creation() -> void:
	print("TEST 2: Item Creation")
	print("-" * 40)
	
	var ComprehensiveDB = preload("res://resources/items/item_database.gd")
	
	# Test creating various items
	var test_items = ["scrap_metal", "data_chip", "weapon_core", "alien_artifact", "singularity_gem"]
	
	for item_id in test_items:
		var item = ComprehensiveDB.create_item_from_comprehensive_data(item_id)
		if item:
			print("✓ Created: %s (%s)" % [item.name, item.get_rarity_name()])
		else:
			print("✗ Failed to create: %s" % item_id)
	
	print()


func test_new_properties() -> void:
	print("TEST 3: New Properties")
	print("-" * 40)
	
	var ComprehensiveDB = preload("res://resources/items/item_database.gd")
	var item = ComprehensiveDB.create_item_from_comprehensive_data("weapon_core")
	
	print("Testing weapon_core properties:")
	print("  ✓ ID: %s" % item.id)
	print("  ✓ Name: %s" % item.name)
	print("  ✓ Tags: %s" % str(item.tags))
	print("  ✓ Weight: %.1f kg" % item.weight)
	print("  ✓ Base value: %d credits" % item.base_value)
	print("  ✓ Black market value: %d credits" % item.black_market_value)
	print("  ✓ Faction affinity: %s" % item.get_faction_affinity_name())
	print("  ✓ Spawn weight: %.2f" % item.spawn_weight)
	print("  ✓ Stack size: %d" % item.stack_size)
	print()


func test_tag_system() -> void:
	print("TEST 4: Tag System")
	print("-" * 40)
	
	var ComprehensiveDB = preload("res://resources/items/item_database.gd")
	
	# Test has_tag
	var weapon = ComprehensiveDB.create_item_from_comprehensive_data("weapon_core")
	print("✓ weapon_core has 'illegal' tag: %s" % weapon.has_tag("illegal"))
	print("✓ weapon_core has 'weapon' tag: %s" % weapon.has_tag("weapon"))
	print("✓ weapon_core is illegal: %s" % weapon.is_illegal())
	
	# Test get_items_by_tag
	var illegal_items = ComprehensiveDB.get_items_by_tag("illegal")
	print("✓ Total illegal items: %d" % illegal_items.size())
	print("  Illegal items: %s" % str(illegal_items))
	
	var tech_items = ComprehensiveDB.get_items_by_tag("tech")
	print("✓ Total tech items: %d" % tech_items.size())
	print()


func test_faction_system() -> void:
	print("TEST 5: Faction System")
	print("-" * 40)
	
	var ComprehensiveDB = preload("res://resources/items/item_database.gd")
	
	# Test faction affinity
	var weapon = ComprehensiveDB.create_item_from_comprehensive_data("weapon_core")
	print("✓ weapon_core faction affinity: %s" % weapon.get_faction_affinity_name())
	print("✓ weapon_core restricted for CCG (0): %s" % weapon.is_restricted_for_faction(0))
	print("✓ weapon_core restricted for GDF (2): %s" % weapon.is_restricted_for_faction(2))
	
	# Test get_items_by_faction
	var gdf_items = ComprehensiveDB.get_items_by_faction(2)  # GDF
	print("✓ Items for GDF faction: %d" % gdf_items.size())
	
	var syn_items = ComprehensiveDB.get_items_by_faction(3)  # SYN
	print("✓ Items for SYN faction: %d" % syn_items.size())
	print()


func test_value_system() -> void:
	print("TEST 6: Value System")
	print("-" * 40)
	
	var ComprehensiveDB = preload("res://resources/items/item_database.gd")
	
	var test_items = [
		"scrap_metal",
		"data_chip",
		"weapon_core",
		"alien_artifact",
		"singularity_gem"
	]
	
	for item_id in test_items:
		var item = ComprehensiveDB.create_item_from_comprehensive_data(item_id)
		var station = item.get_station_value()
		var black_market = item.get_black_market_value()
		var ratio = float(black_market) / float(station) if station > 0 else 1.0
		
		print("  %s:" % item.name)
		print("    Station: %d cr | Black Market: %d cr | Ratio: %.2fx" % [station, black_market, ratio])
	
	print()


func test_helper_functions() -> void:
	print("TEST 7: Helper Functions")
	print("-" * 40)
	
	var ComprehensiveDB = preload("res://resources/items/item_database.gd")
	
	# Test get_items_by_rarity
	for rarity in range(5):
		var items = ComprehensiveDB.get_items_by_rarity(rarity)
		var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
		print("✓ %s items: %d" % [rarity_names[rarity], items.size()])
	
	# Test weight density
	var heavy_item = ComprehensiveDB.create_item_from_comprehensive_data("void_shard")
	var light_item = ComprehensiveDB.create_item_from_comprehensive_data("data_chip")
	
	print("\nWeight density comparison:")
	print("  void_shard: %.2f kg/cell" % heavy_item.get_weight_density())
	print("  data_chip: %.2f kg/cell" % light_item.get_weight_density())
	print()


func test_resource_files() -> void:
	print("TEST 8: Resource Files")
	print("-" * 40)
	
	var resource_paths = [
		"res://resources/items/scrap/scrap_metal.tres",
		"res://resources/items/components/data_chip.tres",
		"res://resources/items/valuables/weapon_core.tres",
		"res://resources/items/epic/alien_artifact.tres",
		"res://resources/items/legendary/singularity_gem.tres"
	]
	
	for path in resource_paths:
		if ResourceLoader.exists(path):
			var item = load(path)
			if item:
				print("✓ Loaded: %s" % item.name)
			else:
				print("✗ Failed to load: %s" % path)
		else:
			print("✗ Resource not found: %s" % path)
	
	print()
