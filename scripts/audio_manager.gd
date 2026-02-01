# ==============================================================================
# AUDIO MANAGER - CENTRALIZED SOUND EFFECT MANAGEMENT
# ==============================================================================
#
# FILE: scripts/audio_manager.gd
# PURPOSE: Singleton for playing sound effects throughout the game
#
# FEATURES:
# - Centralized audio playback
# - Sound effect pooling for performance
# - Volume control
# - Spatial and non-spatial audio support
#
# USAGE:
#   AudioManager.play_sfx("airlock_open")
#   AudioManager.play_sfx_at_position("footstep", player.global_position)
#
# ==============================================================================

extends Node

# ==============================================================================
# CONSTANTS
# ==============================================================================

## Path to sound effects directory
const SFX_PATH := "res://assets/audio/sfx/boarding/"

## Sound effect files
const SOUNDS := {
	"airlock_open": "airlock_open.wav",
	"airlock_close": "airlock_close.wav",
	"door_open": "airlock_open.wav",  # Reuse for regular doors
	"door_close": "airlock_close.wav",
	"footstep": "footstep.wav",
	"container_open": "container_open.wav",
	"container_search": "container_search.wav",
	"loot_pickup": "loot_pickup.wav",
	"escape": "escape.wav",
}

## Maximum number of simultaneous audio players per sound
const MAX_PLAYERS_PER_SOUND := 3

# ==============================================================================
# STATE
# ==============================================================================

## Cached audio streams
var _audio_streams := {}

## Pool of available audio players
var _audio_player_pool: Array[AudioStreamPlayer] = []

## Currently active audio players
var _active_players: Array[AudioStreamPlayer] = []

## Master volume (0.0 to 1.0)
var master_volume := 1.0

## SFX volume (0.0 to 1.0)
var sfx_volume := 0.7

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Preload all sound effects
	_load_sounds()
	
	# Create initial player pool
	_create_player_pool(10)


## Load all sound effects into memory
func _load_sounds() -> void:
	for sound_name in SOUNDS:
		var sound_file = SOUNDS[sound_name]
		var sound_path = SFX_PATH + sound_file
		
		if ResourceLoader.exists(sound_path):
			var stream = load(sound_path)
			_audio_streams[sound_name] = stream
		else:
			push_warning("AudioManager: Sound file not found: %s" % sound_path)


## Create a pool of reusable audio players
func _create_player_pool(count: int) -> void:
	for i in range(count):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"  # Connect to SFX bus if it exists
		player.finished.connect(_on_player_finished.bind(player))
		add_child(player)
		_audio_player_pool.append(player)

# ==============================================================================
# PUBLIC API
# ==============================================================================

## Play a sound effect by name
## Returns true if sound was played successfully
func play_sfx(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> bool:
	if not _audio_streams.has(sound_name):
		push_warning("AudioManager: Sound '%s' not found" % sound_name)
		return false
	
	var player = _get_available_player()
	if not player:
		return false
	
	player.stream = _audio_streams[sound_name]
	player.volume_db = volume_db + _get_master_volume_db()
	player.pitch_scale = pitch_scale
	player.play()
	
	_active_players.append(player)
	return true


## Play a sound with random pitch variation for variety
func play_sfx_varied(sound_name: String, pitch_variation: float = 0.1, volume_db: float = 0.0) -> bool:
	var pitch = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	return play_sfx(sound_name, volume_db, pitch)


## Stop all instances of a specific sound
func stop_sfx(sound_name: String) -> void:
	if not _audio_streams.has(sound_name):
		return
	
	var stream = _audio_streams[sound_name]
	for player in _active_players:
		if player.stream == stream:
			player.stop()
			_return_player_to_pool(player)


## Stop all currently playing sounds
func stop_all_sfx() -> void:
	for player in _active_players.duplicate():
		player.stop()
		_return_player_to_pool(player)


## Set master volume (0.0 to 1.0)
func set_master_volume(volume: float) -> void:
	master_volume = clampf(volume, 0.0, 1.0)


## Set SFX volume (0.0 to 1.0)
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clampf(volume, 0.0, 1.0)

# ==============================================================================
# INTERNAL
# ==============================================================================

## Get an available audio player from the pool
func _get_available_player() -> AudioStreamPlayer:
	# Try to get from pool
	if not _audio_player_pool.is_empty():
		return _audio_player_pool.pop_back()
	
	# Pool is empty, try to reuse oldest active player
	if _active_players.size() > 0:
		var oldest = _active_players[0]
		_return_player_to_pool(oldest)
		return _audio_player_pool.pop_back()
	
	# Shouldn't happen, but create new player if needed
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	player.finished.connect(_on_player_finished.bind(player))
	add_child(player)
	return player


## Return a player to the pool when finished
func _return_player_to_pool(player: AudioStreamPlayer) -> void:
	if player in _active_players:
		_active_players.erase(player)
	
	if player not in _audio_player_pool:
		_audio_player_pool.append(player)


## Called when an audio player finishes playing
func _on_player_finished(player: AudioStreamPlayer) -> void:
	_return_player_to_pool(player)


## Convert volume (0-1) to decibels
func _get_master_volume_db() -> float:
	var combined_volume = master_volume * sfx_volume
	if combined_volume <= 0.0:
		return -80.0  # Effective silence
	return linear_to_db(combined_volume)
