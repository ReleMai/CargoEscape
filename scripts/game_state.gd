# ==============================================================================
# GAME STATE - PERSISTENT PLAYER PROGRESS AND DATA
# ==============================================================================
#
# FILE: scripts/game_state.gd
# PURPOSE: Singleton managing persistent game state across sessions
#
# DATA STORED:
# - Player credits
# - Stash inventory
# - Equipped ship modules
# - Discovered/completed POIs
# - Run statistics
# - Black market prices
#
# ==============================================================================

extends Node
class_name GameStateManager


# ==============================================================================
# SIGNALS
# ==============================================================================

signal credits_changed(new_amount: int)
signal stash_changed()
signal ship_modules_changed()
signal poi_discovered(poi_id: String)
signal poi_completed(poi_id: String)
signal run_completed(stats: Dictionary)


# ==============================================================================
# CONSTANTS
# ==============================================================================

const STASH_MAX_ITEMS: int = 100
const MARKET_PRICE_VARIANCE: float = 0.3  # +/- 30% price variance
const MARKET_REFRESH_RUNS: int = 3  # Market restocks every X runs


# ==============================================================================
# STATE
# ==============================================================================

# Currency
var credits: int = 500:
	set(value):
		credits = maxi(0, value)
		credits_changed.emit(credits)

# Stash - Persistent storage
var stash_items: Array = []  # Array of ItemData/EquipmentData

# Ship configuration
var ship_tier: int = 1
var ship_modules: Dictionary = {
	"flight": null,   # ShipModule
	"combat": null,   # ShipModule
	"utility": null   # ShipModule
}
var owned_modules: Array = []  # Modules in storage (not equipped)

# Galaxy state
var discovered_pois: Array[String] = []
var completed_pois: Array[String] = []
var active_pois: Array = []  # Currently available POIs (GalaxyData.POI instances)
var current_poi: String = ""  # Currently selected POI ID

# Black market state
var market_stock: Array = []  # Items for sale
var market_prices: Dictionary = {}  # item_id -> current_price
var runs_since_restock: int = 0

# Statistics
var total_runs: int = 0
var successful_runs: int = 0
var total_loot_value: int = 0
var total_enemies_killed: int = 0
var highest_tier_completed: int = 0

# Current run state (reset each run)
var current_run: Dictionary = {
	"poi_id": "",
	"enemies_killed": 0,
	"enemies_required": 0,
	"loot_collected": [],
	"time_elapsed": 0.0,
	"time_limit": 90.0
}


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_initialize_defaults()


func _initialize_defaults() -> void:
	if active_pois.is_empty():
		refresh_galaxy_pois()
	
	if market_stock.is_empty():
		_refresh_market_stock()


# ==============================================================================
# CREDITS
# ==============================================================================

func add_credits(amount: int) -> void:
	credits += amount


func spend_credits(amount: int) -> bool:
	if credits >= amount:
		credits -= amount
		return true
	return false


func can_afford(amount: int) -> bool:
	return credits >= amount


# ==============================================================================
# STASH MANAGEMENT
# ==============================================================================

func add_to_stash(item) -> bool:
	if stash_items.size() >= STASH_MAX_ITEMS:
		return false
	
	stash_items.append(item)
	stash_changed.emit()
	return true


func remove_from_stash(item) -> bool:
	var idx = stash_items.find(item)
	if idx >= 0:
		stash_items.remove_at(idx)
		stash_changed.emit()
		return true
	return false


func get_stash_items() -> Array:
	return stash_items.duplicate()


func get_stash_count() -> int:
	return stash_items.size()


func clear_stash() -> void:
	stash_items.clear()
	stash_changed.emit()


# ==============================================================================
# SHIP MODULES
# ==============================================================================

func equip_module(module, slot: String) -> bool:
	if slot not in ship_modules:
		return false
	
	# Unequip current module first
	var current = ship_modules[slot]
	if current:
		owned_modules.append(current)
	
	# Remove from owned if it was there
	var idx = owned_modules.find(module)
	if idx >= 0:
		owned_modules.remove_at(idx)
	
	ship_modules[slot] = module
	ship_modules_changed.emit()
	return true


func unequip_module(slot: String) -> bool:
	if slot not in ship_modules:
		return false
	
	var module = ship_modules[slot]
	if module:
		owned_modules.append(module)
		ship_modules[slot] = null
		ship_modules_changed.emit()
		return true
	return false


func get_equipped_module(slot: String):
	return ship_modules.get(slot)


func get_owned_modules() -> Array:
	return owned_modules.duplicate()


func add_module_to_storage(module) -> void:
	owned_modules.append(module)
	ship_modules_changed.emit()


func get_ship_combat_bonus() -> float:
	var module = ship_modules.get("combat")
	if module and module is ShipModule:
		return module.damage
	return 0.0


func get_ship_speed_bonus() -> float:
	var module = ship_modules.get("flight")
	if module and module is ShipModule:
		return module.thrust_power
	return 0.0


func get_ship_utility_bonus() -> Dictionary:
	var module = ship_modules.get("utility")
	if module and module is ShipModule:
		return {
			"shield": module.shield_capacity,
			"cargo": module.cargo_bonus,
			"scan": module.scan_range
		}
	return {"shield": 0, "cargo": 0, "scan": 0}


# ==============================================================================
# GALAXY / POI MANAGEMENT
# ==============================================================================

func refresh_galaxy_pois() -> void:
	active_pois.clear()
	
	var templates = GalaxyData.get_poi_templates()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Generate 8-12 active POIs
	var count = rng.randi_range(8, 12)
	var available_templates = templates.duplicate()
	available_templates.shuffle()
	
	for i in range(mini(count, available_templates.size())):
		var template = available_templates[i]
		var poi = _create_poi_instance(template, rng)
		active_pois.append(poi)
	
	# Always include at least 2 easy POIs
	var easy_count = 0
	for poi in active_pois:
		if poi.difficulty == GalaxyData.Difficulty.EASY:
			easy_count += 1
	
	if easy_count < 2:
		for template in templates:
			if template.difficulty == GalaxyData.Difficulty.EASY:
				if not _has_poi_with_id(template.id):
					var poi = _create_poi_instance(template, rng)
					active_pois.append(poi)
					easy_count += 1
					if easy_count >= 2:
						break


func _create_poi_instance(template, rng: RandomNumberGenerator):
	var poi = GalaxyData.POI.new(template.id, template.name)
	poi.description = template.description
	poi.poi_type = template.poi_type
	poi.region = template.region
	poi.faction = template.faction
	poi.difficulty = template.difficulty
	poi.min_ship_tier = template.min_ship_tier
	poi.base_credits = template.base_credits
	poi.loot_tier_min = template.loot_tier_min
	poi.loot_tier_max = template.loot_tier_max
	poi.special_loot_chance = template.special_loot_chance
	
	# Randomize position within region
	var region = GalaxyData.get_region(poi.region)
	if region:
		var angle = rng.randf() * TAU
		var dist = rng.randf() * region.radius * 0.8
		poi.position = region.center + Vector2(cos(angle), sin(angle)) * dist
	
	poi.discovered = poi.id in discovered_pois
	poi.completed = poi.id in completed_pois
	poi.available = _check_poi_requirements(poi)
	
	return poi


func _has_poi_with_id(poi_id: String) -> bool:
	for poi in active_pois:
		if poi.id == poi_id:
			return true
	return false


func _check_poi_requirements(poi) -> bool:
	# Check ship tier
	if ship_tier < poi.min_ship_tier:
		return false
	
	# Check required modules
	for mod_id in poi.required_modules:
		var has_module = false
		for slot in ship_modules:
			var mod = ship_modules[slot]
			if mod and mod.module_id == mod_id:
				has_module = true
				break
		if not has_module:
			return false
	
	return true


func discover_poi(poi_id: String) -> void:
	if poi_id not in discovered_pois:
		discovered_pois.append(poi_id)
		poi_discovered.emit(poi_id)
		
		for poi in active_pois:
			if poi.id == poi_id:
				poi.discovered = true
				break


func complete_poi(poi_id: String) -> void:
	if poi_id not in completed_pois:
		completed_pois.append(poi_id)
		poi_completed.emit(poi_id)
		
		for poi in active_pois:
			if poi.id == poi_id:
				poi.completed = true
				break


func get_active_pois() -> Array:
	return active_pois


func get_poi(poi_id: String):
	for poi in active_pois:
		if poi.id == poi_id:
			return poi
	return null


func select_poi(poi_id: String) -> bool:
	var poi = get_poi(poi_id)
	if poi and poi.available:
		current_poi = poi_id
		return true
	return false


# ==============================================================================
# BLACK MARKET
# ==============================================================================

func _refresh_market_stock() -> void:
	market_stock.clear()
	market_prices.clear()
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Generate 10-15 items for sale
	var item_count = rng.randi_range(10, 15)
	
	# Include weapons
	_add_market_weapons(rng, 4)
	
	# Include gear
	_add_market_gear(rng, 3)
	
	# Include modules
	_add_market_modules(rng, 3)
	
	# Include general items
	_add_market_items(rng, 5)


func _add_market_weapons(rng: RandomNumberGenerator, count: int) -> void:
	var weapon_ids = [
		"pistol_basic", "pistol_compact", "pistol_nexus",
		"rifle_assault", "rifle_marksman", "rifle_burst"
	]
	weapon_ids.shuffle()
	
	for i in range(mini(count, weapon_ids.size())):
		var weapon_id = weapon_ids[i]
		var base_price = _get_weapon_base_price(weapon_id)
		var variance = rng.randf_range(-MARKET_PRICE_VARIANCE, MARKET_PRICE_VARIANCE)
		market_prices[weapon_id] = int(base_price * (1.0 + variance))
		market_stock.append({"type": "weapon", "id": weapon_id})


func _add_market_gear(rng: RandomNumberGenerator, count: int) -> void:
	var gear_ids = [
		"vest_basic", "helmet_basic", "boots_basic",
		"vest_tactical", "helmet_tactical"
	]
	gear_ids.shuffle()
	
	for i in range(mini(count, gear_ids.size())):
		var gear_id = gear_ids[i]
		var base_price = _get_gear_base_price(gear_id)
		var variance = rng.randf_range(-MARKET_PRICE_VARIANCE, MARKET_PRICE_VARIANCE)
		market_prices[gear_id] = int(base_price * (1.0 + variance))
		market_stock.append({"type": "gear", "id": gear_id})


func _add_market_modules(rng: RandomNumberGenerator, count: int) -> void:
	var module_ids = [
		"basic_laser", "burst_cannon", "plasma_cutter",
		"basic_engine", "afterburner", "nav_computer",
		"basic_shield", "cargo_expansion", "scanner"
	]
	module_ids.shuffle()
	
	for i in range(mini(count, module_ids.size())):
		var mod_id = module_ids[i]
		var base_price = _get_module_base_price(mod_id)
		var variance = rng.randf_range(-MARKET_PRICE_VARIANCE, MARKET_PRICE_VARIANCE)
		market_prices[mod_id] = int(base_price * (1.0 + variance))
		market_stock.append({"type": "module", "id": mod_id})


func _add_market_items(rng: RandomNumberGenerator, count: int) -> void:
	# Add generic items
	for i in range(count):
		var item_id = "item_%d" % i
		var base_price = rng.randi_range(50, 300)
		market_prices[item_id] = base_price
		market_stock.append({"type": "item", "id": item_id})


func _get_weapon_base_price(weapon_id: String) -> int:
	# Base prices by weapon type
	if "nexus" in weapon_id or "gold" in weapon_id:
		return 2000
	elif "assault" in weapon_id or "marksman" in weapon_id:
		return 800
	elif "compact" in weapon_id:
		return 300
	return 400


func _get_gear_base_price(gear_id: String) -> int:
	if "tactical" in gear_id:
		return 600
	return 250


func _get_module_base_price(module_id: String) -> int:
	if "plasma" in module_id or "afterburner" in module_id:
		return 1500
	elif "burst" in module_id or "scanner" in module_id:
		return 800
	return 400


func get_market_stock() -> Array:
	return market_stock.duplicate()


func get_market_price(item_id: String) -> int:
	return market_prices.get(item_id, 100)


func get_sell_price(item) -> int:
	# Sell price is 40% of base value
	if item.has_method("get") and item.get("base_value"):
		return int(item.base_value * 0.4)
	return 50


func buy_from_market(item_id: String) -> bool:
	var price = get_market_price(item_id)
	if not can_afford(price):
		return false
	
	# Find and remove from stock
	for i in range(market_stock.size()):
		if market_stock[i].id == item_id:
			spend_credits(price)
			market_stock.remove_at(i)
			return true
	
	return false


func sell_to_market(item) -> int:
	var price = get_sell_price(item)
	add_credits(price)
	return price


func check_market_refresh() -> void:
	runs_since_restock += 1
	if runs_since_restock >= MARKET_REFRESH_RUNS:
		runs_since_restock = 0
		_refresh_market_stock()


# ==============================================================================
# RUN MANAGEMENT
# ==============================================================================

func start_run(poi_id: String) -> void:
	var poi = get_poi(poi_id)
	if not poi:
		return
	
	current_run = {
		"poi_id": poi_id,
		"enemies_killed": 0,
		"enemies_required": poi.get_enemy_count(),
		"loot_collected": [],
		"time_elapsed": 0.0,
		"time_limit": poi.get_time_limit()
	}
	
	discover_poi(poi_id)


func record_enemy_kill() -> void:
	current_run.enemies_killed += 1
	total_enemies_killed += 1


func record_loot(item) -> void:
	current_run.loot_collected.append(item)


func can_escape() -> bool:
	return current_run.enemies_killed >= current_run.enemies_required


func get_enemies_remaining() -> int:
	return maxi(0, current_run.enemies_required - current_run.enemies_killed)


func end_run(success: bool) -> Dictionary:
	total_runs += 1
	
	var stats = {
		"success": success,
		"poi_id": current_run.poi_id,
		"enemies_killed": current_run.enemies_killed,
		"loot_count": current_run.loot_collected.size(),
		"time_elapsed": current_run.time_elapsed
	}
	
	if success:
		successful_runs += 1
		complete_poi(current_run.poi_id)
		
		# Calculate loot value
		var loot_value = 0
		for item in current_run.loot_collected:
			if item.has_method("get") and item.get("base_value"):
				loot_value += item.base_value
		
		total_loot_value += loot_value
		stats.loot_value = loot_value
		
		# Add credits from POI
		var poi = get_poi(current_run.poi_id)
		if poi:
			add_credits(poi.base_credits)
			stats.bonus_credits = poi.base_credits
		
		# Update highest tier
		if poi and poi.min_ship_tier > highest_tier_completed:
			highest_tier_completed = poi.min_ship_tier
	
	# Check for market refresh
	check_market_refresh()
	
	# Refresh POIs after every 3 runs
	if total_runs % 3 == 0:
		refresh_galaxy_pois()
	
	run_completed.emit(stats)
	return stats


# ==============================================================================
# SAVE / LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
	var module_data = {}
	for slot in ship_modules:
		var mod = ship_modules[slot]
		if mod:
			module_data[slot] = mod.resource_path if mod.resource_path else mod.module_id
		else:
			module_data[slot] = ""
	
	return {
		"credits": credits,
		"ship_tier": ship_tier,
		"ship_modules": module_data,
		"discovered_pois": discovered_pois,
		"completed_pois": completed_pois,
		"total_runs": total_runs,
		"successful_runs": successful_runs,
		"total_loot_value": total_loot_value,
		"total_enemies_killed": total_enemies_killed,
		"highest_tier_completed": highest_tier_completed,
		"runs_since_restock": runs_since_restock
	}


func load_save_data(data: Dictionary) -> void:
	credits = data.get("credits", 500)
	ship_tier = data.get("ship_tier", 1)
	discovered_pois = data.get("discovered_pois", [])
	completed_pois = data.get("completed_pois", [])
	total_runs = data.get("total_runs", 0)
	successful_runs = data.get("successful_runs", 0)
	total_loot_value = data.get("total_loot_value", 0)
	total_enemies_killed = data.get("total_enemies_killed", 0)
	highest_tier_completed = data.get("highest_tier_completed", 0)
	runs_since_restock = data.get("runs_since_restock", 0)
	
	# Refresh POIs with saved discovery state
	refresh_galaxy_pois()
