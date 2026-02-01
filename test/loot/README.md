# Loot System Tests

This directory contains unit tests for the Cargo Escape loot system using GDUnit4.

## Test Files

### test_item_data.gd
Tests for the `ItemData` resource class:
- Item creation and initialization
- Item properties (grid size, value, rarity, category)
- Computed properties (cell_count, search_time, value_density)
- Rarity names and colors
- Static helper functions

### test_inventory.gd
Tests for the `GridInventory` class:
- Grid initialization
- Item placement validation (can_place_at, place_item)
- Item removal
- Capacity limits
- Grid positioning
- Auto-placement logic
- Value tracking

### test_container.gd
Tests for the `CargoContainer` class:
- Container states (CLOSED, OPEN, EMPTY)
- Container opening/closing
- Item population
- Item addition and removal
- Value calculations

### test_loot_system.gd
Tests for the loot generation system (`ItemDatabase`):
- Item database access
- Loot table rolls
- Rarity-based item generation
- Weighted item selection
- Tier-based loot generation
- Item creation from definitions
- Statistical distribution tests

## Running Tests

### In Godot Editor
1. Open the project in Godot 4.x
2. The GDUnit4 plugin should be enabled automatically
3. Go to the GDUnit4 panel (usually at bottom of editor)
4. Click "Run All Tests" to run the entire test suite
5. Or navigate to individual test files and run them separately

### From Command Line
```bash
# Run all tests
./addons/gdUnit4/runtest.sh --add test/

# Run specific test file
./addons/gdUnit4/runtest.sh --add test/loot/test_item_data.gd

# Run with verbose output
./addons/gdUnit4/runtest.sh --add test/ --verbose
```

## Test Coverage

The test suite provides comprehensive coverage of the loot system:

- **ItemData**: 20+ tests covering all item properties and computed functions
- **GridInventory**: 35+ tests covering placement, removal, capacity, and utilities
- **CargoContainer**: 20+ tests covering states, items, and workflows
- **ItemDatabase/LootSystem**: 35+ tests covering generation, tables, and statistics

## Requirements

- Godot 4.5 or later
- GDUnit4 plugin (included in `addons/gdUnit4/`)

## Notes

- Tests are isolated and can run in any order
- Each test has proper setup/teardown to avoid state pollution
- Tests use realistic item data and scenarios
- Statistical tests use sampling to verify probability distributions

## Adding New Tests

When adding new loot system features:

1. Create tests first (TDD approach recommended)
2. Follow the existing test structure and naming conventions
3. Use descriptive test names that explain what is being tested
4. Add comments for complex test logic
5. Ensure tests are isolated and deterministic

Example test structure:
```gdscript
func test_feature_description():
    """Test that feature works as expected"""
    # Setup
    var item = create_test_item()
    
    # Action
    var result = item.some_function()
    
    # Assert
    assert_object(result).is_not_null()
    assert_int(result.value).is_equal(expected_value)
```
