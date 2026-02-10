# ==============================================================================
# ITEM VISUALS - CLEAN ICON-ONLY ITEM RENDERER
# ==============================================================================
#
# FILE: scripts/loot/item_visuals.gd
# PURPOSE: Creates clean item icons without backgrounds
#
# Items are rendered as:
# - Icon only (no background box)
# - Sized to match grid dimensions
# - Rarity shown via subtle glow/border on the icon itself
#
# ==============================================================================

extends RefCounted
class_name ItemVisuals

# ==============================================================================
# ITEM CATEGORIES
# ==============================================================================

enum ItemCategory {
	SCRAP,      # Irregular, metallic
	TECH,       # Rectangular, circuitry
	MEDICAL,    # Cross/plus shape
	WEAPON,     # Angular, aggressive
	CARGO,      # Box/crate
	ARTIFACT,   # Gem/crystal
	DATA,       # Chip/card
	POWER       # Cylinder/cell
}

# ==============================================================================
# COLOR PALETTES
# ==============================================================================

const CATEGORY_COLORS = {
	ItemCategory.SCRAP: Color(0.6, 0.5, 0.4),
	ItemCategory.TECH: Color(0.3, 0.6, 0.7),
	ItemCategory.MEDICAL: Color(0.9, 0.3, 0.3),
	ItemCategory.WEAPON: Color(0.5, 0.5, 0.6),
	ItemCategory.CARGO: Color(0.7, 0.55, 0.35),
	ItemCategory.ARTIFACT: Color(0.7, 0.4, 0.9),
	ItemCategory.DATA: Color(0.3, 0.8, 0.5),
	ItemCategory.POWER: Color(1.0, 0.8, 0.2),
}

const RARITY_COLORS = {
	0: Color(0.6, 0.6, 0.6),      # Common - Gray
	1: Color(0.4, 0.9, 0.4),      # Uncommon - Green
	2: Color(0.4, 0.6, 1.0),      # Rare - Blue
	3: Color(0.8, 0.4, 1.0),      # Epic - Purple
	4: Color(1.0, 0.85, 0.3),     # Legendary - Gold
}

# ==============================================================================
# ITEM NAME TO CATEGORY MAPPING
# ==============================================================================

static func get_category_for_item(item_name: String) -> ItemCategory:
	var name_lower = item_name.to_lower()
	
	if "scrap" in name_lower or "bolt" in name_lower or "wire" in name_lower or "debris" in name_lower:
		return ItemCategory.SCRAP
	if "circuit" in name_lower or "computer" in name_lower or "cpu" in name_lower or "module" in name_lower or "nav" in name_lower:
		return ItemCategory.TECH
	if "medical" in name_lower or "med" in name_lower or "health" in name_lower:
		return ItemCategory.MEDICAL
	if "weapon" in name_lower or "core" in name_lower or "stealth" in name_lower or "shield" in name_lower:
		return ItemCategory.WEAPON
	if "data" in name_lower or "chip" in name_lower:
		return ItemCategory.DATA
	if "power" in name_lower or "cell" in name_lower or "fuel" in name_lower or "plasma" in name_lower or "coil" in name_lower:
		return ItemCategory.POWER
	if "artifact" in name_lower or "relic" in name_lower or "ancient" in name_lower or "alien" in name_lower or "dark matter" in name_lower or "quantum" in name_lower:
		return ItemCategory.ARTIFACT
	
	return ItemCategory.CARGO


# ==============================================================================
# CREATE ITEM VISUAL - NO BACKGROUND, ICON ONLY
# ==============================================================================

static func create_item_visual(item_data: ItemData, cell_size: int = 64) -> Control:
	var category = get_category_for_item(item_data.name)
	var base_color = CATEGORY_COLORS[category]
	var rarity_color = RARITY_COLORS.get(item_data.rarity, RARITY_COLORS[0])
	
	var width = item_data.grid_width * cell_size
	var height = item_data.grid_height * cell_size
	
	# Create transparent container - NO BACKGROUND
	var container = Control.new()
	container.custom_minimum_size = Vector2(width, height)
	container.size = Vector2(width, height)
	
	# Check if item has a custom sprite
	if item_data.sprite != null:
		_add_sprite_icon(container, item_data.sprite, width, height, rarity_color, item_data.rarity)
	else:
		# Create procedural icon
		_add_procedural_icon(container, category, width, height, base_color, rarity_color, item_data.rarity)
	
	# Add rarity-specific visual effects
	_add_rarity_effects(container, width, height, rarity_color, item_data.rarity)
	
	return container


## Add sprite-based icon (no background)
static func _add_sprite_icon(container: Control, sprite: Texture2D, width: float, height: float, _rarity_color: Color, _rarity: int) -> void:
	# Icon takes up most of the cell with small padding
	var padding = 4.0
	
	var tex_rect = TextureRect.new()
	tex_rect.texture = sprite
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.position = Vector2(padding, padding)
	tex_rect.size = Vector2(width - padding * 2, height - padding * 2)
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(tex_rect)


## Create procedural icon based on category
static func _add_procedural_icon(container: Control, category: ItemCategory, width: float, height: float, base_color: Color, _rarity_color: Color, _rarity: int) -> void:
	var padding = 6.0
	var icon_w = width - padding * 2
	var icon_h = height - padding * 2
	
	match category:
		ItemCategory.SCRAP:
			_draw_scrap_icon(container, padding, icon_w, icon_h, base_color)
		ItemCategory.TECH:
			_draw_tech_icon(container, padding, icon_w, icon_h, base_color)
		ItemCategory.MEDICAL:
			_draw_medical_icon(container, padding, icon_w, icon_h)
		ItemCategory.WEAPON:
			_draw_weapon_icon(container, padding, icon_w, icon_h, base_color)
		ItemCategory.DATA:
			_draw_data_icon(container, padding, icon_w, icon_h, base_color)
		ItemCategory.POWER:
			_draw_power_icon(container, padding, icon_w, icon_h, base_color)
		ItemCategory.ARTIFACT:
			_draw_artifact_icon(container, padding, icon_w, icon_h, base_color)
		ItemCategory.CARGO:
			_draw_cargo_icon(container, padding, icon_w, icon_h, base_color)


## Add rarity-specific visual effects based on tier
## Common (0): No effect
## Uncommon (1): Subtle glow
## Rare (2): Blue shimmer effect
## Epic (3): Purple pulsing glow
## Legendary (4): Gold particle effect with shine
static func _add_rarity_effects(container: Control, width: float, height: float, color: Color, rarity: int) -> void:
	match rarity:
		0:
			# Common - no effect
			pass
		1:
			# Uncommon - subtle glow shader
			_add_uncommon_glow(container, width, height, color)
		2:
			# Rare - blue shimmer shader
			_add_rare_shimmer(container, width, height, color)
		3:
			# Epic - purple pulsing glow with AnimationPlayer
			_add_epic_pulse(container, width, height, color)
		4:
			# Legendary - gold particle effect with shine
			_add_legendary_particles(container, width, height, color)


## Subtle glow effect for uncommon items
static func _add_uncommon_glow(container: Control, width: float, height: float, color: Color) -> void:
	var glow_rect = ColorRect.new()
	glow_rect.size = Vector2(width, height)
	glow_rect.color = Color.WHITE
	glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Load and apply glow shader
	var shader = load("res://resources/shaders/glow_effect.gdshader")
	if shader:
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("glow_color", color)
		material.set_shader_parameter("glow_intensity", 0.4)
		material.set_shader_parameter("glow_speed", 1.0)
		glow_rect.material = material
	
	container.add_child(glow_rect)
	container.move_child(glow_rect, 0)  # Move to back


## Blue shimmer effect for rare items
static func _add_rare_shimmer(container: Control, width: float, height: float, color: Color) -> void:
	var shimmer_rect = ColorRect.new()
	shimmer_rect.size = Vector2(width, height)
	shimmer_rect.color = Color.WHITE
	shimmer_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Load and apply shimmer shader
	var shader = load("res://resources/shaders/shimmer_effect.gdshader")
	if shader:
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("shimmer_color", color)
		material.set_shader_parameter("shimmer_speed", 2.0)
		material.set_shader_parameter("shimmer_width", 0.3)
		shimmer_rect.material = material
	
	container.add_child(shimmer_rect)
	container.move_child(shimmer_rect, 0)  # Move to back


## Purple pulsing glow for epic items
static func _add_epic_pulse(container: Control, width: float, height: float, color: Color) -> void:
	var pulse_rect = ColorRect.new()
	pulse_rect.size = Vector2(width, height)
	pulse_rect.color = color
	pulse_rect.color.a = 0.3
	pulse_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse_rect.name = "PulseRect"  # Give it a specific name for animation
	container.add_child(pulse_rect)
	container.move_child(pulse_rect, 0)  # Move to back
	
	# Create AnimationPlayer for pulsing
	var anim_player = AnimationPlayer.new()
	container.add_child(anim_player)
	
	# Create pulse animation
	var animation = Animation.new()
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, NodePath("PulseRect:color:a"))
	animation.length = 2.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	# Keyframes for pulsing effect
	animation.track_insert_key(track_idx, 0.0, 0.2)
	animation.track_insert_key(track_idx, 1.0, 0.5)
	animation.track_insert_key(track_idx, 2.0, 0.2)
	
	# Add animation to player
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("pulse", animation)
	anim_player.add_animation_library("", anim_library)
	anim_player.play("pulse")


## Gold particle effect for legendary items
static func _add_legendary_particles(container: Control, width: float, height: float, color: Color) -> void:
	# Add background glow
	var glow_rect = ColorRect.new()
	glow_rect.size = Vector2(width, height)
	glow_rect.color = color
	glow_rect.color.a = 0.4
	glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_rect.name = "GlowRect"  # Give it a specific name for animation
	container.add_child(glow_rect)
	container.move_child(glow_rect, 0)
	
	# Create particle system
	var particles = GPUParticles2D.new()
	particles.position = Vector2(width / 2, height / 2)
	particles.amount = 20
	particles.lifetime = 2.0
	particles.preprocess = 0.5
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	# Note: GPUParticles2D doesn't block mouse events by default
	
	# Create process material
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_mat.emission_box_extents = Vector3(width * 0.4, height * 0.4, 0)
	particle_mat.direction = Vector3(0, -1, 0)
	particle_mat.spread = 30.0
	particle_mat.initial_velocity_min = 10.0
	particle_mat.initial_velocity_max = 20.0
	particle_mat.gravity = Vector3(0, -15, 0)
	particle_mat.scale_min = 2.0
	particle_mat.scale_max = 4.0
	particle_mat.color = color
	particles.process_material = particle_mat
	
	# Create simple square texture for particles
	var particle_texture = _create_particle_texture()
	particles.texture = particle_texture
	
	container.add_child(particles)
	particles.emitting = true
	
	# Add AnimationPlayer for shine effect
	var anim_player = AnimationPlayer.new()
	container.add_child(anim_player)
	
	var animation = Animation.new()
	var track_idx = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_idx, NodePath("GlowRect:color:a"))
	animation.length = 3.0
	animation.loop_mode = Animation.LOOP_LINEAR
	
	animation.track_insert_key(track_idx, 0.0, 0.3)
	animation.track_insert_key(track_idx, 1.5, 0.6)
	animation.track_insert_key(track_idx, 3.0, 0.3)
	
	var anim_library = AnimationLibrary.new()
	anim_library.add_animation("shine", animation)
	anim_player.add_animation_library("", anim_library)
	anim_player.play("shine")


## Create a simple particle texture
static func _create_particle_texture() -> Texture2D:
	# Create a small gradient texture for particles
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	
	for y in range(8):
		for x in range(8):
			var dx = x - 4.0
			var dy = y - 4.0
			var dist = sqrt(dx * dx + dy * dy)
			var alpha = clamp(1.0 - dist / 4.0, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(img)


# ==============================================================================
# ICON DRAWING FUNCTIONS - Clean shapes without backgrounds
# ==============================================================================

static func _draw_scrap_icon(container: Control, pad: float, w: float, h: float, color: Color) -> void:
	# Irregular metal pieces
	var piece1 = ColorRect.new()
	piece1.position = Vector2(pad + w * 0.1, pad + h * 0.2)
	piece1.size = Vector2(w * 0.5, h * 0.3)
	piece1.rotation_degrees = -10
	piece1.color = color
	piece1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(piece1)
	
	var piece2 = ColorRect.new()
	piece2.position = Vector2(pad + w * 0.3, pad + h * 0.5)
	piece2.size = Vector2(w * 0.6, h * 0.25)
	piece2.rotation_degrees = 5
	piece2.color = color.lightened(0.1)
	piece2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(piece2)
	
	var piece3 = ColorRect.new()
	piece3.position = Vector2(pad + w * 0.15, pad + h * 0.6)
	piece3.size = Vector2(w * 0.35, h * 0.2)
	piece3.rotation_degrees = -5
	piece3.color = color.darkened(0.1)
	piece3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(piece3)


static func _draw_tech_icon(container: Control, pad: float, w: float, h: float, color: Color) -> void:
	# Circuit board shape
	var board = ColorRect.new()
	board.position = Vector2(pad + w * 0.1, pad + h * 0.15)
	board.size = Vector2(w * 0.8, h * 0.7)
	board.color = color
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(board)
	
	# Circuit traces
	var trace_color = Color(0.3, 0.9, 0.5, 0.8)
	for i in range(3):
		var trace = ColorRect.new()
		trace.position = Vector2(pad + w * 0.15, pad + h * 0.25 + i * h * 0.2)
		trace.size = Vector2(w * 0.7, 2)
		trace.color = trace_color
		trace.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(trace)
	
	# Chip in center
	var chip = ColorRect.new()
	chip.position = Vector2(pad + w * 0.35, pad + h * 0.35)
	chip.size = Vector2(w * 0.3, h * 0.3)
	chip.color = Color(0.15, 0.15, 0.2)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(chip)


static func _draw_medical_icon(container: Control, pad: float, w: float, h: float) -> void:
	var cross_color = Color(0.95, 0.95, 0.95)
	var bg_color = Color(0.9, 0.2, 0.2)
	var cx = pad + w / 2
	var cy = pad + h / 2
	var arm = min(w, h) * 0.35
	var thick = arm * 0.4
	
	# Red circle background
	var bg = ColorRect.new()
	bg.position = Vector2(pad + w * 0.1, pad + h * 0.1)
	bg.size = Vector2(w * 0.8, h * 0.8)
	bg.color = bg_color
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)
	
	# White cross
	var vbar = ColorRect.new()
	vbar.position = Vector2(cx - thick/2, cy - arm)
	vbar.size = Vector2(thick, arm * 2)
	vbar.color = cross_color
	vbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(vbar)
	
	var hbar = ColorRect.new()
	hbar.position = Vector2(cx - arm, cy - thick/2)
	hbar.size = Vector2(arm * 2, thick)
	hbar.color = cross_color
	hbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(hbar)


static func _draw_weapon_icon(container: Control, pad: float, w: float, h: float, color: Color) -> void:
	# Weapon/module shape - angular
	var body = ColorRect.new()
	body.position = Vector2(pad + w * 0.1, pad + h * 0.3)
	body.size = Vector2(w * 0.8, h * 0.4)
	body.color = color
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(body)
	
	# Barrel/extension
	var barrel = ColorRect.new()
	barrel.position = Vector2(pad + w * 0.7, pad + h * 0.35)
	barrel.size = Vector2(w * 0.25, h * 0.3)
	barrel.color = color.darkened(0.2)
	barrel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(barrel)
	
	# Power indicator
	var indicator = ColorRect.new()
	indicator.position = Vector2(pad + w * 0.2, pad + h * 0.4)
	indicator.size = Vector2(w * 0.15, h * 0.2)
	indicator.color = Color(1, 0.3, 0.2)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(indicator)


static func _draw_data_icon(container: Control, pad: float, w: float, h: float, color: Color) -> void:
	# Data chip shape
	var chip = ColorRect.new()
	chip.position = Vector2(pad + w * 0.15, pad + h * 0.1)
	chip.size = Vector2(w * 0.7, h * 0.7)
	chip.color = color
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(chip)
	
	# Contact pins
	var pin_color = Color(0.85, 0.8, 0.4)
	var pins = int(w / 16)
	pins = max(3, pins)
	var pin_width = (w * 0.6) / pins
	for i in range(pins):
		var pin = ColorRect.new()
		pin.position = Vector2(pad + w * 0.2 + i * pin_width, pad + h * 0.75)
		pin.size = Vector2(pin_width * 0.6, h * 0.15)
		pin.color = pin_color
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(pin)
	
	# Label area
	var label = ColorRect.new()
	label.position = Vector2(pad + w * 0.25, pad + h * 0.25)
	label.size = Vector2(w * 0.5, h * 0.3)
	label.color = Color(0.1, 0.1, 0.15)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)


static func _draw_power_icon(container: Control, pad: float, w: float, h: float, color: Color) -> void:
	# Battery/power cell shape
	var body = ColorRect.new()
	body.position = Vector2(pad + w * 0.2, pad + h * 0.15)
	body.size = Vector2(w * 0.6, h * 0.7)
	body.color = color.darkened(0.2)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(body)
	
	# Glowing core
	var core = ColorRect.new()
	core.position = Vector2(pad + w * 0.25, pad + h * 0.25)
	core.size = Vector2(w * 0.5, h * 0.5)
	core.color = Color(0.5, 1.0, 1.0, 0.9)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(core)
	
	# Terminal on top
	var terminal = ColorRect.new()
	terminal.position = Vector2(pad + w * 0.35, pad + h * 0.05)
	terminal.size = Vector2(w * 0.3, h * 0.12)
	terminal.color = Color(0.5, 0.5, 0.5)
	terminal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(terminal)


static func _draw_artifact_icon(container: Control, pad: float, w: float, h: float, color: Color) -> void:
	var cx = pad + w / 2
	var cy = pad + h / 2
	var size = min(w, h) * 0.35
	
	# Crystal/gem shape - rotated square
	var gem = ColorRect.new()
	gem.position = Vector2(cx - size, cy - size)
	gem.size = Vector2(size * 2, size * 2)
	gem.rotation_degrees = 45
	gem.pivot_offset = Vector2(size, size)
	gem.color = color
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(gem)
	
	# Inner shine
	var shine_size = size * 0.5
	var shine = ColorRect.new()
	shine.position = Vector2(cx - shine_size, cy - shine_size)
	shine.size = Vector2(shine_size * 2, shine_size * 2)
	shine.rotation_degrees = 45
	shine.pivot_offset = Vector2(shine_size, shine_size)
	shine.color = Color(1, 1, 1, 0.5)
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(shine)


static func _draw_cargo_icon(container: Control, pad: float, w: float, h: float, color: Color) -> void:
	# Crate shape
	var crate = ColorRect.new()
	crate.position = Vector2(pad + w * 0.1, pad + h * 0.15)
	crate.size = Vector2(w * 0.8, h * 0.7)
	crate.color = color
	crate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(crate)
	
	# Horizontal bands
	var band_color = color.darkened(0.25)
	var band1 = ColorRect.new()
	band1.position = Vector2(pad + w * 0.1, pad + h * 0.35)
	band1.size = Vector2(w * 0.8, h * 0.08)
	band1.color = band_color
	band1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(band1)
	
	var band2 = ColorRect.new()
	band2.position = Vector2(pad + w * 0.1, pad + h * 0.55)
	band2.size = Vector2(w * 0.8, h * 0.08)
	band2.color = band_color
	band2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(band2)
