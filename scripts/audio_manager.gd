# ==============================================================================
# AUDIO MANAGER - COMPREHENSIVE SOUND MANAGEMENT
# ==============================================================================
#
# FILE: scripts/audio_manager.gd
# PURPOSE: Singleton for all audio - SFX, music, ambient, and voice
#
# FEATURES:
# - Audio spam prevention (cooldowns per sound)
# - Music system with crossfading
# - Ambient sound layers
# - Spatial and non-spatial audio
# - Volume categories (Master, Music, SFX, Ambient, Voice)
#
# ==============================================================================

extends Node


# ==============================================================================
# CONSTANTS
# ==============================================================================

const SFX_PATH := "res://assets/audio/sfx/"
const MUSIC_PATH := "res://assets/audio/music/"
const AMBIENT_PATH := "res://assets/audio/ambient/"
const VOICE_PATH := "res://assets/audio/voice/"

## Default cooldown between same sound plays (prevents spam)
const DEFAULT_SOUND_COOLDOWN := 0.08

## Music crossfade duration
const MUSIC_CROSSFADE_TIME := 2.0

## Maximum simultaneous sounds per category
const MAX_SFX_PLAYERS := 16
const MAX_AMBIENT_PLAYERS := 4
const MAX_VOICE_PLAYERS := 3


# ==============================================================================
# SOUND DEFINITIONS
# ==============================================================================

## All sound effects with paths and settings
const SOUNDS := {
	# === BOARDING SOUNDS ===
	"airlock_open": {"file": "boarding/airlock_open.wav", "cooldown": 0.3},
	"airlock_close": {"file": "boarding/airlock_close.wav", "cooldown": 0.3},
	"door_open": {"file": "boarding/door_open.wav", "cooldown": 0.15},
	"door_close": {"file": "boarding/door_close.wav", "cooldown": 0.15},
	"footstep": {"file": "boarding/footstep.wav", "cooldown": 0.18},
	"container_open": {"file": "boarding/container_open.wav", "cooldown": 0.2},
	"container_search": {"file": "boarding/container_search.wav", "cooldown": 3.0},
	"loot_pickup": {"file": "boarding/loot_pickup.wav", "cooldown": 0.05},
	"escape": {"file": "boarding/escape.wav", "cooldown": 1.0},
	
	# === LOOT RARITY SOUNDS ===
	"loot_common": {"file": "loot/loot_common.wav", "cooldown": 0.1},
	"loot_uncommon": {"file": "loot/loot_uncommon.wav", "cooldown": 0.1},
	"loot_rare": {"file": "loot/loot_rare.wav", "cooldown": 0.1},
	"loot_epic": {"file": "loot/loot_epic.wav", "cooldown": 0.2},
	"loot_legendary": {"file": "loot/loot_legendary.wav", "cooldown": 0.5},
	
	# === UI SOUNDS ===
	"ui_click": {"file": "ui/ui_click.wav", "cooldown": 0.05},
	"ui_hover": {"file": "ui/ui_hover.wav", "cooldown": 0.03},
	"ui_confirm": {"file": "ui/ui_confirm.wav", "cooldown": 0.1},
	"ui_cancel": {"file": "ui/ui_cancel.wav", "cooldown": 0.1},
	"ui_deny": {"file": "ui/ui_deny.wav", "cooldown": 0.15},
	"ui_open": {"file": "ui/ui_open.wav", "cooldown": 0.1},
	"ui_close": {"file": "ui/ui_close.wav", "cooldown": 0.1},
	"ui_tab": {"file": "ui/ui_tab.wav", "cooldown": 0.08},
	"ui_scroll": {"file": "ui/ui_scroll.wav", "cooldown": 0.02},
	"ui_notification": {"file": "ui/ui_notification.wav", "cooldown": 0.3},
	
	# === SPACE FLIGHT SOUNDS ===
	"engine_idle": {"file": "ship/engine_idle.wav", "cooldown": 0.5},
	"engine_thrust": {"file": "ship/engine_thrust.wav", "cooldown": 0.2},
	"engine_boost": {"file": "ship/engine_boost.wav", "cooldown": 0.3},
	"ship_damage": {"file": "ship/ship_damage.wav", "cooldown": 0.1},
	"shield_hit": {"file": "ship/shield_hit.wav", "cooldown": 0.08},
	"shield_down": {"file": "ship/shield_down.wav", "cooldown": 0.5},
	"shield_recharge": {"file": "ship/shield_recharge.wav", "cooldown": 0.3},
	
	# === WEAPON SOUNDS ===
	"laser_fire": {"file": "weapons/laser_fire.wav", "cooldown": 0.05},
	"laser_hit": {"file": "weapons/laser_hit.wav", "cooldown": 0.03},
	"missile_launch": {"file": "weapons/missile_launch.wav", "cooldown": 0.2},
	"missile_explode": {"file": "weapons/missile_explode.wav", "cooldown": 0.1},
	"railgun_charge": {"file": "weapons/railgun_charge.wav", "cooldown": 0.3},
	"railgun_fire": {"file": "weapons/railgun_fire.wav", "cooldown": 0.3},
	
	# === EXPLOSION SOUNDS ===
	"explosion_small": {"file": "explosions/explosion_small.wav", "cooldown": 0.08},
	"explosion_medium": {"file": "explosions/explosion_medium.wav", "cooldown": 0.1},
	"explosion_large": {"file": "explosions/explosion_large.wav", "cooldown": 0.15},
	"ship_explode": {"file": "explosions/ship_explode.wav", "cooldown": 0.3},
	
	# === DOCKING SOUNDS ===
	"dock_approach": {"file": "docking/dock_approach.wav", "cooldown": 1.0},
	"dock_clamp": {"file": "docking/dock_clamp.wav", "cooldown": 0.5},
	"dock_seal": {"file": "docking/dock_seal.wav", "cooldown": 0.5},
	"undock": {"file": "docking/undock.wav", "cooldown": 0.5},
	
	# === ALERT/WARNING SOUNDS ===
	"alert_warning": {"file": "alerts/alert_warning.wav", "cooldown": 0.5},
	"alert_critical": {"file": "alerts/alert_critical.wav", "cooldown": 0.3},
	"alert_timer": {"file": "alerts/alert_timer.wav", "cooldown": 1.0},
	"countdown_beep": {"file": "alerts/countdown_beep.wav", "cooldown": 0.8},
	"countdown_final": {"file": "alerts/countdown_final.wav", "cooldown": 0.5},
	
	# === ACHIEVEMENT SOUNDS ===
	"achievement_unlock": {"file": "achievements/achievement_unlock.wav", "cooldown": 1.0},
	"level_up": {"file": "achievements/level_up.wav", "cooldown": 1.0},
	"money_gain": {"file": "achievements/money_gain.wav", "cooldown": 0.1},
}

## Music tracks
const MUSIC_TRACKS := {
	# Main menu and menus
	"main_menu": "menu/main_theme.wav",
	"pause_menu": "menu/pause_ambient.wav",
	
	# Gameplay music
	"space_exploration": "gameplay/space_exploration.wav",
	"combat_light": "gameplay/combat_light.wav",
	"combat_intense": "gameplay/combat_intense.wav",
	"boarding_tension": "gameplay/boarding_tension.wav",
	"boarding_escape": "gameplay/boarding_escape.wav",
	
	# Cutscene/story music
	"intro_cinematic": "cutscenes/intro_cinematic.wav",
	"victory": "cutscenes/victory.wav",
	"defeat": "cutscenes/defeat.wav",
	
	# Ambient tracks (can layer)
	"station_ambient": "ambient/station_ambient.wav",
	"ship_interior": "ambient/ship_interior.wav",
}

## Ambient sound layers
const AMBIENT_SOUNDS := {
	"space_hum": {"file": "space_hum.wav", "volume": -12.0},
	"ship_ambience": {"file": "ship_ambience.wav", "volume": -10.0},
	"station_bustle": {"file": "station_bustle.wav", "volume": -8.0},
	"engine_rumble": {"file": "engine_rumble.wav", "volume": -15.0},
	"ventilation": {"file": "ventilation.wav", "volume": -18.0},
	"computer_hum": {"file": "computer_hum.wav", "volume": -20.0},
	"radio_static": {"file": "radio_static.wav", "volume": -25.0},
}


# ==============================================================================
# VOLUME SETTINGS
# ==============================================================================

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var ambient_volume: float = 0.6
var voice_volume: float = 1.0

## Enable debug logging for all audio (set to true to see what's playing)
var _debug_audio: bool = true


# ==============================================================================
# STATE
# ==============================================================================

## Cached audio streams
var _sfx_streams: Dictionary = {}
var _music_streams: Dictionary = {}
var _ambient_streams: Dictionary = {}

## Last play time for each sound (spam prevention)
var _last_play_times: Dictionary = {}

## Audio player pools
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_active: Array[AudioStreamPlayer] = []

## Music players (2 for crossfading)
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _current_music_player: AudioStreamPlayer
var _current_music_track: String = ""

## Ambient players
var _ambient_players: Dictionary = {}  # name -> AudioStreamPlayer

## Voice player
var _voice_player: AudioStreamPlayer


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_setup_music_players()
	_setup_voice_player()
	_create_sfx_pool(MAX_SFX_PLAYERS)
	_preload_sounds()
	_load_and_apply_audio_settings()


## Load and apply saved audio settings on startup
func _load_and_apply_audio_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		var master_vol = config.get_value("audio", "master_volume", 1.0)
		var sfx_vol = config.get_value("audio", "sfx_volume", 1.0)
		var music_vol = config.get_value("audio", "music_volume", 1.0)
		var ambient_vol = config.get_value("audio", "ambient_volume", 1.0)
		
		# Apply to audio buses
		_apply_volume_to_bus("Master", master_vol)
		_apply_volume_to_bus("SFX", sfx_vol)
		_apply_volume_to_bus("Music", music_vol)
		_apply_volume_to_bus("Ambient", ambient_vol)
		
		if _debug_audio:
			print("[AUDIO] Loaded saved settings - Master: %.0f%%, SFX: %.0f%%, Music: %.0f%%, Ambient: %.0f%%" % [
				master_vol * 100, sfx_vol * 100, music_vol * 100, ambient_vol * 100])
	else:
		if _debug_audio:
			print("[AUDIO] No saved settings found, using defaults")


## Apply a volume level to an audio bus
func _apply_volume_to_bus(bus_name: String, volume: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		var vol = maxf(volume, 0.0001)  # Avoid -inf
		var db = linear_to_db(vol)
		AudioServer.set_bus_volume_db(bus_idx, db)
		AudioServer.set_bus_mute(bus_idx, volume < 0.01)


func _setup_music_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.bus = "Music"
	add_child(_music_player_a)
	
	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = "Music"
	add_child(_music_player_b)
	
	_current_music_player = _music_player_a


func _setup_voice_player() -> void:
	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = "Voice"
	add_child(_voice_player)


func _create_sfx_pool(count: int) -> void:
	for i in range(count):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.finished.connect(_on_sfx_finished.bind(player))
		add_child(player)
		_sfx_pool.append(player)


func _preload_sounds() -> void:
	# Preload SFX
	for sound_name in SOUNDS:
		var sound_data = SOUNDS[sound_name]
		var path = SFX_PATH + sound_data.file
		if ResourceLoader.exists(path):
			_sfx_streams[sound_name] = load(path)
	
	# Preload music (lazy load - just check existence)
	for track_name in MUSIC_TRACKS:
		var path = MUSIC_PATH + MUSIC_TRACKS[track_name]
		if ResourceLoader.exists(path):
			_music_streams[track_name] = path  # Store path, load on demand
	
	# Preload ambient
	for amb_name in AMBIENT_SOUNDS:
		var amb_data = AMBIENT_SOUNDS[amb_name]
		var path = AMBIENT_PATH + amb_data.file
		if ResourceLoader.exists(path):
			_ambient_streams[amb_name] = load(path)


# ==============================================================================
# SFX PLAYBACK
# ==============================================================================

## Play a sound effect with spam prevention
func play_sfx(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> bool:
	# Check if sound exists
	if not _sfx_streams.has(sound_name):
		if _debug_audio:
			print("[AUDIO] SFX missing: %s" % sound_name)
		return false
	
	# Check cooldown (spam prevention)
	var sound_data = SOUNDS.get(sound_name, {"cooldown": DEFAULT_SOUND_COOLDOWN})
	var cooldown = sound_data.get("cooldown", DEFAULT_SOUND_COOLDOWN)
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if _last_play_times.has(sound_name):
		var elapsed = current_time - _last_play_times[sound_name]
		if elapsed < cooldown:
			if _debug_audio:
				print("[AUDIO] SFX cooldown: %s (%.2fs)" % [sound_name, cooldown - elapsed])
			return false  # Still in cooldown
	
	# Get available player
	var player = _get_sfx_player()
	if not player:
		if _debug_audio:
			print("[AUDIO] SFX no player: %s" % sound_name)
		return false
	
	# Play the sound
	player.stream = _sfx_streams[sound_name]
	player.volume_db = volume_db + _get_sfx_volume_db()
	player.pitch_scale = pitch
	player.play()
	
	_sfx_active.append(player)
	_last_play_times[sound_name] = current_time
	
	if _debug_audio:
		print("[AUDIO] SFX play: %s (vol=%.1f, pitch=%.2f)" % [sound_name, volume_db, pitch])
	return true


## Play SFX with random pitch variation
func play_sfx_varied(sound_name: String, variation: float = 0.1, vol_db: float = 0.0) -> bool:
	var pitch = randf_range(1.0 - variation, 1.0 + variation)
	return play_sfx(sound_name, vol_db, pitch)


## Play loot pickup sound based on rarity
func play_loot_sound(rarity: int) -> void:
	match rarity:
		0: play_sfx("loot_common", -3.0)
		1: play_sfx("loot_uncommon", -2.0)
		2: play_sfx("loot_rare", 0.0)
		3: play_sfx("loot_epic", 2.0)
		4: play_sfx("loot_legendary", 4.0)
		_: play_sfx("loot_pickup", 0.0)


## Stop all SFX
func stop_all_sfx() -> void:
	for player in _sfx_active.duplicate():
		player.stop()
		_return_sfx_to_pool(player)


func _get_sfx_player() -> AudioStreamPlayer:
	if not _sfx_pool.is_empty():
		return _sfx_pool.pop_back()
	
	# Steal oldest if pool empty
	if not _sfx_active.is_empty():
		var oldest = _sfx_active[0]
		_return_sfx_to_pool(oldest)
		return _sfx_pool.pop_back()
	
	return null


func _return_sfx_to_pool(player: AudioStreamPlayer) -> void:
	player.stop()
	if player in _sfx_active:
		_sfx_active.erase(player)
	if player not in _sfx_pool:
		_sfx_pool.append(player)


func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	_return_sfx_to_pool(player)


# ==============================================================================
# MUSIC PLAYBACK
# ==============================================================================

## Play music track with optional crossfade
func play_music(track_name: String, crossfade: bool = true) -> void:
	if track_name == _current_music_track:
		if _debug_audio:
			print("[AUDIO] Music already playing: %s" % track_name)
		return  # Already playing
	
	if not _music_streams.has(track_name):
		if _debug_audio:
			print("[AUDIO] Music missing: %s" % track_name)
		push_warning("AudioManager: Music track '%s' not found" % track_name)
		return
	
	if _debug_audio:
		print("[AUDIO] Music play: %s (crossfade=%s)" % [track_name, crossfade])
	
	var path = _music_streams[track_name]
	var stream = load(path) if path is String else path
	
	if crossfade and _current_music_player.playing:
		_crossfade_to(stream, track_name)
	else:
		_current_music_player.stream = stream
		_current_music_player.volume_db = _get_music_volume_db()
		_current_music_player.play()
		_current_music_track = track_name


## Stop music with optional fade out
func stop_music(fade_out: bool = true) -> void:
	if fade_out:
		var tween = create_tween()
		tween.tween_property(_current_music_player, "volume_db", -40.0, 1.0)
		tween.tween_callback(_current_music_player.stop)
	else:
		_current_music_player.stop()
	_current_music_track = ""


func _crossfade_to(stream: AudioStream, track_name: String) -> void:
	var old_player = _current_music_player
	var new_player = _music_player_b if old_player == _music_player_a else _music_player_a
	
	new_player.stream = stream
	new_player.volume_db = -40.0
	new_player.play()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(old_player, "volume_db", -40.0, MUSIC_CROSSFADE_TIME)
	tween.tween_property(new_player, "volume_db", _get_music_volume_db(), MUSIC_CROSSFADE_TIME)
	tween.set_parallel(false)
	tween.tween_callback(old_player.stop)
	
	_current_music_player = new_player
	_current_music_track = track_name


# ==============================================================================
# AMBIENT SOUNDS
# ==============================================================================

## Start an ambient sound layer
func start_ambient(ambient_name: String) -> void:
	if _ambient_players.has(ambient_name):
		if _debug_audio:
			print("[AUDIO] Ambient already playing: %s" % ambient_name)
		return  # Already playing
	
	if not _ambient_streams.has(ambient_name):
		if _debug_audio:
			print("[AUDIO] Ambient missing: %s" % ambient_name)
		return
	
	if _debug_audio:
		print("[AUDIO] Ambient start: %s" % ambient_name)
	
	var player = AudioStreamPlayer.new()
	player.bus = "Ambient"
	player.stream = _ambient_streams[ambient_name]
	player.volume_db = AMBIENT_SOUNDS[ambient_name].volume + _get_ambient_volume_db()
	add_child(player)
	
	# Set up looping - try multiple approaches for different stream types
	var stream = player.stream
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		stream.loop = true
	else:
		# For compressed streams (QOA), connect to finished signal to restart
		# This ensures seamless looping even when stream doesn't support loop property
		player.finished.connect(func():
			if is_instance_valid(player) and _ambient_players.has(ambient_name):
				player.play()
		)
	
	player.play()
	_ambient_players[ambient_name] = player


## Stop an ambient sound layer
func stop_ambient(ambient_name: String, fade: bool = true) -> void:
	if not _ambient_players.has(ambient_name):
		return
	
	if _debug_audio:
		print("[AUDIO] Ambient stop: %s (fade=%s)" % [ambient_name, fade])
	
	var player = _ambient_players[ambient_name]
	_ambient_players.erase(ambient_name)
	
	if fade:
		var tween = create_tween()
		tween.tween_property(player, "volume_db", -40.0, 1.0)
		tween.tween_callback(player.queue_free)
	else:
		player.queue_free()


## Stop all ambient sounds
func stop_all_ambient() -> void:
	if _debug_audio:
		print("[AUDIO] Stopping all ambient sounds")
	for amb_name in _ambient_players.keys():
		stop_ambient(amb_name, false)


# ==============================================================================
# VOICE/RADIO
# ==============================================================================

## Play a voice line
func play_voice(voice_name: String) -> void:
	var path = VOICE_PATH + voice_name
	if not ResourceLoader.exists(path):
		return
	
	_voice_player.stream = load(path)
	_voice_player.volume_db = _get_voice_volume_db()
	_voice_player.play()


## Stop voice
func stop_voice() -> void:
	_voice_player.stop()


# ==============================================================================
# VOLUME CONTROL
# ==============================================================================

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	_update_all_volumes()


func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	_current_music_player.volume_db = _get_music_volume_db()


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)


func set_ambient_volume(vol: float) -> void:
	ambient_volume = clampf(vol, 0.0, 1.0)
	for player in _ambient_players.values():
		player.volume_db = _get_ambient_volume_db()


func set_voice_volume(vol: float) -> void:
	voice_volume = clampf(vol, 0.0, 1.0)


func _get_sfx_volume_db() -> float:
	var vol = master_volume * sfx_volume
	return linear_to_db(vol) if vol > 0 else -80.0


func _get_music_volume_db() -> float:
	var vol = master_volume * music_volume
	return linear_to_db(vol) if vol > 0 else -80.0


func _get_ambient_volume_db() -> float:
	var vol = master_volume * ambient_volume
	return linear_to_db(vol) if vol > 0 else -80.0


func _get_voice_volume_db() -> float:
	var vol = master_volume * voice_volume
	return linear_to_db(vol) if vol > 0 else -80.0


func _update_all_volumes() -> void:
	_current_music_player.volume_db = _get_music_volume_db()
	for player in _ambient_players.values():
		player.volume_db = _get_ambient_volume_db()


# ==============================================================================
# SCENE HELPERS
# ==============================================================================

## Set up audio for main menu
func setup_main_menu_audio() -> void:
	stop_all_ambient()
	play_music("main_menu")


## Set up audio for space flight
func setup_space_audio() -> void:
	play_music("space_exploration")
	start_ambient("space_hum")
	start_ambient("engine_rumble")


## Set up audio for boarding
func setup_boarding_audio() -> void:
	play_music("boarding_tension")
	stop_ambient("space_hum")
	stop_ambient("engine_rumble")
	start_ambient("ship_ambience")
	start_ambient("ventilation")


## Set up audio for combat
func setup_combat_audio(intense: bool = false) -> void:
	if intense:
		play_music("combat_intense")
	else:
		play_music("combat_light")


## Set up audio for station/hideout
func setup_station_audio() -> void:
	play_music("station_ambient")
	stop_all_ambient()
	start_ambient("station_bustle")
