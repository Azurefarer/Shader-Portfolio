shader_type spatial;

uniform sampler2D rain : repeat_enable;

void vertex(){
//	VERTEX.xy = VERTEX.xy - vec2(TIME*.1);
}

void fragment() {
	vec2 uv = UV;
	vec4 raindrop = texture(rain, vec2(uv.x + TIME*.1, uv.y - TIME*.3));
	ALBEDO = raindrop.rgb;
	ALPHA = raindrop.a;
}
