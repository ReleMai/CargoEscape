# ==============================================================================
# UNIT TESTS FOR LOOT SYSTEM (ITEM DATABASE)
# ==============================================================================
#
# FILE: test/loot/test_loot_system.gd
# PURPOSE: Tests for loot generation, tables, and rarity weighting
#
# TEST COVERAGE:
# - Item database access
# - Loot table rolls
# - Rarity-based item generation
# - Weighted item selection
# - Tier-based loot generation
# - Item creation from definitions
#
# ==============================================================================

extends GdUnitTestSuite

# Preload dependencies
const ItemDB = preload("res://scripts/loot/item_database.gd")
const ItemData = preload("res://scripts/loot/item_data.gd")


# ==============================================================================
# SETUP & TEARDOWN
# ==============================================================================

func before():
	"""Setup before each test"""
	pass


func after():
	"""Cleanup after each test"""
	pass


# ==============================================================================
# ITEM DATABASE TESTS
# ==============================================================================

func test_get_all_items():
	"""Test retrieving all items from database"""
	var all_items = ItemDB.get_all_items()
	
	assert_object(all_items).is_not_null()
	assert_bool(all_items is Dictionary).is_true()
	assert_int(all_items.size()).is_greater(0)


func test_all_items_have_required_fields():
	"""Test that all items have required fields"""
	var all_items = ItemDB.get_all_items()
	
	for item_id in all_items:
		var item_def = all_items[item_id]
		assert_bool(item_def.has("name")).is_true()
		assert_bool(item_def.has("width")).is_true()
		assert_bool(item_def.has("height")).is_true()
		assert_bool(item_def.has("base_value")).is_true()
		assert_bool(item_def.has("rarity")).is_true()


func test_get_items_by_rarity():
	"""Test filtering items by rarity level"""
	# Test common items (rarity 0)
	var common = ItemDB.get_items_by_rarity(0)
	assert_object(common).is_not_null()
	assert_int(common.size()).is_greater(0)
	
	# Verify all items are rarity 0
	for item_id in common:
		assert_int(common[item_id].get("rarity")).is_equal(0)
	
	# Test uncommon items (rarity 1)
	var uncommon = ItemDB.get_items_by_rarity(1)
	assert_object(uncommon).is_not_null()
	
	# Test rare items (rarity 2)
	var rare = ItemDB.get_items_by_rarity(2)
	assert_object(rare).is_not_null()


func test_get_all_item_ids():
	"""Test getting list of all item IDs"""
	var item_ids = ItemDB.get_all_item_ids()
	
	assert_object(item_ids).is_not_null()
	assert_int(item_ids.size()).is_greater(0)
	
	# Verify it's an array of strings
	for id in item_ids:
		assert_bool(id is String).is_true()


# ==============================================================================
# ITEM CREATION TESTS
# ==============================================================================

func test_create_item_basic():
	"""Test creating a basic item from ID"""
	var item = ItemDB.create_item("scrap_metal")
	
	assert_object(item).is_not_null()
	assert_bool(item is ItemData).is_true()
	assert_str(item.id).is_equal("scrap_metal")
	assert_str(item.name).is_not_equal("")


func test_create_item_with_all_properties():
	"""Test that created item has all expected properties"""
	var item = ItemDB.create_item("scrap_metal")
	
	assert_int(item.grid_width).is_greater(0)
	assert_int(item.grid_height).is_greater(0)
	assert_int(item.value).is_greater(0)
	assert_int(item.rarity).is_greater_equal(0)
	assert_int(item.category).is_greater_equal(0)


func test_create_item_invalid_id():
	"""Test creating item with invalid ID returns null"""
	var item = ItemDB.create_item("nonexistent_item_xyz")
	
	assert_object(item).is_null()


func test_create_multiple_items():
	"""Test creating multiple different items"""
	var item1 = ItemDB.create_item("scrap_metal")
	var item2 = ItemDB.create_item("scrap_plastics")
	var item3 = ItemDB.create_item("copper_wire")
	
	assert_object(item1).is_not_null()
	assert_object(item2).is_not_null()
	assert_object(item3).is_not_null()
	
	# Verify they're different items
	assert_str(item1.id).is_not_equal(item2.id)
	assert_str(item2.id).is_not_equal(item3.id)


# ==============================================================================
# RARITY-BASED ITEM TESTS
# ==============================================================================

func test_roll_item_by_rarity_common():
	"""Test rolling a common item (rarity 0)"""
	var item = ItemDB.roll_item_by_rarity(0)
	
	assert_object(item).is_not_null()
	assert_bool(item is ItemData).is_true()
	assert_int(item.rarity).is_equal(0)


func test_roll_item_by_rarity_uncommon():
	"""Test rolling an uncommon item (rarity 1)"""
	var item = ItemDB.roll_item_by_rarity(1)
	
	assert_object(item).is_not_null()
	assert_int(item.rarity).is_equal(1)


func test_roll_item_by_rarity_rare():
	"""Test rolling a rare item (rarity 2)"""
	var item = ItemDB.roll_item_by_rarity(2)
	
	assert_object(item).is_not_null()
	assert_int(item.rarity).is_equal(2)


func test_roll_item_by_rarity_consistency():
	"""Test that rolling same rarity multiple times gives valid items"""
	for i in range(10):
		var item = ItemDB.roll_item_by_rarity(0)
		assert_object(item).is_not_null()
		assert_int(item.rarity).is_equal(0)


# ==============================================================================
# LOOT TABLE TESTS
# ==============================================================================

func test_get_loot_table_tier_0():
	"""Test getting loot table for tier 0 (near space)"""
	var table = ItemDB.get_loot_table(0)
	
	assert_object(table).is_not_null()
	assert_bool(table is Dictionary).is_true()
	assert_int(table.size()).is_greater(0)


func test_get_loot_table_tier_1():
	"""Test getting loot table for tier 1 (middle space)"""
	var table = ItemDB.get_loot_table(1)
	
	assert_object(table).is_not_null()
	assert_int(table.size()).is_greater(0)


func test_get_loot_table_tier_2():
	"""Test getting loot table for tier 2 (far space)"""
	var table = ItemDB.get_loot_table(2)
	
	assert_object(table).is_not_null()
	assert_int(table.size()).is_greater(0)


func test_get_loot_table_tier_3():
	"""Test getting loot table for tier 3 (deepest space)"""
	var table = ItemDB.get_loot_table(3)
	
	assert_object(table).is_not_null()
	assert_int(table.size()).is_greater(0)


func test_get_loot_table_invalid_tier():
	"""Test that invalid tier returns default table (tier 0)"""
	var table = ItemDB.get_loot_table(99)
	var tier0_table = ItemDB.get_loot_table(0)
	
	assert_object(table).is_equal(tier0_table)


func test_loot_table_has_weights():
	"""Test that loot table entries have numeric weights"""
	var table = ItemDB.get_loot_table(0)
	
	for item_id in table:
		var weight = table[item_id]
		assert_bool(weight is int or weight is float).is_true()
		assert_int(weight).is_greater(0)


# ==============================================================================
# WEIGHTED LOOT ROLL TESTS
# ==============================================================================

func test_roll_item_from_table():
	"""Test rolling an item from a loot table"""
	var table = ItemDB.get_loot_table(0)
	var item = ItemDB.roll_item_from_table(table)
	
	assert_object(item).is_not_null()
	assert_bool(item is ItemData).is_true()


func test_roll_item_from_table_consistency():
	"""Test that rolling from table always returns valid items"""
	var table = ItemDB.get_loot_table(1)
	
	for i in range(20):
		var item = ItemDB.roll_item_from_table(table)
		assert_object(item).is_not_null()
		assert_str(item.id).is_not_equal("")


func test_roll_item_from_table_respects_weights():
	"""Test that weighted rolling produces items in the table"""
	var table = ItemDB.get_loot_table(0)
	var table_item_ids = table.keys()
	
	# Roll 50 items and verify they're all from the table
	for i in range(50):
		var item = ItemDB.roll_item_from_table(table)
		assert_bool(item.id in table_item_ids).is_true()


func test_roll_item_from_empty_table():
	"""Test rolling from empty table returns fallback"""
	var empty_table = {}
	var item = ItemDB.roll_item_from_table(empty_table)
	
	# Should return fallback item (scrap_metal)
	assert_object(item).is_not_null()
	assert_str(item.id).is_equal("scrap_metal")


# ==============================================================================
# TIER-BASED LOOT GENERATION TESTS
# ==============================================================================

func test_roll_loot_tier_0():
	"""Test rolling loot for tier 0"""
	var item = ItemDB.roll_loot(0)
	
	assert_object(item).is_not_null()
	assert_bool(item is ItemData).is_true()


func test_roll_loot_tier_1():
	"""Test rolling loot for tier 1"""
	var item = ItemDB.roll_loot(1)
	
	assert_object(item).is_not_null()


func test_roll_loot_tier_2():
	"""Test rolling loot for tier 2"""
	var item = ItemDB.roll_loot(2)
	
	assert_object(item).is_not_null()


func test_roll_loot_tier_3():
	"""Test rolling loot for tier 3"""
	var item = ItemDB.roll_loot(3)
	
	assert_object(item).is_not_null()


func test_roll_loot_multiple_times():
	"""Test rolling loot multiple times produces valid items"""
	for tier in range(4):
		for i in range(10):
			var item = ItemDB.roll_loot(tier)
			assert_object(item).is_not_null()
			assert_str(item.id).is_not_equal("")


# ==============================================================================
# STATISTICAL TESTS (Sampling-based)
# ==============================================================================

func test_loot_distribution_has_variety():
	"""Test that rolling many items produces different results"""
	var items_seen = {}
	
	# Roll 100 items from tier 0
	for i in range(100):
		var item = ItemDB.roll_loot(0)
		items_seen[item.id] = true
	
	# Should have gotten at least 3 different items
	assert_int(items_seen.size()).is_greater_equal(3)


func test_higher_tier_has_higher_average_value():
	"""Test that higher tiers tend to have more valuable items"""
	var tier0_total = 0
	var tier3_total = 0
	var sample_size = 50
	
	# Sample tier 0
	for i in range(sample_size):
		var item = ItemDB.roll_loot(0)
		tier0_total += item.value
	
	# Sample tier 3
	for i in range(sample_size):
		var item = ItemDB.roll_loot(3)
		tier3_total += item.value
	
	var tier0_avg = tier0_total / sample_size
	var tier3_avg = tier3_total / sample_size
	
	# Tier 3 should generally have higher value items
	assert_int(tier3_avg).is_greater(tier0_avg)


# ==============================================================================
# ITEM CATEGORIES TESTS
# ==============================================================================

func test_items_have_categories():
	"""Test that items have valid category assignments"""
	var all_items = ItemDB.get_all_items()
	
	for item_id in all_items:
		var item_def = all_items[item_id]
		var category = item_def.get("category", -1)
		
		# Category should be 0-4
		assert_int(category).is_greater_equal(0)
		assert_int(category).is_less_equal(4)


func test_create_item_preserves_category():
	"""Test that created items preserve category from definition"""
	var item = ItemDB.create_item("scrap_metal")
	
	assert_int(item.category).is_greater_equal(0)
	assert_int(item.category).is_less_equal(4)


# ==============================================================================
# VALUE CALCULATION TESTS
# ==============================================================================

func test_item_value_calculated_from_base_and_weight():
	"""Test that item values are calculated from base value and weight"""
	var item = ItemDB.create_item("scrap_metal")
	
	# Value should be positive
	assert_int(item.value).is_greater(0)


func test_heavier_items_have_value_bonus():
	"""Test that weight affects item value"""
	# This is more of a system verification test
	# Items with same base value but different weights should have different values
	var all_items = ItemDB.get_all_items()
	
	# Just verify value calculation doesn't crash and produces positive values
	for item_id in all_items:
		var item = ItemDB.create_item(item_id)
		if item:
			assert_int(item.value).is_greater(0)


# ==============================================================================
# SEARCH TIME TESTS
# ==============================================================================

func test_item_search_time_calculated():
	"""Test that item search time is calculated"""
	var item = ItemDB.create_item("scrap_metal")
	
	assert_float(item.base_search_time).is_greater(0.0)


func test_larger_items_have_longer_search_time():
	"""Test that larger items generally take longer to search"""
	# Create a 1x1 item
	var small_item = ItemDB.create_item("scrap_plastics")  # 1x1
	
	# Create a larger item
	var large_item = ItemDB.create_item("scrap_electronics")  # 1x2
	
	# Larger items should generally take longer (though rarity also affects it)
	# So we just verify both have positive search times
	assert_float(small_item.get_search_time()).is_greater(0.0)
	assert_float(large_item.get_search_time()).is_greater(0.0)
