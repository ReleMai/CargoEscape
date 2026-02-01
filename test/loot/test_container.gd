# ==============================================================================
# UNIT TESTS FOR CARGO CONTAINER
# ==============================================================================
#
# FILE: test/loot/test_container.gd
# PURPOSE: Tests for CargoContainer class
#
# TEST COVERAGE:
# - Container states (CLOSED, OPEN, EMPTY)
# - Container opening/closing
# - Item population
# - Item addition and removal
# - Container utility functions
#
# ==============================================================================

extends GdUnitTestSuite

# Preload dependencies
const ItemData = preload("res://scripts/loot/item_data.gd")
const CargoContainer = preload("res://scripts/loot/container.gd")


# ==============================================================================
# TEST HELPERS
# ==============================================================================

var container: CargoContainer
var test_items_data: Array[ItemData] = []


func before():
	"""Setup before each test"""
	# Create a basic container for testing
	container = CargoContainer.new()
	container.container_name = "Test Container"
	container.slot_count = 6
	container.cell_size = 64
	
	test_items_data.clear()


func after():
	"""Cleanup after each test"""
	test_items_data.clear()
	
	if is_instance_valid(container):
		container.queue_free()


func create_test_item_data(width: int, height: int, val: int = 100) -> ItemData:
	"""Helper to create test item data"""
	var item = ItemData.create_item("Test Item", width, height, val)
	test_items_data.append(item)
	return item


# ==============================================================================
# STATE TESTS
# ==============================================================================

func test_container_starts_closed():
	"""Test that container starts in CLOSED state"""
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.CLOSED)


func test_open_container():
	"""Test opening a closed container"""
	container.open_container()
	
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.OPEN)


func test_cannot_open_already_open_container():
	"""Test that opening an already open container has no effect"""
	container.open_container()
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.OPEN)
	
	# Try to open again - should remain OPEN
	container.open_container()
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.OPEN)


func test_close_container():
	"""Test closing an open container"""
	container.open_container()
	container.close_container()
	
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.CLOSED)


func test_set_state_to_empty():
	"""Test setting container to EMPTY state"""
	container.set_state(CargoContainer.ContainerState.EMPTY)
	
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.EMPTY)


# ==============================================================================
# ITEM MANAGEMENT TESTS
# ==============================================================================

func test_container_starts_with_no_items():
	"""Test that container starts empty"""
	assert_int(container.get_item_count()).is_equal(0)
	assert_array(container.contained_items).is_empty()


func test_populate_items():
	"""Test populating container with items"""
	var items: Array[ItemData] = []
	items.append(create_test_item_data(1, 1, 100))
	items.append(create_test_item_data(2, 1, 200))
	items.append(create_test_item_data(1, 2, 150))
	
	container.populate_items(items)
	
	assert_int(container.get_item_count()).is_equal(3)


func test_add_single_item():
	"""Test adding a single item to container"""
	var item_data = create_test_item_data(1, 1, 100)
	
	var loot_item = container.add_item(item_data)
	
	assert_object(loot_item).is_not_null()
	assert_int(container.get_item_count()).is_equal(1)


func test_remove_item():
	"""Test removing an item from container"""
	var item_data = create_test_item_data(1, 1, 100)
	var loot_item = container.add_item(item_data)
	
	assert_int(container.get_item_count()).is_equal(1)
	
	container.remove_item(loot_item)
	
	assert_int(container.get_item_count()).is_equal(0)


func test_remove_item_not_in_container():
	"""Test removing an item that's not in the container"""
	var item_data = create_test_item_data(1, 1, 100)
	var loot_item = container.add_item(item_data)
	
	# Remove twice - second removal should have no effect
	container.remove_item(loot_item)
	assert_int(container.get_item_count()).is_equal(0)
	
	container.remove_item(loot_item)
	assert_int(container.get_item_count()).is_equal(0)


func test_container_becomes_empty_when_all_items_removed():
	"""Test that container state becomes EMPTY when all items are taken"""
	var item_data = create_test_item_data(1, 1, 100)
	var loot_item = container.add_item(item_data)
	
	container.open_container()
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.OPEN)
	
	container.remove_item(loot_item)
	
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.EMPTY)


func test_clear_items():
	"""Test clearing all items from container"""
	var items: Array[ItemData] = []
	for i in range(5):
		items.append(create_test_item_data(1, 1, 100))
	
	container.populate_items(items)
	assert_int(container.get_item_count()).is_equal(5)
	
	container.clear_items()
	
	assert_int(container.get_item_count()).is_equal(0)


# ==============================================================================
# VALUE TESTS
# ==============================================================================

func test_get_remaining_value():
	"""Test calculating total value of items in container"""
	var items: Array[ItemData] = []
	items.append(create_test_item_data(1, 1, 100))
	items.append(create_test_item_data(1, 1, 200))
	items.append(create_test_item_data(1, 1, 300))
	
	container.populate_items(items)
	
	assert_int(container.get_remaining_value()).is_equal(600)


func test_remaining_value_decreases_when_items_removed():
	"""Test that remaining value decreases as items are removed"""
	var items: Array[ItemData] = []
	items.append(create_test_item_data(1, 1, 100))
	items.append(create_test_item_data(1, 1, 200))
	
	container.populate_items(items)
	assert_int(container.get_remaining_value()).is_equal(300)
	
	# Remove one item
	var first_item = container.contained_items[0]
	container.remove_item(first_item)
	
	# Value should decrease by 100
	var remaining = container.get_remaining_value()
	assert_bool(remaining == 100 or remaining == 200).is_true()


func test_remaining_value_zero_when_empty():
	"""Test that remaining value is 0 when container is empty"""
	var items: Array[ItemData] = []
	items.append(create_test_item_data(1, 1, 100))
	
	container.populate_items(items)
	container.clear_items()
	
	assert_int(container.get_remaining_value()).is_equal(0)


# ==============================================================================
# PROPERTIES TESTS
# ==============================================================================

func test_container_name():
	"""Test container name property"""
	container.container_name = "Cargo Hold Alpha"
	
	assert_str(container.container_name).is_equal("Cargo Hold Alpha")


func test_slot_count():
	"""Test slot count property"""
	container.slot_count = 8
	
	assert_int(container.slot_count).is_equal(8)


func test_cell_size():
	"""Test cell size property"""
	container.cell_size = 48
	
	assert_int(container.cell_size).is_equal(48)


# ==============================================================================
# INTEGRATION TESTS
# ==============================================================================

func test_full_container_workflow():
	"""Test complete workflow: populate -> open -> remove items -> empty"""
	# Start closed
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.CLOSED)
	
	# Populate with items
	var items: Array[ItemData] = []
	items.append(create_test_item_data(1, 1, 100))
	items.append(create_test_item_data(2, 1, 200))
	container.populate_items(items)
	
	assert_int(container.get_item_count()).is_equal(2)
	assert_int(container.get_remaining_value()).is_equal(300)
	
	# Open container
	container.open_container()
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.OPEN)
	
	# Remove first item
	var first_item = container.contained_items[0]
	container.remove_item(first_item)
	assert_int(container.get_item_count()).is_equal(1)
	
	# Remove last item - should become empty
	var last_item = container.contained_items[0]
	container.remove_item(last_item)
	
	assert_int(container.get_item_count()).is_equal(0)
	assert_int(container.current_state).is_equal(CargoContainer.ContainerState.EMPTY)
	assert_int(container.get_remaining_value()).is_equal(0)


func test_multiple_populate_clears_previous():
	"""Test that populating container clears previous items"""
	# First populate
	var items1: Array[ItemData] = []
	items1.append(create_test_item_data(1, 1, 100))
	container.populate_items(items1)
	assert_int(container.get_item_count()).is_equal(1)
	
	# Second populate should clear first
	var items2: Array[ItemData] = []
	items2.append(create_test_item_data(1, 1, 200))
	items2.append(create_test_item_data(1, 1, 300))
	container.populate_items(items2)
	
	assert_int(container.get_item_count()).is_equal(2)
	assert_int(container.get_remaining_value()).is_equal(500)
