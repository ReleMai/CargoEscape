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
@onready var fullscreen_toggle: CheckButton = $Panel/MarginContainer/VBoxContainer/DisplaySettings/FullscreenToggle
@onready var back_button: Button = $Panel/MarginContainer/VBoxContainer/BackButton

# ==============================================================================
# SETTINGS DATA
# ==============================================================================

var master_volume: float = 1.0
var sfx_volume: float = 1.0
var music_volume: float = 1.0
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
		is_fullscreen = config.get_value("display", "fullscreen", false)
	else:
		# Use defaults
		master_volume = 1.0
		sfx_volume = 1.0
		music_volume = 1.0
		is_fullscreen = false
	
	# Apply settings
	_apply_audio_settings()
	_apply_display_settings()


func _save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("display", "fullscreen", is_fullscreen)
	
	config.save("user://settings.cfg")


func _apply_audio_settings() -> void:
	# Set audio bus volumes (Godot uses decibels)
	var master_db = linear_to_db(master_volume)
	var sfx_db = linear_to_db(sfx_volume)
	var music_db = linear_to_db(music_volume)
	
	# Apply to audio buses if they exist
	if AudioServer.get_bus_index("Master") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), master_db)
	
	# You can add SFX and Music buses in the Audio settings
	if AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfx_db)
	
	if AudioServer.get_bus_index("Music") >= 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), music_db)


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
