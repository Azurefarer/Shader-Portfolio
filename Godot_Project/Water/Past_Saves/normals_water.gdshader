shader_type spatial;

//Base material properties
uniform vec3 albedo1 : source_color;
uniform vec3 albedo2 : source_color;
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = .02;

//Samplers
uniform sampler2D wave;
uniform sampler2D water_normal; // background water noise
uniform sampler2D wind_normal; // what will the water look like when wind is blowing
uniform sampler2D current_normal; // what will the water look like when wind is not blowing
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D vignette;

//Water stuff
uniform float wind_strength : hint_range(0.0, 1.0) = 0.25;
uniform float current_strength : hint_range(0.0, 1.0) = 0.25;
uniform float water_background : hint_range(0.0, 1.0) = 0.25;
uniform vec2 wind_direction = vec2(2.0, 0.0);
uniform vec2 current_direction = vec2(0.0, 1.0);
uniform float time_scale : hint_range(0.0, 1.0, .005) = .025;
uniform float noise_scale : hint_range(0.0, 25.0) = 10.0;
uniform float height_scale : hint_range(0.0, 1.0) = .15;

//Depth
uniform vec4 color_deep : source_color;
uniform vec4 color_shallow : source_color;
uniform float fresnel_coef : hint_range(0.0, 10.0, .25) = 1.0;
uniform float beers_law = 2.0;

//Edge
uniform float edge_scale = .1;
uniform vec3 edge_color : source_color;

// Misc
uniform float small_angle : hint_range(0.0, .262) = .017; // from 0 - 15 degrees | set to 1
uniform float epsilon : hint_range(0.0, .1, 0.001) = .001; // small number | for fine details

// Varying.
varying float height;
varying vec3 world_pos;

vec2 twoD_rot(vec2 vector, float angle) {
	mat2 rot = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
	return rot * vector;
}

float wave_fct(vec2 position) {
  position += texture(wave, position).x * 2.0 - 1.0;
  vec2 wv = 1.0 - abs(sin(position));
  return pow(1.0 - pow(wv.x * wv.y, 0.65), 4.0);
}

float height_fct(vec2 position, float time) {
//  vec2 offset = 0.1 * cos(position + time);
//  return texture(wave, (position) - offset).x;
	float h = wave_fct((position + time) * 0.1) * 0.3;
	return h;
}

float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((dot(normalize(normal), normalize(view))), amount);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 pos = VERTEX.xz;
	
	// Tangent, Binormal, Normal Calcs
	vec4 wave_tex = texture(wave, world_pos.xz);
	TANGENT = vec3(0.0, 0.0, dFdx(wave_tex.x));
	BINORMAL = vec3(0.0, 0.0, dFdx(wave_tex.z));
	NORMAL = normalize(cross(TANGENT, BINORMAL));	

	height = height_fct(world_pos.xz, TIME);
	VERTEX.y += 1.0 * height;

//	NORMAL = normalize(vec3(height - height_fct(world_pos.xz + vec2(0.1, 0.0), TIME), 0.1, height - height_fct(world_pos.xz + vec2(0.1, 0.0), TIME)));
//	NORMAL = MODEL_NORMAL_MATRIX * NORMAL; // this makes it so the normal is of the underlyingt plane | does not include ridges...
}

void fragment() {
	// TIME
	float time_adj = TIME * pow(epsilon, 2.0);
	// Calc Fresnel.
	float fresnel = fresnel(fresnel_coef, NORMAL, VIEW);
	
	// Adding oscillation to the directions
	vec2 adj_wind_direction = twoD_rot(wind_direction, small_angle*sin(TIME));
	vec2 adj_current_direction = twoD_rot(current_direction, small_angle*sin(TIME));
	
	// Time calcs for wave (normal map) movement.
	vec2 time_water = twoD_rot(vec2(water_background), TIME);  //Movement rate of water.
	vec2 time_wind = TIME * wind_strength * normalize(epsilon * adj_wind_direction + wind_direction);  //Movement rate of wind.
	vec2 time_current = TIME * current_strength * normalize(epsilon * adj_current_direction + current_direction);  //Movement rate of current.

	// Generate normal maps
	vec3 water_tex = texture(water_normal, world_pos.xz/noise_scale + time_water).rgb;
	vec3 wind_tex = texture(wind_normal, world_pos.xz/noise_scale + time_wind).rgb;
	vec3 current_tex = texture(current_normal, world_pos.xz/noise_scale + time_current).rgb;
	
	// Blend normal maps into one.	
	vec3 wind_blend = mix(water_tex, wind_tex, wind_strength);
	vec3 current_blend = mix(water_tex, current_tex, current_strength);
	vec3 blend = mix(current_blend, wind_blend, wind_strength);

	// Depth variables and calc
	float depth_texture = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV, depth_texture);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z;
	linear_depth = VERTEX.z + linear_depth;
	
	float depth_blend = pow(fresnel, fresnel_coef) / clamp(linear_depth, 5.0, 100.0) * exp(clamp(linear_depth, 0.0, 1.0) * (1.0 - fresnel) * -beers_law);
	
	vec3 screen_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, depth_blend*3.5).rgb;
	vec3 depth_color = mix(color_deep.rgb, color_shallow.rgb, depth_blend);
	vec3 color = mix(depth_color, screen_color * depth_color, depth_blend);
	
	// Edge depth calc
	float z_dif = linear_depth - FRAGCOORD.z;
	
	// surface color
	vec3 albedo = mix(albedo1, albedo2, fresnel);
	vec3 surface_color = mix(albedo, color, fresnel); //Interpolate albedo values by fresnel
	
	// Edge color
	vec3 edge_color_adj = mix(edge_color, color, linear_depth);
	vec3 depth_color_adj = mix(edge_color_adj, color, step(edge_scale, linear_depth));
	
	
	// Vignette
	float vignette_grad = texture(vignette, UV).x;
	
	// edge correction
	if (linear_depth <= edge_scale || linear_depth >= 1.0) {
		linear_depth = 1.0;
	}
	if (linear_depth <= edge_scale) {
		depth_color_adj = vec3(0.0);
	}
	// Out
//	ALPHA = vignette_grad * 10.0 + pow(linear_depth, 0.5);	 
	ALPHA = pow(linear_depth, 0.5);	
//	ALBEDO = clamp(surface_color + depth_color_adj, vec3(0.0), vec3(1.0));
	ALBEDO = vec3(-VERTEX.z);

//	METALLIC = metallic;
//	ROUGHNESS = roughness;
//	NORMAL_MAP = blend;
}
