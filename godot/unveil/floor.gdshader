shader_type spatial;

uniform sampler2D floor_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 scaled_uv = UV * 3.0;
	vec4 tex = texture(floor_texture, scaled_uv);
	ALBEDO = tex.rgb;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
