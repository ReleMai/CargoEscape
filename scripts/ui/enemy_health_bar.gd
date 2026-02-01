# ==============================================================================
# ENEMY HEALTH BAR
# ==============================================================================
#
# FILE: scripts/ui/enemy_health_bar.gd
# PURPOSE: Displays health bar above damaged enemies
#
# ==============================================================================

extends Control
class_name EnemyHealthBar


# ==============================================================================
# EXPORTS
# ==============================================================================

## How long the health bar stays visible after last damage
@export var fade_delay: float = 2.0

## Fade duration
@export var fade_duration: float = 0.5


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var fill: ColorRect = %Fill


# ==============================================================================
# STATE
# ==============================================================================

var max_health: float = 100.0
var current_health: float = 100.0
var fade_timer: float = 0.0
var is_fading: bool = false
var tween: Tween


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Start hidden
	visible = false
	modulate.a = 1.0


func _process(delta: float) -> void:
	if visible and not is_fading:
		fade_timer += delta
		if fade_timer >= fade_delay:
			_start_fade()


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

## Initialize with max health
func setup(health: float) -> void:
	max_health = health
	current_health = health
	_update_bar()


## Update health display
func update_health(health: float) -> void:
	current_health = health
	_update_bar()
	
	# Show when damaged
	if current_health < max_health:
		_show_bar()


## Update color based on health percentage
func _update_bar() -> void:
	if not fill:
		return
	
	var percent = current_health / max_health if max_health > 0 else 0.0
	
	# Scale the fill width
	fill.anchor_right = clampf(percent, 0.0, 1.0)
	
	# Color based on health (green -> yellow -> red)
	if percent > 0.6:
		fill.color = Color(0.2, 0.8, 0.2)  # Green
	elif percent > 0.3:
		fill.color = Color(0.9, 0.7, 0.1)  # Yellow
	else:
		fill.color = Color(0.8, 0.2, 0.2)  # Red


## Show the health bar
func _show_bar() -> void:
	# Cancel any fade
	if tween and tween.is_valid():
		tween.kill()
	is_fading = false
	
	visible = true
	modulate.a = 1.0
	fade_timer = 0.0


## Start fading out
func _start_fade() -> void:
	if is_fading:
		return
	
	is_fading = true
	
	if tween and tween.is_valid():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_callback(func(): visible = false; is_fading = false)
