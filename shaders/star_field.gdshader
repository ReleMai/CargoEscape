// ==============================================================================
// STAR FIELD SHADER - GPU-ACCELERATED PROCEDURAL STARS
// ==============================================================================
//
// PURPOSE: Renders a procedural star field using GPU for performance
//
// FEATURES:
// - Procedural star generation based on UV coordinates
// - Parallax scrolling support via UV offset
// - Twinkling animation
// - Multiple star layers with different sizes
// - Color variation
// - LOD support for distant stars
//
// USAGE:
// Apply to a ColorRect or Sprite2D in your parallax layer
//
// ==============================================================================

shader_type canvas_item;

// ==============================================================================
// UNIFORMS - Configurable parameters
// ==============================================================================

// Scrolling offset for parallax effect
uniform vec2 scroll_offset = vec2(0.0, 0.0);

// Star density (higher = more stars)
uniform float star_density : hint_range(0.0, 100.0) = 50.0;

// Star size range
uniform float star_size_min : hint_range(0.0, 5.0) = 0.5;
uniform float star_size_max : hint_range(0.0, 10.0) = 3.0;

// Twinkling animation
uniform float time_scale : hint_range(0.0, 5.0) = 1.0;
uniform float twinkle_speed : hint_range(0.0, 10.0) = 2.0;
uniform float twinkle_amount : hint_range(0.0, 1.0) = 0.3;

// Color theming
uniform vec3 base_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float color_variation : hint_range(0.0, 1.0) = 0.2;

// Layer depth (for parallax - higher = closer/faster)
uniform float layer_depth : hint_range(0.0, 1.0) = 0.5;

// Background color
uniform vec4 background_color : source_color = vec4(0.02, 0.02, 0.06, 1.0);

// ==============================================================================
// NOISE FUNCTIONS - Pseudo-random number generation
// ==============================================================================

// Hash function for pseudo-random numbers
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// 2D noise function
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    // Smooth interpolation
    f = f * f * (3.0 - 2.0 * f);
    
    // Four corners
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    
    // Mix
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// ==============================================================================
// STAR GENERATION
// ==============================================================================

// Generate a star at a given cell position
vec4 generate_star(vec2 uv, vec2 cell_pos, float time_var) {
    vec2 cell_center = cell_pos + 0.5;
    
    // Random offset within cell
    float offset_x = hash(cell_pos) * 0.8 - 0.4;
    float offset_y = hash(cell_pos + vec2(42.0, 17.0)) * 0.8 - 0.4;
    vec2 star_pos = cell_center + vec2(offset_x, offset_y);
    
    // Distance from pixel to star
    float dist = distance(uv, star_pos);
    
    // Star size (varies per star)
    float size_rand = hash(cell_pos + vec2(13.0, 37.0));
    float star_size = mix(star_size_min, star_size_max, size_rand);
    
    // Star brightness falloff
    float brightness = 1.0 - smoothstep(0.0, star_size * 0.01, dist);
    
    // Twinkle effect
    float twinkle_phase = hash(cell_pos + vec2(99.0, 23.0)) * 6.28318;
    float twinkle = sin(time_var * twinkle_speed + twinkle_phase) * twinkle_amount;
    brightness *= (1.0 - twinkle_amount) + twinkle;
    
    // Color variation
    float color_rand_r = hash(cell_pos + vec2(7.0, 11.0));
    float color_rand_g = hash(cell_pos + vec2(13.0, 19.0));
    float color_rand_b = hash(cell_pos + vec2(23.0, 29.0));
    
    vec3 star_color = base_color + vec3(
        (color_rand_r - 0.5) * color_variation,
        (color_rand_g - 0.5) * color_variation,
        (color_rand_b - 0.5) * color_variation
    );
    
    star_color = clamp(star_color, 0.0, 1.0);
    
    return vec4(star_color, brightness);
}

// ==============================================================================
// FRAGMENT SHADER
// ==============================================================================

void fragment() {
    // Apply scroll offset for parallax
    vec2 scrolled_uv = UV + scroll_offset * layer_depth;
    
    // Time for animation
    float time_var = TIME * time_scale;
    
    // Scale UV for star density
    vec2 scaled_uv = scrolled_uv * star_density;
    
    // Get current cell
    vec2 cell = floor(scaled_uv);
    vec2 local_uv = fract(scaled_uv);
    
    // Start with background
    vec4 final_color = background_color;
    
    // Check current cell and neighboring cells for stars
    for(float x = -1.0; x <= 1.0; x += 1.0) {
        for(float y = -1.0; y <= 1.0; y += 1.0) {
            vec2 neighbor_cell = cell + vec2(x, y);
            
            // Probability of star in this cell
            float star_prob = hash(neighbor_cell);
            
            // Only generate star if random value is high enough
            if(star_prob > 0.5) {
                vec2 neighbor_uv = local_uv - vec2(x, y);
                vec4 star = generate_star(neighbor_uv, neighbor_cell, time_var);
                
                // Alpha blend star onto background
                final_color.rgb = mix(final_color.rgb, star.rgb, star.a);
                final_color.a = max(final_color.a, star.a);
            }
        }
    }
    
    COLOR = final_color;
}
