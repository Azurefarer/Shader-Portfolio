shader_type spatial;

uniform sampler2D gradient;
uniform sampler2D screen : hint_screen_texture;

void vertex() {
	POSITION = vec4(VERTEX.x, VERTEX.y, VERTEX.z, 1.0);
}

// FIX-ME: screen sampling after manually setting POSITION vector needs tuning.

void fragment() {
	vec4 screen_sample = texture(screen, -UV);
	vec4 vingette = texture(gradient, UV);	
	
	ALBEDO = screen_sample.rgb * vingette.rgb;
}
