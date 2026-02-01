// Shimmer effect shader for rare items
shader_type canvas_item;

uniform vec4 shimmer_color : source_color = vec4(0.4, 0.6, 1.0, 0.5);
uniform float shimmer_speed : hint_range(0.1, 5.0) = 2.0;
uniform float shimmer_width : hint_range(0.1, 1.0) = 0.3;

void fragment() {
	// Create animated shimmer moving across the item
	float shimmer_pos = fract(TIME * shimmer_speed * 0.2);
	float dist = abs(UV.x - shimmer_pos);
	float shimmer = smoothstep(shimmer_width, 0.0, dist);
	
	// Add diagonal shimmer for more visual interest
	float diagonal_shimmer_pos = fract((UV.x + UV.y) * 0.5 + TIME * shimmer_speed * 0.15);
	float diagonal_shimmer = smoothstep(shimmer_width * 0.5, 0.0, abs(diagonal_shimmer_pos - 0.5)) * 0.3;
	
	// Combine shimmers
	float total_shimmer = shimmer + diagonal_shimmer;
	
	// Apply shimmer color
	COLOR.rgb = mix(COLOR.rgb, shimmer_color.rgb, total_shimmer * shimmer_color.a);
}
