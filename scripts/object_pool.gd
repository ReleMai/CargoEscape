# ==============================================================================
# OBJECT POOL - PERFORMANCE OPTIMIZATION SYSTEM
# ==============================================================================
#
# FILE: scripts/object_pool.gd
# PURPOSE: Generic object pooling system for frequently spawned/destroyed objects
#
# FEATURES:
# - Generic pooling for any scene type
# - Pre-instantiation to reduce runtime overhead
# - Automatic pool size management
# - Reset callbacks for object reuse
# - Separate pools per scene type
#
# USAGE:
# ------
# # Initialize a pool (usually in _ready):
# ObjectPool.create_pool(laser_scene, 50)
#
# # Acquire an object from the pool:
# var laser = ObjectPool.acquire(laser_scene)
# laser.position = spawn_position
# add_child(laser)
#
# # Release an object back to the pool (instead of queue_free):
# ObjectPool.release(laser)
#
# ==============================================================================

extends Node


# ==============================================================================
# POOL STRUCTURE
# ==============================================================================

## Dictionary of pools, keyed by scene path
## Each pool contains: { available: Array[Node], in_use: Array[Node], scene: PackedScene }
var pools: Dictionary = {}


# ==============================================================================
# POOL MANAGEMENT
# ==============================================================================

## Create a new pool for a scene type
## @param scene: The PackedScene to pool
## @param initial_size: Number of objects to pre-instantiate
func create_pool(scene: PackedScene, initial_size: int = 10) -> void:
	if scene == null:
		push_error("[ObjectPool] Cannot create pool for null scene")
		return
	
	var scene_path := scene.resource_path
	
	# Don't recreate if pool already exists
	if scene_path in pools:
		print("[ObjectPool] Pool already exists for: ", scene_path)
		return
	
	# Create pool structure
	pools[scene_path] = {
		"available": [],
		"in_use": [],
		"scene": scene
	}
	
	# Pre-instantiate objects
	for i in initial_size:
		var obj := scene.instantiate()
		_prepare_pooled_object(obj)
		pools[scene_path]["available"].append(obj)
	
	print("[ObjectPool] Created pool for ", scene_path, " with ", initial_size, " objects")


## Acquire an object from the pool
## @param scene: The PackedScene type to acquire
## @return: An instance of the scene, either from pool or newly created
func acquire(scene: PackedScene) -> Node:
	if scene == null:
		push_error("[ObjectPool] Cannot acquire from null scene")
		return null
	
	var scene_path := scene.resource_path
	
	# Create pool if it doesn't exist
	if scene_path not in pools:
		create_pool(scene, 10)
	
	var pool := pools[scene_path]
	var obj: Node
	
	# Reuse from available pool if possible
	if pool["available"].size() > 0:
		obj = pool["available"].pop_back()
	else:
		# Create new instance if pool is empty
		obj = scene.instantiate()
		_prepare_pooled_object(obj)
	
	# Mark as in use
	pool["in_use"].append(obj)
	
	# Reset the object for reuse
	if obj.has_method("reset"):
		obj.call("reset")
	
	# Make object visible and active
	obj.visible = true
	obj.process_mode = Node.PROCESS_MODE_INHERIT
	
	return obj


## Release an object back to the pool
## @param obj: The object to release
func release(obj: Node) -> void:
	if obj == null:
		return
	
	# Find which pool this object belongs to
	var scene_path := _get_scene_path_for_object(obj)
	if scene_path == "":
		# Object not in any pool, just free it
		obj.queue_free()
		return
	
	var pool := pools[scene_path]
	
	# Remove from in_use
	var idx := pool["in_use"].find(obj)
	if idx >= 0:
		pool["in_use"].remove_at(idx)
	
	# Prepare for pooling
	_deactivate_object(obj)
	
	# Return to available pool
	pool["available"].append(obj)


## Reparent a pooled object to a new parent
## @param obj: The pooled object to reparent
## @param new_parent: The new parent node
func reparent_pooled_object(obj: Node, new_parent: Node) -> void:
	if obj == null or new_parent == null:
		return
	
	# Remove from current parent if different
	if obj.get_parent() != null and obj.get_parent() != new_parent:
		obj.get_parent().remove_child(obj)
	
	# Add to new parent
	if obj.get_parent() == null:
		new_parent.add_child(obj)


## Clear a specific pool
## @param scene: The PackedScene type to clear
func clear_pool(scene: PackedScene) -> void:
	if scene == null:
		return
	
	var scene_path := scene.resource_path
	if scene_path not in pools:
		return
	
	var pool := pools[scene_path]
	
	# Free all objects
	for obj in pool["available"]:
		if is_instance_valid(obj):
			obj.queue_free()
	for obj in pool["in_use"]:
		if is_instance_valid(obj):
			obj.queue_free()
	
	# Remove pool
	pools.erase(scene_path)
	print("[ObjectPool] Cleared pool for: ", scene_path)


## Clear all pools
func clear_all_pools() -> void:
	for scene_path in pools.keys():
		var pool := pools[scene_path]
		
		# Free all objects
		for obj in pool["available"]:
			if is_instance_valid(obj):
				obj.queue_free()
		for obj in pool["in_use"]:
			if is_instance_valid(obj):
				obj.queue_free()
	
	pools.clear()
	print("[ObjectPool] Cleared all pools")


## Get pool statistics
## @param scene: The PackedScene to get stats for (optional)
## @return: Dictionary with pool statistics
func get_stats(scene: PackedScene = null) -> Dictionary:
	if scene == null:
		# Return stats for all pools
		var total_available := 0
		var total_in_use := 0
		for pool in pools.values():
			total_available += pool["available"].size()
			total_in_use += pool["in_use"].size()
		
		return {
			"pool_count": pools.size(),
			"total_available": total_available,
			"total_in_use": total_in_use,
			"total_objects": total_available + total_in_use
		}
	else:
		var scene_path := scene.resource_path
		if scene_path not in pools:
			return {}
		
		var pool := pools[scene_path]
		return {
			"scene_path": scene_path,
			"available": pool["available"].size(),
			"in_use": pool["in_use"].size(),
			"total": pool["available"].size() + pool["in_use"].size()
		}


# ==============================================================================
# INTERNAL HELPERS
# ==============================================================================

## Prepare a newly created object for pooling
func _prepare_pooled_object(obj: Node) -> void:
	# Add to the ObjectPool node as parent (keeps them organized)
	if obj.get_parent() == null:
		add_child(obj)
	
	# Deactivate initially
	_deactivate_object(obj)


## Deactivate an object when returning to pool
func _deactivate_object(obj: Node) -> void:
	# Remove from current parent (but keep in scene tree under ObjectPool)
	if obj.get_parent() != self and obj.get_parent() != null:
		obj.get_parent().remove_child(obj)
		add_child(obj)
	
	# Hide and disable processing
	obj.visible = false
	obj.process_mode = Node.PROCESS_MODE_DISABLED


## Find which pool an object belongs to
func _get_scene_path_for_object(obj: Node) -> String:
	# Check each pool to see if object is in use
	for scene_path in pools.keys():
		var pool := pools[scene_path]
		if pool["in_use"].has(obj):
			return scene_path
	
	return ""


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	print("[ObjectPool] Initialized")


func _exit_tree() -> void:
	# Clean up all pools on exit
	clear_all_pools()
