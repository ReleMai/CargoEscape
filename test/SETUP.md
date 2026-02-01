# Setting Up and Running Loot System Tests

This guide explains how to set up the testing framework and run the loot system tests.

## Prerequisites

- Godot 4.5 or later installed
- Git (for cloning GDUnit4 if needed)

## Installation

The GDUnit4 testing framework is already included in the `addons/gdUnit4/` directory and configured in `project.godot`.

### First-Time Setup

1. **Open the project in Godot**
   ```bash
   godot --editor project.godot
   ```

2. **Enable the GDUnit4 plugin**
   - The plugin is already configured in `project.godot` under `[editor_plugins]`
   - When you open the project, Godot should automatically load the plugin
   - You should see a "GDUnit4" tab at the bottom of the editor

3. **Verify installation**
   - Go to Project → Project Settings → Plugins
   - Ensure "gdUnit4" is checked/enabled

## Running Tests

### Option 1: Using Godot Editor (Recommended)

1. Open the project in Godot
2. Click on the "GDUnit4" tab at the bottom of the editor
3. The test panel will show all discovered tests
4. Click "Run All Tests" to run the entire suite
5. Or expand the tree and run individual test files

### Option 2: Using Command Line

#### Linux/Mac:
```bash
cd /path/to/CargoEscape
./addons/gdUnit4/runtest.sh --add test/
```

#### Windows:
```cmd
cd C:\path\to\CargoEscape
addons\gdUnit4\runtest.cmd --add test\
```

### Running Specific Tests

```bash
# Run only item_data tests
./addons/gdUnit4/runtest.sh --add test/loot/test_item_data.gd

# Run only inventory tests
./addons/gdUnit4/runtest.sh --add test/loot/test_inventory.gd

# Run with verbose output
./addons/gdUnit4/runtest.sh --add test/ --verbose
```

## Test Structure

```
test/
└── loot/
    ├── README.md              # Test documentation
    ├── test_item_data.gd      # ItemData tests (20+ tests)
    ├── test_inventory.gd      # GridInventory tests (35+ tests)
    ├── test_container.gd      # CargoContainer tests (20+ tests)
    └── test_loot_system.gd    # ItemDatabase/LootManager tests (35+ tests)
```

## Expected Results

All tests should pass on first run. The test suite includes:

- **110+ total tests** across all files
- **Item creation and properties** - Verifies item data correctness
- **Inventory grid logic** - Tests placement, removal, capacity
- **Container mechanics** - Tests states and item management
- **Loot generation** - Tests randomization, tables, and tiers

### Sample Output

```
Running: test_item_data.gd
  ✓ test_create_item_with_defaults
  ✓ test_create_item_with_static_helper
  ✓ test_grid_size_properties
  ...
  20 tests passed

Running: test_inventory.gd
  ✓ test_grid_initialized_correctly
  ✓ test_grid_starts_empty
  ✓ test_can_place_1x1_item
  ...
  35 tests passed

Running: test_container.gd
  ✓ test_container_starts_closed
  ✓ test_open_container
  ...
  20 tests passed

Running: test_loot_system.gd
  ✓ test_get_all_items
  ✓ test_roll_loot_tier_0
  ...
  35 tests passed

Total: 110 tests passed, 0 failed
```

## Troubleshooting

### Plugin not appearing
- Ensure Godot 4.5+ is being used
- Check that `addons/gdUnit4/plugin.cfg` exists
- Go to Project → Reload Current Project

### Tests not discovered
- Ensure test files start with `test_` prefix
- Ensure test files extend `GdUnitTestSuite`
- Ensure test methods start with `test_` prefix

### Import errors
- Ensure all dependencies are properly loaded
- Check that scene files exist (e.g., `res://scenes/loot/loot_item.tscn`)
- Try reimporting assets in Godot

### GDUnit4 not found
- If `addons/gdUnit4/` is missing, install it:
  ```bash
  cd addons
  git clone https://github.com/MikeSchulze/gdUnit4.git
  # Copy only the plugin:
  cp -r gdUnit4/addons/gdUnit4 .
  rm -rf gdUnit4
  ```

## Continuous Integration

For CI/CD pipelines, you can run tests headless:

```bash
godot --headless --path . --script addons/gdUnit4/bin/GdUnitCmdTool.gd --add test/ --quit
```

## Additional Resources

- [GDUnit4 Documentation](https://github.com/MikeSchulze/gdUnit4)
- [GDUnit4 API Reference](https://mikeschulze.github.io/gdUnit4/)
- Project loot system docs: `LOOT_SYSTEM_DOCS.md`

## Contributing

When adding new features to the loot system:

1. Write tests first (TDD approach)
2. Ensure all existing tests still pass
3. Add new tests to the appropriate test file
4. Update this documentation if needed
5. Run the full test suite before committing
