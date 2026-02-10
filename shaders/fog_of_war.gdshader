shader_type canvas_item;

// Fog of War Shader for Ship Interiors
// Uses RGBA where:
// - R,G,B = blur amount (grayscale)
// - A = fog opacity (1 = fully fogged, 0 = clear)

uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float blur_strength : hint_range(0.0, 20.0) = 8.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;

void fragment() {
	vec4 fog_data = texture(TEXTURE, UV);
	float blur_amount = fog_data.r;
	float fog_opacity = fog_data.a;
	
	// Get base color from screen
	vec2 screen_uv = SCREEN_UV;
	vec4 base_color = texture(screen_texture, screen_uv);
	
	// Apply blur for peripheral vision
	if (blur_amount > 0.01) {
		vec2 pixel_size = SCREEN_PIXEL_SIZE * blur_strength * blur_amount;
		vec4 blurred = vec4(0.0);
		
		// 9-tap gaussian-ish blur
		blurred += texture(screen_texture, screen_uv + vec2(-1, -1) * pixel_size) * 0.0625;
		blurred += texture(screen_texture, screen_uv + vec2(0, -1) * pixel_size) * 0.125;
		blurred += texture(screen_texture, screen_uv + vec2(1, -1) * pixel_size) * 0.0625;
		blurred += texture(screen_texture, screen_uv + vec2(-1, 0) * pixel_size) * 0.125;
		blurred += texture(screen_texture, screen_uv) * 0.25;
		blurred += texture(screen_texture, screen_uv + vec2(1, 0) * pixel_size) * 0.125;
		blurred += texture(screen_texture, screen_uv + vec2(-1, 1) * pixel_size) * 0.0625;
		blurred += texture(screen_texture, screen_uv + vec2(0, 1) * pixel_size) * 0.125;
		blurred += texture(screen_texture, screen_uv + vec2(1, 1) * pixel_size) * 0.0625;
		
		base_color = mix(base_color, blurred, blur_amount);
		
		// Slight desaturation for peripheral areas
		float gray = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
		base_color.rgb = mix(base_color.rgb, vec3(gray), blur_amount * 0.3);
	}
	
	// Apply fog overlay
	COLOR = mix(base_color, fog_color, fog_opacity);
}
