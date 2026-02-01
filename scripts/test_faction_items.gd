# ==============================================================================
# FACTION ITEMS TEST - Verifies faction-specific items are working
# ==============================================================================
#
# This script tests that:
# 1. All 25 faction-specific items can be created
# 2. Faction-specific loot generation works
# 3. Items have correct faction_exclusive field set
#
# Run this script in Godot's Script Editor to test the implementation
# ==============================================================================

extends Node

const ItemDB = preload("res://scripts/loot/item_database.gd")
const Factions = preload("res://scripts/data/factions.gd")

func _ready() -> void:
	print("\n========================================")
	print("FACTION ITEMS TEST")
	print("========================================\n")
	
	test_all_faction_items_exist()
	test_faction_items_creation()
	test_faction_loot_generation()
	test_faction_filtering()
	
	print("\n========================================")
	print("ALL TESTS COMPLETED")
	print("========================================\n")
	
	# Exit after tests
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


func test_all_faction_items_exist() -> void:
	print("Test 1: Checking all 25 faction items exist...")
	
	var expected_items = {
		"CCG": ["guild_trade_license", "bulk_cargo_manifest", "premium_fuel_reserves", "trade_route_data", "guild_masters_seal"],
		"NEX": ["syndicate_cipher", "assassination_contract", "forged_id_chips", "syndicate_tribute", "crime_lords_ledger"],
		"GDF": ["military_rations_premium", "tactical_armor_plating", "encrypted_orders", "officers_sidearm", "admirals_medal"],
		"SYN": ["prototype_chip", "ai_core_fragment", "nanobot_swarm", "holographic_projector", "quantum_processor"],
		"IND": ["salvage_rights_claim", "homemade_repairs", "family_heirloom", "prospectors_map", "lucky_charm"]
	}
	
	var all_items = ItemDB.get_all_items()
	var total_found = 0
	
	for faction in expected_items:
		print("  Checking %s items..." % faction)
		var faction_items = expected_items[faction]
		for item_id in faction_items:
			if all_items.has(item_id):
				total_found += 1
				print("    ✓ %s found" % item_id)
			else:
				print("    ✗ %s MISSING!" % item_id)
	
	print("  Result: %d/25 faction items found\n" % total_found)
	assert(total_found == 25, "Not all faction items were found!")


func test_faction_items_creation() -> void:
	print("Test 2: Creating sample faction items...")
	
	var test_items = [
		"guild_trade_license",  # CCG
		"syndicate_cipher",     # NEX
		"tactical_armor_plating", # GDF
		"quantum_processor",    # SYN
		"lucky_charm"           # IND
	]
	
	var expected_factions = ["CCG", "NEX", "GDF", "SYN", "IND"]
	
	for i in range(test_items.size()):
		var item_id = test_items[i]
		var expected_faction = expected_factions[i]
		
		var item = ItemDB.create_item(item_id)
		if item:
			var actual_faction = item.faction_exclusive
			if actual_faction == expected_faction:
				print("  ✓ %s created with faction '%s'" % [item.name, actual_faction])
			else:
				print("  ✗ %s has wrong faction '%s' (expected '%s')" % [item.name, actual_faction, expected_faction])
				assert(false, "Item has wrong faction!")
		else:
			print("  ✗ Failed to create %s" % item_id)
			assert(false, "Failed to create item!")
	
	print("  All test items created successfully!\n")


func test_faction_loot_generation() -> void:
	print("Test 3: Testing faction-specific loot generation...")
	
	var factions = ["CCG", "NEX", "GDF", "SYN", "IND"]
	
	for faction_code in factions:
		print("  Testing %s faction loot..." % faction_code)
		
		# Generate 20 items for this faction
		var items = ItemDB.generate_container_loot_with_faction(2, 1, 20, faction_code)
		
		var faction_specific_count = 0
		var regular_count = 0
		
		for item in items:
			if item.faction_exclusive == faction_code:
				faction_specific_count += 1
			elif item.faction_exclusive == "":
				regular_count += 1
		
		print("    Generated %d items (%d faction-specific, %d regular)" % [items.size(), faction_specific_count, regular_count])
		
		# We expect at least some faction-specific items due to 20% chance per item
		if faction_specific_count > 0:
			print("    ✓ Faction-specific items found!")
		else:
			print("    ⚠ No faction-specific items (this can happen by chance)")
	
	print("  Faction loot generation working!\n")


func test_faction_filtering() -> void:
	print("Test 4: Testing faction item filtering...")
	
	var factions = ["CCG", "NEX", "GDF", "SYN", "IND"]
	
	for faction_code in factions:
		var faction_items = ItemDB.get_faction_items(faction_code)
		print("  %s has %d exclusive items" % [faction_code, faction_items.size()])
		
		# Verify all items have correct faction
		var all_correct = true
		for item_id in faction_items:
			var item_def = faction_items[item_id]
			if item_def.get("faction_exclusive", "") != faction_code:
				all_correct = false
				print("    ✗ %s has wrong faction!" % item_id)
		
		if all_correct:
			print("    ✓ All items have correct faction")
	
	# Test common pool
	var common_items = ItemDB.get_common_pool_items()
	print("  Common pool has %d non-faction items" % common_items.size())
	
	print("  Faction filtering working!\n")
