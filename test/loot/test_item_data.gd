# ==============================================================================
# UNIT TESTS FOR ITEM DATA
# ==============================================================================
#
# FILE: test/loot/test_item_data.gd
# PURPOSE: Tests for ItemData resource class
#
# TEST COVERAGE:
# - Item creation and initialization
# - Item properties (grid size, value, rarity)
# - Computed properties (cell_count, search_time, value_density)
# - Rarity names and colors
# - Static helper functions
#
# ==============================================================================

extends GdUnitTestSuite


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
# ITEM CREATION TESTS
# ==============================================================================

func test_create_item_with_defaults():
	"""Test creating an ItemData with default values"""
	var default_item = ItemData.new()
	
	assert_str(default_item.id).is_equal("item_unknown")
	assert_str(default_item.name).is_equal("Unknown Item")
	assert_int(default_item.grid_width).is_equal(1)
	assert_int(default_item.grid_height).is_equal(2)
	assert_int(default_item.value).is_equal(100)
	assert_int(default_item.rarity).is_equal(0)
	assert_int(default_item.category).is_equal(0)


func test_create_item_with_static_helper():
	"""Test creating an item using the static create_item helper"""
	var item = ItemData.create_item("Test Widget", 2, 3, 500)
	
	assert_str(item.id).is_equal("test_widget")
	assert_str(item.name).is_equal("Test Widget")
	assert_int(item.grid_width).is_equal(2)
	assert_int(item.grid_height).is_equal(3)
	assert_int(item.value).is_equal(500)


# ==============================================================================
# PROPERTY TESTS
# ==============================================================================

func test_grid_size_properties():
	"""Test grid width and height properties"""
	var item = ItemData.new()
	item.grid_width = 3
	item.grid_height = 4
	
	assert_int(item.grid_width).is_equal(3)
	assert_int(item.grid_height).is_equal(4)


func test_value_property():
	"""Test item value property"""
	var item = ItemData.new()
	item.value = 1500
	
	assert_int(item.value).is_equal(1500)


func test_rarity_property():
	"""Test rarity property (0-4)"""
	var item = ItemData.new()
	
	# Test each rarity level
	for rarity in range(5):
		item.rarity = rarity
		assert_int(item.rarity).is_equal(rarity)


func test_category_property():
	"""Test category property"""
	var item = ItemData.new()
	item.category = 3  # Module category
	
	assert_int(item.category).is_equal(3)


# ==============================================================================
# COMPUTED PROPERTY TESTS
# ==============================================================================

func test_get_cell_count():
	"""Test computed cell count (grid_width * grid_height)"""
	var item = ItemData.new()
	
	# 1x2 item (default)
	assert_int(item.get_cell_count()).is_equal(2)
	
	# 3x4 item
	item.grid_width = 3
	item.grid_height = 4
	assert_int(item.get_cell_count()).is_equal(12)
	
	# 1x1 item
	item.grid_width = 1
	item.grid_height = 1
	assert_int(item.get_cell_count()).is_equal(1)


func test_get_search_time_default():
	"""Test search time with auto-calculated size modifier"""
	var item = ItemData.new()
	item.base_search_time = 2.0
	item.grid_width = 2
	item.grid_height = 2
	
	# 2x2 = 4 cells, size_factor = 1.0 + (4-1)*0.3 = 1.9
	# search_time = 2.0 * 1.9 = 3.8
	var expected = 2.0 * (1.0 + (4 - 1) * 0.3)
	assert_float(item.get_search_time()).is_equal(expected)


func test_get_search_time_with_custom_multiplier():
	"""Test search time with custom multiplier"""
	var item = ItemData.new()
	item.base_search_time = 2.0
	item.search_time_multiplier = 1.5
	
	# With custom multiplier, should use that instead of auto-calc
	assert_float(item.get_search_time()).is_equal(3.0)


func test_get_value_density():
	"""Test value density calculation (value per cell)"""
	var item = ItemData.new()
	
	# 100 value, 2 cells (1x2 default)
	assert_float(item.get_value_density()).is_equal(50.0)
	
	# 1000 value, 4 cells (2x2)
	item.value = 1000
	item.grid_width = 2
	item.grid_height = 2
	assert_float(item.get_value_density()).is_equal(250.0)
	
	# 500 value, 1 cell (1x1)
	item.value = 500
	item.grid_width = 1
	item.grid_height = 1
	assert_float(item.get_value_density()).is_equal(500.0)


# ==============================================================================
# RARITY TESTS
# ==============================================================================

func test_get_rarity_name():
	"""Test rarity name strings"""
	var item = ItemData.new()
	
	item.rarity = 0
	assert_str(item.get_rarity_name()).is_equal("Common")
	
	item.rarity = 1
	assert_str(item.get_rarity_name()).is_equal("Uncommon")
	
	item.rarity = 2
	assert_str(item.get_rarity_name()).is_equal("Rare")
	
	item.rarity = 3
	assert_str(item.get_rarity_name()).is_equal("Epic")
	
	item.rarity = 4
	assert_str(item.get_rarity_name()).is_equal("Legendary")


func test_get_rarity_name_unknown():
	"""Test rarity name for invalid rarity"""
	var item = ItemData.new()
	item.rarity = 99
	
	assert_str(item.get_rarity_name()).is_equal("Unknown")


func test_get_rarity_color_defaults():
	"""Test default rarity colors"""
	var item = ItemData.new()
	item.rarity_color = Color.WHITE  # Use default
	
	# Common - Gray
	item.rarity = 0
	var color = item.get_rarity_color()
	assert_object(color).is_not_null()
	
	# Uncommon - Green
	item.rarity = 1
	color = item.get_rarity_color()
	assert_object(color).is_not_null()
	
	# Rare - Blue
	item.rarity = 2
	color = item.get_rarity_color()
	assert_object(color).is_not_null()
	
	# Epic - Purple
	item.rarity = 3
	color = item.get_rarity_color()
	assert_object(color).is_not_null()
	
	# Legendary - Gold
	item.rarity = 4
	color = item.get_rarity_color()
	assert_object(color).is_not_null()


func test_get_rarity_color_custom():
	"""Test custom rarity color override"""
	var item = ItemData.new()
	var custom_color = Color(1.0, 0.0, 1.0)  # Magenta
	item.rarity_color = custom_color
	
	# Should return custom color regardless of rarity
	assert_object(item.get_rarity_color()).is_equal(custom_color)


# ==============================================================================
# INTEGRATION TESTS
# ==============================================================================

func test_item_with_all_properties():
	"""Test creating a fully configured item"""
	var item = ItemData.new()
	item.id = "quantum_core"
	item.name = "Quantum Core"
	item.description = "A powerful quantum processor"
	item.grid_width = 2
	item.grid_height = 2
	item.value = 2000
	item.rarity = 4  # Legendary
	item.category = 4  # Artifact
	item.base_search_time = 5.0
	
	# Verify all properties
	assert_str(item.id).is_equal("quantum_core")
	assert_str(item.name).is_equal("Quantum Core")
	assert_int(item.grid_width).is_equal(2)
	assert_int(item.grid_height).is_equal(2)
	assert_int(item.value).is_equal(2000)
	assert_int(item.rarity).is_equal(4)
	assert_int(item.category).is_equal(4)
	assert_float(item.base_search_time).is_equal(5.0)
	
	# Verify computed properties
	assert_int(item.get_cell_count()).is_equal(4)
	assert_float(item.get_value_density()).is_equal(500.0)
	assert_str(item.get_rarity_name()).is_equal("Legendary")
