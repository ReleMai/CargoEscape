## Debug Logger - Centralized logging system for game debugging
## Tracks player actions, game state, and system events
extends Node

# ==============================================================================
# CONFIGURATION
# ==============================================================================

## Enable/disable logging categories
var log_player_actions: bool = true
var log_inventory: bool = true
var log_game_state: bool = true
var log_scene_loading: bool = true
var log_containers: bool = true
var log_combat: bool = false  # Verbose, disabled by default
var log_performance: bool = false  # Disabled by default

## Log level: 0=ERROR, 1=WARN, 2=INFO, 3=DEBUG, 4=VERBOSE
var log_level: int = 2

## Session data
var session_id: String = ""
var session_start_time: float = 0.0
var action_count: int = 0

## Recent actions buffer (for crash reports)
var recent_actions: Array[String] = []
const MAX_RECENT_ACTIONS: int = 50

## Performance tracking
var frame_times: Array[float] = []
var last_frame_time: float = 0.0

# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	session_id = _generate_session_id()
	session_start_time = Time.get_unix_time_from_system()
	last_frame_time = Time.get_ticks_msec()
	
	_log_system("=".repeat(60))
	_log_system("DEBUG SESSION STARTED: %s" % session_id)
	_log_system("Time: %s" % Time.get_datetime_string_from_system())
	_log_system("Godot Version: %s" % Engine.get_version_info().string)
	_log_system("=".repeat(60))


func _process(_delta: float) -> void:
	if log_performance:
		var current_time = Time.get_ticks_msec()
		var frame_time = current_time - last_frame_time
		last_frame_time = current_time
		
		frame_times.append(frame_time)
		if frame_times.size() > 60:
			frame_times.pop_front()


func _generate_session_id() -> String:
	var time = Time.get_unix_time_from_system()
	return "S%d" % (int(time) % 100000)

# ==============================================================================
# LOGGING METHODS
# ==============================================================================

func _log_system(message: String) -> void:
	print("[DEBUG] %s" % message)
	_add_to_recent("[SYS] %s" % message)


func _add_to_recent(message: String) -> void:
	var timestamp = "%.2f" % (Time.get_ticks_msec() / 1000.0)
	recent_actions.append("[%s] %s" % [timestamp, message])
	if recent_actions.size() > MAX_RECENT_ACTIONS:
		recent_actions.pop_front()

# ==============================================================================
# PLAYER ACTIONS
# ==============================================================================

## Log player movement/input
func log_player_action(action: String, details: Dictionary = {}) -> void:
	if not log_player_actions:
		return
	action_count += 1
	var detail_str = _dict_to_string(details) if not details.is_empty() else ""
	var msg = "[PLAYER] #%d %s %s" % [action_count, action, detail_str]
	if log_level >= 3:
		print(msg)
	_add_to_recent(msg)


## Log player interaction with objects
func log_interaction(target: String, interaction_type: String, result: String = "") -> void:
	if not log_player_actions:
		return
	action_count += 1
	var msg = "[INTERACT] #%d %s -> %s" % [action_count, interaction_type, target]
	if result:
		msg += " = %s" % result
	print(msg)
	_add_to_recent(msg)

# ==============================================================================
# INVENTORY LOGGING
# ==============================================================================

## Log inventory changes
func log_inventory_change(change_type: String, item_name: String, details: Dictionary = {}) -> void:
	if not log_inventory:
		return
	var detail_str = _dict_to_string(details) if not details.is_empty() else ""
	var msg = "[INV] %s: %s %s" % [change_type, item_name, detail_str]
	print(msg)
	_add_to_recent(msg)


## Log inventory state summary
func log_inventory_state(inventory_name: String, item_count: int, total_value: int, weight: float) -> void:
	if not log_inventory or log_level < 2:
		return
	var msg = "[INV] %s: %d items, $%d, %.1fkg" % [inventory_name, item_count, total_value, weight]
	print(msg)
	_add_to_recent(msg)

# ==============================================================================
# GAME STATE LOGGING
# ==============================================================================

## Log scene transitions
func log_scene_change(from_scene: String, to_scene: String, load_time_ms: float = 0.0) -> void:
	if not log_scene_loading:
		return
	var msg = "[SCENE] %s -> %s" % [from_scene, to_scene]
	if load_time_ms > 0:
		msg += " (%.0fms)" % load_time_ms
	print(msg)
	_add_to_recent(msg)


## Log game state changes
func log_state_change(state_name: String, old_value, new_value) -> void:
	if not log_game_state:
		return
	var msg = "[STATE] %s: %s -> %s" % [state_name, str(old_value), str(new_value)]
	print(msg)
	_add_to_recent(msg)


## Log boarding session info
func log_boarding_start(ship_tier: int, room_count: int, container_count: int, time_limit: float) -> void:
	if not log_game_state:
		return
	print("[BOARDING] Started: Tier %d, %d rooms, %d containers, %.0fs limit" % [
		ship_tier, room_count, container_count, time_limit])
	_add_to_recent("[BOARDING] Tier %d started" % ship_tier)


func log_boarding_end(escaped: bool, loot_value: int, time_remaining: float, items_collected: int) -> void:
	if not log_game_state:
		return
	var result = "ESCAPED" if escaped else "FAILED"
	print("[BOARDING] %s: $%d loot, %d items, %.1fs remaining" % [
		result, loot_value, items_collected, time_remaining])
	_add_to_recent("[BOARDING] %s with $%d" % [result, loot_value])

# ==============================================================================
# CONTAINER LOGGING
# ==============================================================================

## Log container interaction
func log_container_opened(container_type: String, item_count: int, total_value: int) -> void:
	if not log_containers:
		return
	print("[CONTAINER] Opened %s: %d items worth $%d" % [container_type, item_count, total_value])
	_add_to_recent("[CONTAINER] %s opened" % container_type)


func log_container_looted(item_name: String, value: int, rarity: int) -> void:
	if not log_containers:
		return
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	var rarity_str = rarity_names[rarity] if rarity < rarity_names.size() else "Unknown"
	if log_level >= 3:
		print("[LOOT] %s ($%d, %s)" % [item_name, value, rarity_str])
	_add_to_recent("[LOOT] %s" % item_name)

# ==============================================================================
# ERROR/WARNING LOGGING
# ==============================================================================

## Log errors with context
func log_error(category: String, message: String, context: Dictionary = {}) -> void:
	var ctx_str = _dict_to_string(context) if not context.is_empty() else ""
	var msg = "[ERROR] [%s] %s %s" % [category, message, ctx_str]
	push_error(msg)
	_add_to_recent(msg)


## Log warnings
func log_warning(category: String, message: String) -> void:
	if log_level < 1:
		return
	var msg = "[WARN] [%s] %s" % [category, message]
	push_warning(msg)
	_add_to_recent(msg)

# ==============================================================================
# PERFORMANCE LOGGING
# ==============================================================================

## Get performance summary
func get_performance_summary() -> Dictionary:
	if frame_times.is_empty():
		return {}
	
	var avg_frame = 0.0
	var max_frame = 0.0
	for ft in frame_times:
		avg_frame += ft
		max_frame = max(max_frame, ft)
	avg_frame /= frame_times.size()
	
	return {
		"avg_frame_ms": avg_frame,
		"max_frame_ms": max_frame,
		"avg_fps": 1000.0 / avg_frame if avg_frame > 0 else 0,
		"action_count": action_count
	}


## Log performance snapshot
func log_performance_snapshot() -> void:
	if not log_performance:
		return
	var perf = get_performance_summary()
	if perf.is_empty():
		return
	print("[PERF] FPS: %.1f (avg frame: %.1fms, max: %.1fms)" % [
		perf.avg_fps, perf.avg_frame_ms, perf.max_frame_ms])

# ==============================================================================
# CRASH REPORT
# ==============================================================================

## Get recent actions for crash debugging
func get_crash_report() -> String:
	var report = "=== CRASH REPORT ===\n"
	report += "Session: %s\n" % session_id
	report += "Uptime: %.1fs\n" % ((Time.get_unix_time_from_system() - session_start_time))
	report += "Actions: %d\n\n" % action_count
	report += "Recent Actions:\n"
	for action in recent_actions:
		report += "  %s\n" % action
	report += "\nPerformance:\n"
	var perf = get_performance_summary()
	for key in perf:
		report += "  %s: %s\n" % [key, str(perf[key])]
	return report


## Print crash report to console
func print_crash_report() -> void:
	print(get_crash_report())

# ==============================================================================
# UTILITIES
# ==============================================================================

func _dict_to_string(d: Dictionary) -> String:
	if d.is_empty():
		return ""
	var parts: Array[String] = []
	for key in d:
		parts.append("%s=%s" % [key, str(d[key])])
	return "{%s}" % ", ".join(parts)


## Shorthand logging methods
func info(message: String) -> void:
	if log_level >= 2:
		print("[INFO] %s" % message)
		_add_to_recent("[INFO] %s" % message)


func debug(message: String) -> void:
	if log_level >= 3:
		print("[DEBUG] %s" % message)
		_add_to_recent(message)


func verbose(message: String) -> void:
	if log_level >= 4:
		print("[VERBOSE] %s" % message)
