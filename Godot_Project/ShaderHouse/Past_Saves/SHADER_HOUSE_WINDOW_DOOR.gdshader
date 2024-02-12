shader_type spatial;
render_mode cull_disabled;

uniform sampler2D walls : filter_linear_mipmap;

void fragment() {
	
	vec4 wallTex = texture(walls, UV);
	ALBEDO = wallTex.rgb;
	ALBEDO = vec3(UV, 0.0);
}