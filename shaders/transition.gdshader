shader_type canvas_item;

uniform sampler2D scene_texture;
uniform sampler2D new_scene_texture;
uniform float pixel_size : hint_range(1.0, 50.0) = 1.0;
uniform bool use_new_scene = false;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Smooth pixelation steps (avoiding immediate loss of detail)
    float step_size = 1.0 / max(pixel_size, 1.0);
    uv = floor(uv / step_size) * step_size;
    
    // Use the correct texture
    if (use_new_scene) {
        COLOR = texture(new_scene_texture, uv);
    } else {
        COLOR = texture(scene_texture, uv);
    }
}