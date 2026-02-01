shader_type canvas_item;
render_mode unshaded;

// Colorblind simulation shader for Godot 4.x
// Based on research from:
// - Brettel, Viénot and Mollon (1997)
// - Machado, Oliveira and Fernandes (2009)

uniform int mode = 0; // 0=none, 1=deuteranopia, 2=protanopia, 3=tritanopia

// Deuteranopia transformation matrix (red-green, missing green cones)
const mat3 DEUTERANOPIA = mat3(
	vec3(0.625, 0.375, 0.0),
	vec3(0.7, 0.3, 0.0),
	vec3(0.0, 0.3, 0.7)
);

// Protanopia transformation matrix (red-green, missing red cones)
const mat3 PROTANOPIA = mat3(
	vec3(0.567, 0.433, 0.0),
	vec3(0.558, 0.442, 0.0),
	vec3(0.0, 0.242, 0.758)
);

// Tritanopia transformation matrix (blue-yellow, missing blue cones)
const mat3 TRITANOPIA = mat3(
	vec3(0.95, 0.05, 0.0),
	vec3(0.0, 0.433, 0.567),
	vec3(0.0, 0.475, 0.525)
);

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec3 rgb = color.rgb;
	
	if (mode == 1) {
		// Deuteranopia
		rgb = DEUTERANOPIA * rgb;
	} else if (mode == 2) {
		// Protanopia
		rgb = PROTANOPIA * rgb;
	} else if (mode == 3) {
		// Tritanopia
		rgb = TRITANOPIA * rgb;
	}
	// mode == 0 or invalid: no change
	
	COLOR = vec4(rgb, color.a);
}
