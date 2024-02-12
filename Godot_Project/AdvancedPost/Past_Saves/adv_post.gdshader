shader_type spatial;

uniform sampler2D rain : repeat_enable;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec4 full_screen_rain = texture(rain, UV);
	ALBEDO = full_screen_rain.rgb;
	ALPHA = full_screen_rain.a;
}
