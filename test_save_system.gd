# ==============================================================================
# SAVE SYSTEM TEST SCRIPT
# ==============================================================================
#
# FILE: test_save_system.gd
# PURPOSE: Manual test script to verify save/load functionality
#
# HOW TO USE:
# -----------
# 1. Attach this script to a Node in a test scene
# 2. Run the scene
# 3. Check the console output for test results
#
# This script will:
# - Create test data in GameManager
# - Save the game
# - Clear GameManager
# - Load the game
# - Verify data was restored correctly
#
# ==============================================================================

extends Node

var game_manager: Node
var save_manager: Node


func _ready() -> void:
	# Wait a frame for autoloads to initialize
	await get_tree().process_frame
	
	# Get references
	game_manager = get_node("/root/GameManager")
	save_manager = get_node("/root/SaveManager")
	
	if not game_manager or not save_manager:
		print("[TEST] ERROR: Could not get GameManager or SaveManager!")
		return
	
	print("[TEST] Starting save system tests...")
	print("=" * 60)
	
	# Run tests
	await get_tree().create_timer(0.5).timeout
	test_save_and_load()


func test_save_and_load() -> void:
	print("\n[TEST] Test 1: Save and Load Basic Data")
	print("-" * 60)
	
	# Set up test data
	print("[TEST] Setting up test data...")
	game_manager.credits = 1000
	game_manager.health_upgrade_level = 2
	game_manager.laser_upgrade_level = 3
	game_manager.ship_inventory_upgrade = 1
	game_manager.stash_inventory_upgrade = 2
	game_manager.ship_type = 1
	game_manager.loot_tier = 2
	
	print("[TEST] Test data:")
	print("  Credits: ", game_manager.credits)
	print("  Health upgrades: ", game_manager.health_upgrade_level)
	print("  Laser upgrades: ", game_manager.laser_upgrade_level)
	print("  Ship inventory upgrades: ", game_manager.ship_inventory_upgrade)
	print("  Stash inventory upgrades: ", game_manager.stash_inventory_upgrade)
	print("  Ship type: ", game_manager.ship_type)
	print("  Loot tier: ", game_manager.loot_tier)
	
	# Save
	print("\n[TEST] Saving game...")
	var save_success = save_manager.save_game()
	if not save_success:
		print("[TEST] FAILED: Save operation failed!")
		return
	print("[TEST] Save successful!")
	
	# Modify data to different values
	print("\n[TEST] Modifying data to verify load...")
	game_manager.credits = 0
	game_manager.health_upgrade_level = 0
	game_manager.laser_upgrade_level = 0
	game_manager.ship_inventory_upgrade = 0
	game_manager.stash_inventory_upgrade = 0
	game_manager.ship_type = 0
	game_manager.loot_tier = 0
	
	print("[TEST] Modified data:")
	print("  Credits: ", game_manager.credits)
	print("  Health upgrades: ", game_manager.health_upgrade_level)
	print("  Laser upgrades: ", game_manager.laser_upgrade_level)
	
	# Load
	print("\n[TEST] Loading game...")
	var load_success = save_manager.load_game()
	if not load_success:
		print("[TEST] FAILED: Load operation failed!")
		return
	print("[TEST] Load successful!")
	
	# Verify data
	print("\n[TEST] Verifying loaded data...")
	var test_passed = true
	
	if game_manager.credits != 1000:
		print("[TEST] FAILED: Credits mismatch. Expected 1000, got ", game_manager.credits)
		test_passed = false
	
	if game_manager.health_upgrade_level != 2:
		print("[TEST] FAILED: Health upgrades mismatch. Expected 2, got ", game_manager.health_upgrade_level)
		test_passed = false
	
	if game_manager.laser_upgrade_level != 3:
		print("[TEST] FAILED: Laser upgrades mismatch. Expected 3, got ", game_manager.laser_upgrade_level)
		test_passed = false
	
	if game_manager.ship_inventory_upgrade != 1:
		print("[TEST] FAILED: Ship inventory upgrades mismatch. Expected 1, got ", game_manager.ship_inventory_upgrade)
		test_passed = false
	
	if game_manager.stash_inventory_upgrade != 2:
		print("[TEST] FAILED: Stash inventory upgrades mismatch. Expected 2, got ", game_manager.stash_inventory_upgrade)
		test_passed = false
	
	if game_manager.ship_type != 1:
		print("[TEST] FAILED: Ship type mismatch. Expected 1, got ", game_manager.ship_type)
		test_passed = false
	
	if game_manager.loot_tier != 2:
		print("[TEST] FAILED: Loot tier mismatch. Expected 2, got ", game_manager.loot_tier)
		test_passed = false
	
	if test_passed:
		print("[TEST] PASSED: All data verified correctly!")
		print("\n[TEST] Loaded data:")
		print("  Credits: ", game_manager.credits)
		print("  Health upgrades: ", game_manager.health_upgrade_level)
		print("  Laser upgrades: ", game_manager.laser_upgrade_level)
		print("  Ship inventory upgrades: ", game_manager.ship_inventory_upgrade)
		print("  Stash inventory upgrades: ", game_manager.stash_inventory_upgrade)
		print("  Ship type: ", game_manager.ship_type)
		print("  Loot tier: ", game_manager.loot_tier)
	
	print("\n" + "=" * 60)
	print("[TEST] Save system test completed!")
	print("=" * 60)
	
	# Print save file location
	print("\n[TEST] Save file location:")
	print("  ", ProjectSettings.globalize_path("user://save_data.cfg"))
	
	# Print save file contents
	print("\n[TEST] Save file contents:")
	save_manager.print_save_file()
	
	# Clean up - reset to defaults
	await get_tree().create_timer(1.0).timeout
	print("\n[TEST] Resetting GameManager to defaults...")
	game_manager.credits = 0
	game_manager.health_upgrade_level = 0
	game_manager.laser_upgrade_level = 0
	game_manager.ship_inventory_upgrade = 0
	game_manager.stash_inventory_upgrade = 0
	game_manager.ship_type = 0
	game_manager.loot_tier = 0
