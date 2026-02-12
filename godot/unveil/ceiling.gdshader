shader_type spatial;

uniform sampler2D center_tile_on;
uniform sampler2D center_tile_off;
uniform sampler2D regular_tile;
uniform bool light_on = true;

void fragment() {
    float third = 1.0 / 3.0;
    float two_thirds = 2.0 / 3.0;
	vec2 uv_scaled = UV * 3.0;
    vec4 center_tile = texture(regular_tile, uv_scaled);
	
    if (UV.x > third && UV.x < two_thirds && UV.y > third && UV.y < two_thirds) {
        vec2 center_uv = (UV - third) * 3.0; 
		if (light_on) {
			center_tile = texture(center_tile_on, center_uv);
		} else {
			center_tile = texture(center_tile_off, center_uv);
		}
    }
    ALBEDO = center_tile.rgb;
}