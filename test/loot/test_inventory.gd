# ==============================================================================
# UNIT TESTS FOR GRID INVENTORY
# ==============================================================================
#
# FILE: test/loot/test_inventory.gd
# PURPOSE: Tests for GridInventory class
#
# TEST COVERAGE:
# - Grid initialization
# - Item placement (can_place_at, place_item)
# - Item removal
# - Capacity limits
# - Grid positioning
# - Auto-placement logic
# - Value tracking
#
# ==============================================================================

extends GdUnitTestSuite

# Preload dependencies
const ItemData = preload("res://scripts/loot/item_data.gd")
const LootItem = preload("res://scenes/loot/loot_item.tscn")


# ==============================================================================
# TEST HELPERS
# ==============================================================================

var inventory: GridInventory
var test_items: Array = []


func before():
	"""Setup before each test"""
	# Create a basic inventory for testing
	inventory = GridInventory.new()
	inventory.grid_width = 4
	inventory.grid_height = 3
	inventory.cell_size = 64
	inventory.cell_gap = 2
	
	# Initialize the inventory grid
	inventory._init_grid()
	
	test_items.clear()


func after():
	"""Cleanup after each test"""
	# Clean up test items
	for item in test_items:
		if is_instance_valid(item):
			item.queue_free()
	test_items.clear()
	
	if is_instance_valid(inventory):
		inventory.queue_free()


func create_test_item(width: int, height: int, val: int = 100) -> LootItem:
	"""Helper to create a test loot item"""
	var item_data = ItemData.create_item("Test Item", width, height, val)
	var loot_item = LootItem.instantiate()
	loot_item.initialize(item_data)
	test_items.append(loot_item)
	return loot_item


# ==============================================================================
# GRID INITIALIZATION TESTS
# ==============================================================================

func test_grid_initialized_correctly():
	"""Test that grid is initialized with correct dimensions"""
	assert_int(inventory.grid_width).is_equal(4)
	assert_int(inventory.grid_height).is_equal(3)
	assert_int(inventory.grid.size()).is_equal(4)
	
	# Check each column has correct height
	for x in range(4):
		assert_int(inventory.grid[x].size()).is_equal(3)


func test_grid_starts_empty():
	"""Test that all grid cells start as unoccupied"""
	for x in range(inventory.grid_width):
		for y in range(inventory.grid_height):
			assert_bool(inventory.grid[x][y]).is_false()


func test_total_value_starts_at_zero():
	"""Test that total value starts at 0"""
	assert_int(inventory.total_value).is_equal(0)


# ==============================================================================
# PLACEMENT VALIDATION TESTS
# ==============================================================================

func test_can_place_1x1_item():
	"""Test that 1x1 item can be placed at origin"""
	var item = create_test_item(1, 1)
	
	assert_bool(inventory.can_place_at(item, Vector2i(0, 0))).is_true()


func test_can_place_2x2_item():
	"""Test that 2x2 item can be placed"""
	var item = create_test_item(2, 2)
	
	# Should fit at origin
	assert_bool(inventory.can_place_at(item, Vector2i(0, 0))).is_true()
	
	# Should fit at (2, 1)
	assert_bool(inventory.can_place_at(item, Vector2i(2, 1))).is_true()


func test_cannot_place_out_of_bounds():
	"""Test that items cannot be placed out of bounds"""
	var item = create_test_item(2, 2)
	
	# Would exceed grid width (4x3 grid)
	assert_bool(inventory.can_place_at(item, Vector2i(3, 0))).is_false()
	
	# Would exceed grid height
	assert_bool(inventory.can_place_at(item, Vector2i(0, 2))).is_false()
	
	# Negative position
	assert_bool(inventory.can_place_at(item, Vector2i(-1, 0))).is_false()
	assert_bool(inventory.can_place_at(item, Vector2i(0, -1))).is_false()


func test_cannot_place_overlapping_items():
	"""Test that items cannot overlap"""
	var item1 = create_test_item(2, 2)
	var item2 = create_test_item(2, 2)
	
	# Place first item
	inventory.place_item(item1, Vector2i(0, 0))
	
	# Try to place second item overlapping
	assert_bool(inventory.can_place_at(item2, Vector2i(1, 1))).is_false()
	assert_bool(inventory.can_place_at(item2, Vector2i(0, 0))).is_false()


# ==============================================================================
# PLACEMENT TESTS
# ==============================================================================

func test_place_item_at_origin():
	"""Test placing an item at grid origin"""
	var item = create_test_item(1, 1, 100)
	
	var result = inventory.place_item(item, Vector2i(0, 0))
	
	assert_bool(result).is_true()
	assert_bool(inventory.grid[0][0]).is_true()
	assert_int(inventory.total_value).is_equal(100)


func test_place_2x2_item():
	"""Test placing a 2x2 item marks all cells as occupied"""
	var item = create_test_item(2, 2, 500)
	
	inventory.place_item(item, Vector2i(1, 1))
	
	# Check all 4 cells are marked occupied
	assert_bool(inventory.grid[1][1]).is_true()
	assert_bool(inventory.grid[2][1]).is_true()
	assert_bool(inventory.grid[1][2]).is_true()
	assert_bool(inventory.grid[2][2]).is_true()
	
	# Check surrounding cells are still empty
	assert_bool(inventory.grid[0][0]).is_false()
	assert_bool(inventory.grid[3][0]).is_false()


func test_place_multiple_items():
	"""Test placing multiple non-overlapping items"""
	var item1 = create_test_item(1, 1, 100)
	var item2 = create_test_item(1, 1, 200)
	var item3 = create_test_item(2, 1, 300)
	
	assert_bool(inventory.place_item(item1, Vector2i(0, 0))).is_true()
	assert_bool(inventory.place_item(item2, Vector2i(1, 0))).is_true()
	assert_bool(inventory.place_item(item3, Vector2i(0, 1))).is_true()
	
	assert_int(inventory.total_value).is_equal(600)
	assert_int(inventory.get_item_count()).is_equal(3)


func test_place_item_updates_value():
	"""Test that placing item updates total value"""
	var item = create_test_item(1, 1, 250)
	
	inventory.place_item(item, Vector2i(0, 0))
	
	assert_int(inventory.total_value).is_equal(250)
	assert_int(inventory.get_total_value()).is_equal(250)


# ==============================================================================
# REMOVAL TESTS
# ==============================================================================

func test_remove_item():
	"""Test removing an item from inventory"""
	var item = create_test_item(2, 2, 500)
	
	# Place and then remove
	inventory.place_item(item, Vector2i(0, 0))
	assert_int(inventory.total_value).is_equal(500)
	
	var removed = inventory.remove_item(item)
	
	assert_bool(removed).is_true()
	assert_int(inventory.total_value).is_equal(0)
	
	# Check cells are freed
	assert_bool(inventory.grid[0][0]).is_false()
	assert_bool(inventory.grid[1][0]).is_false()
	assert_bool(inventory.grid[0][1]).is_false()
	assert_bool(inventory.grid[1][1]).is_false()


func test_remove_nonexistent_item():
	"""Test removing an item that's not in inventory"""
	var item = create_test_item(1, 1)
	
	var removed = inventory.remove_item(item)
	
	assert_bool(removed).is_false()


func test_remove_item_frees_space():
	"""Test that removing item allows placing new item in same space"""
	var item1 = create_test_item(2, 2, 100)
	var item2 = create_test_item(2, 2, 200)
	
	# Place first item
	inventory.place_item(item1, Vector2i(0, 0))
	
	# Remove it
	inventory.remove_item(item1)
	
	# Should now be able to place second item in same spot
	assert_bool(inventory.can_place_at(item2, Vector2i(0, 0))).is_true()
	assert_bool(inventory.place_item(item2, Vector2i(0, 0))).is_true()


# ==============================================================================
# AUTO-PLACEMENT TESTS
# ==============================================================================

func test_find_free_position():
	"""Test finding first free position for an item"""
	var item = create_test_item(1, 1)
	
	var pos = inventory.find_free_position(item)
	
	# Should find origin (0, 0)
	assert_object(pos).is_equal(Vector2i(0, 0))


func test_find_free_position_with_occupied_cells():
	"""Test finding free position when some cells are occupied"""
	var blocker = create_test_item(2, 1)
	inventory.place_item(blocker, Vector2i(0, 0))
	
	var item = create_test_item(1, 1)
	var pos = inventory.find_free_position(item)
	
	# Should find (2, 0) since (0,0) and (1,0) are occupied
	assert_object(pos).is_equal(Vector2i(2, 0))


func test_find_free_position_returns_invalid_when_full():
	"""Test that find_free_position returns (-1,-1) when inventory is full"""
	# Fill the entire grid with 1x1 items
	for y in range(inventory.grid_height):
		for x in range(inventory.grid_width):
			var item = create_test_item(1, 1)
			inventory.place_item(item, Vector2i(x, y))
	
	# Try to find space for another item
	var new_item = create_test_item(1, 1)
	var pos = inventory.find_free_position(new_item)
	
	assert_object(pos).is_equal(Vector2i(-1, -1))


func test_auto_place():
	"""Test automatic placement of item"""
	var item = create_test_item(1, 1, 100)
	
	var placed = inventory.auto_place(item)
	
	assert_bool(placed).is_true()
	assert_int(inventory.total_value).is_equal(100)


func test_auto_place_when_full():
	"""Test auto_place fails when inventory is full"""
	# Fill the grid
	for y in range(inventory.grid_height):
		for x in range(inventory.grid_width):
			var item = create_test_item(1, 1)
			inventory.place_item(item, Vector2i(x, y))
	
	# Try to auto-place another item
	var new_item = create_test_item(1, 1)
	var placed = inventory.auto_place(new_item)
	
	assert_bool(placed).is_false()


# ==============================================================================
# CAPACITY TESTS
# ==============================================================================

func test_inventory_capacity_limit():
	"""Test that inventory respects capacity limits"""
	# 4x3 grid = 12 cells total
	# Fill with 1x1 items
	var items_placed = 0
	
	for i in range(20):  # Try to place more than capacity
		var item = create_test_item(1, 1)
		if inventory.auto_place(item):
			items_placed += 1
	
	# Should only fit 12 items
	assert_int(items_placed).is_equal(12)
	assert_int(inventory.get_item_count()).is_equal(12)


func test_large_item_capacity():
	"""Test capacity with larger items"""
	# 4x3 grid = 12 cells
	# 2x2 items take 4 cells each
	var items_placed = 0
	
	for i in range(10):
		var item = create_test_item(2, 2)
		if inventory.auto_place(item):
			items_placed += 1
	
	# Should fit 3 items (3 * 4 = 12 cells)
	assert_int(items_placed).is_equal(3)


# ==============================================================================
# UTILITY TESTS
# ==============================================================================

func test_get_item_count():
	"""Test counting items in inventory"""
	assert_int(inventory.get_item_count()).is_equal(0)
	
	var item1 = create_test_item(1, 1)
	var item2 = create_test_item(2, 1)
	inventory.place_item(item1, Vector2i(0, 0))
	inventory.place_item(item2, Vector2i(1, 0))
	
	assert_int(inventory.get_item_count()).is_equal(2)


func test_get_item_at_position():
	"""Test retrieving item at specific grid position"""
	var item = create_test_item(2, 2)
	inventory.place_item(item, Vector2i(1, 1))
	
	# All cells occupied by the item should return the same item
	assert_object(inventory.get_item_at_position(Vector2i(1, 1))).is_equal(item)
	assert_object(inventory.get_item_at_position(Vector2i(2, 1))).is_equal(item)
	assert_object(inventory.get_item_at_position(Vector2i(1, 2))).is_equal(item)
	assert_object(inventory.get_item_at_position(Vector2i(2, 2))).is_equal(item)
	
	# Empty cell should return null
	assert_object(inventory.get_item_at_position(Vector2i(0, 0))).is_null()


func test_get_all_items():
	"""Test retrieving all items from inventory"""
	var item1 = create_test_item(1, 1)
	var item2 = create_test_item(1, 1)
	var item3 = create_test_item(1, 1)
	
	inventory.place_item(item1, Vector2i(0, 0))
	inventory.place_item(item2, Vector2i(1, 0))
	inventory.place_item(item3, Vector2i(2, 0))
	
	var all_items = inventory.get_all_items()
	
	assert_int(all_items.size()).is_equal(3)
	assert_bool(item1 in all_items).is_true()
	assert_bool(item2 in all_items).is_true()
	assert_bool(item3 in all_items).is_true()


func test_clear_all():
	"""Test clearing all items from inventory"""
	# Place some items
	for i in range(3):
		var item = create_test_item(1, 1)
		inventory.auto_place(item)
	
	assert_int(inventory.get_item_count()).is_equal(3)
	
	# Clear all
	inventory.clear_all()
	
	assert_int(inventory.get_item_count()).is_equal(0)
	assert_int(inventory.total_value).is_equal(0)
