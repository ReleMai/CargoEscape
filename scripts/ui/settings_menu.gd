# ==============================================================================
# SETTINGS MENU
# ==============================================================================
#
# FILE: scripts/ui/settings_menu.gd
# PURPOSE: Settings submenu for audio, controls, and display options
#
# ==============================================================================

extends Control
class_name SettingsMenu

# ==============================================================================
# SIGNALS
# ==============================================================================

signal back_requested

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var master_volume_slider: HSlider = $Panel/MarginContainer/VBoxContainer/AudioSettings/MasterVolume/MasterSlider
@onready var master_volume_label: Label = $Panel/MarginContainer/VBoxContainer/AudioSettings/MasterVolume/ValueLabel
@onready var sfx_volume_slider: HSlider = $Panel/MarginContainer/VBoxContainer/AudioSettings/SFXVolume/SFXSlider
@onready var sfx_volume_label: Label = $Panel/MarginContainer/VBoxContainer/AudioSettings/SFXVolume/ValueLabel
@onready var music_volume_slider: HSlider = $Panel/MarginContainer/VBoxContainer/AudioSettings/MusicVolume/MusicSlider
@onready var music_volume_label: Label = $Panel/MarginContainer/VBoxContainer/AudioSettings/MusicVolume/ValueLabel
@onready var ambient_volume_slider: HSlider = $Panel/MarginContainer/VBoxContainer/AudioSettings/AmbientVolume/AmbientSlider
@onready var ambient_volume_label: Label = $Panel/MarginContainer/VBoxContainer/AudioSettings/AmbientVolume/ValueLabel
@onready var fullscreen_toggle: CheckButton = $Panel/MarginContainer/VBoxContainer/DisplaySettings/FullscreenToggle
@onready var back_button: Button = $Panel/MarginContainer/VBoxContainer/BackButton

# ==============================================================================
# SETTINGS DATA
# ==============================================================================

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var ambient_volume: float = 1.0
var is_fullscreen: bool = false

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_load_settings()
	_connect_signals()
	_update_ui()
	hide()
	
	# Make sure the settings menu processes even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS


func _connect_signals() -> void:
	if master_volume_slider:
		master_volume_slider.value_changed.connect(_on_master_volume_changed)
	if sfx_volume_slider:
		sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if music_volume_slider:
		music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if ambient_volume_slider:
		ambient_volume_slider.value_changed.connect(_on_ambient_volume_changed)
	if fullscreen_toggle:
		fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	if back_button:
		back_button.pressed.connect(_on_back_pressed)


# ==============================================================================
# SETTINGS MANAGEMENT
# ==============================================================================

func _load_settings() -> void:
	# Load from config file or use defaults
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 1.0)
		ambient_volume = config.get_value("audio", "ambient_volume", 1.0)
		is_fullscreen = config.get_value("display", "fullscreen", false)
	else:
		# Use defaults
		master_volume = 1.0
		sfx_volume = 1.0
		music_volume = 1.0
		ambient_volume = 1.0
		is_fullscreen = false
	
	# Apply settings
	_apply_audio_settings()
	_apply_display_settings()


func _save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "ambient_volume", ambient_volume)
	config.set_value("display", "fullscreen", is_fullscreen)
	
	config.save("user://settings.cfg")


func _apply_audio_settings() -> void:
	# Set audio bus volumes (Godot uses decibels)
	# Clamp minimum volume to avoid -inf from linear_to_db(0.0)
	var master_vol = maxf(master_volume, 0.0001)
	var sfx_vol = maxf(sfx_volume, 0.0001)
	var music_vol = maxf(music_volume, 0.0001)
	var ambient_vol = maxf(ambient_volume, 0.0001)
	
	var master_db = linear_to_db(master_vol)
	var sfx_db = linear_to_db(sfx_vol)
	var music_db = linear_to_db(music_vol)
	var ambient_db = linear_to_db(ambient_vol)
	
	# Debug: Print available buses
	print("[Settings] Applying audio - Master: %.0f%%, SFX: %.0f%%, Music: %.0f%%, Ambient: %.0f%%" % [master_volume * 100, sfx_volume * 100, music_volume * 100, ambient_volume * 100])
	print("[Settings] Available buses: ", _get_bus_names())
	
	# Apply to audio buses if they exist
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, master_db)
		AudioServer.set_bus_mute(master_idx, master_volume < 0.01)
		print("[Settings] Master bus set to %.1f dB" % master_db)
	
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, sfx_db)
		AudioServer.set_bus_mute(sfx_idx, sfx_volume < 0.01)
		print("[Settings] SFX bus set to %.1f dB" % sfx_db)
	else:
		push_warning("[Settings] SFX bus not found!")
	
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, music_db)
		AudioServer.set_bus_mute(music_idx, music_volume < 0.01)
		print("[Settings] Music bus set to %.1f dB" % music_db)
	else:
		push_warning("[Settings] Music bus not found!")
	
	var ambient_idx = AudioServer.get_bus_index("Ambient")
	if ambient_idx >= 0:
		AudioServer.set_bus_volume_db(ambient_idx, ambient_db)
		AudioServer.set_bus_mute(ambient_idx, ambient_volume < 0.01)
		print("[Settings] Ambient bus set to %.1f dB" % ambient_db)
	else:
		push_warning("[Settings] Ambient bus not found!")


func _get_bus_names() -> Array:
	var names = []
	for i in range(AudioServer.bus_count):
		names.append(AudioServer.get_bus_name(i))
	return names


func _apply_display_settings() -> void:
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _update_ui() -> void:
	if master_volume_slider:
		master_volume_slider.value = master_volume
	if sfx_volume_slider:
		sfx_volume_slider.value = sfx_volume
	if music_volume_slider:
		music_volume_slider.value = music_volume
	if ambient_volume_slider:
		ambient_volume_slider.value = ambient_volume
	if fullscreen_toggle:
		fullscreen_toggle.button_pressed = is_fullscreen
	
	_update_volume_labels()


func _update_volume_labels() -> void:
	if master_volume_label:
		master_volume_label.text = str(int(master_volume * 100)) + "%"
	if sfx_volume_label:
		sfx_volume_label.text = str(int(sfx_volume * 100)) + "%"
	if music_volume_label:
		music_volume_label.text = str(int(music_volume * 100)) + "%"
	if ambient_volume_label:
		ambient_volume_label.text = str(int(ambient_volume * 100)) + "%"


# ==============================================================================
# UI HANDLERS
# ==============================================================================

func _on_master_volume_changed(value: float) -> void:
	master_volume = value
	_apply_audio_settings()
	_update_volume_labels()
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	sfx_volume = value
	_apply_audio_settings()
	_update_volume_labels()
	_save_settings()


func _on_music_volume_changed(value: float) -> void:
	music_volume = value
	_apply_audio_settings()
	_update_volume_labels()
	_save_settings()


func _on_ambient_volume_changed(value: float) -> void:
	ambient_volume = value
	_apply_audio_settings()
	_update_volume_labels()
	_save_settings()


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	is_fullscreen = toggled_on
	_apply_display_settings()
	_save_settings()


func _on_back_pressed() -> void:
	hide()
	back_requested.emit()


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func show_settings() -> void:
	show()
	if back_button:
		back_button.grab_focus()
