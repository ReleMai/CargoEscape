// Subtle glow effect shader for uncommon items
shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.4, 0.9, 0.4, 0.3);
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float glow_speed : hint_range(0.1, 3.0) = 1.0;

void fragment() {
	// Gentle pulsing glow
	float pulse = sin(TIME * glow_speed) * 0.3 + 0.7;
	
	// Edge-based glow (stronger at edges)
	float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float edge_glow = smoothstep(0.3, 0.0, edge_dist) * 0.5;
	
	// Apply subtle glow
	float total_glow = (pulse + edge_glow) * glow_intensity;
	COLOR.rgb = mix(COLOR.rgb, glow_color.rgb, total_glow * glow_color.a);
}
