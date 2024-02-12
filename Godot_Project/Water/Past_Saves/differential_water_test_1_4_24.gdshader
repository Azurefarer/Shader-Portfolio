shader_type spatial;
render_mode skip_vertex_transform;

#define randomFloat(N) randf(N) * scale

const int num_sines = 5;

uniform float epsilon : hint_range(0.0, 0.001, 0.00001) = 0.000001;
uniform float scale;
uniform sampler2D rand;

varying mat4 invViewMat;

struct Wave {
	float[num_sines] v; // velocity
	float pos; // position
	float[num_sines] f; // frequency
	float[num_sines] w; // wavelength
	float[num_sines] p; // phase
	float[num_sines] a; // amplitude
};

float randf(float seed) {
//	return float(texture(rand, vec2(seed*epsilon, seed*epsilon)).z);
	return 1.0;
}

Wave wave_gen(Wave w, float seed) {
	float j = 1.0;
	for (int i = 0; i <= (num_sines-1); i++, j += 1.0) {
		w.a[i] = randomFloat(seed) * 2.0 / j;
		w.f[i] = randomFloat(seed) * 2.0;
		w.w[i] = randomFloat(seed) * 2.0;
		w.v[i] = w.f[i]*w.w[i];
		w.p[i] = w.v[i] * (2.0 * PI / w.w[i]);
	}
	return w;
}

float wave_fct(float time, Wave wx, Wave wz) {
	float sum = 0.0;
	for (int i = 0; i <= (num_sines-1); i++) {
		sum += (wx.a[i] * wz.a[i]) * sin(wx.pos * wx.f[i] + time * wx.p[i] + wz.pos * wz.f[i] + time * wz.p[i]);
	}
	return sum;
}

float wave_fct_dx(float time, Wave wx, Wave wz) {
	float sum = 0.0;
	for (int i = 0; i <= (num_sines-1); i++) {
		sum += (wx.f[i]) * (wx.a[i] * wz.a[i]) * cos(wx.pos * wx.f[i] + time * wx.p[i] + wz.pos * wz.f[i] + time * wz.p[i]);
	}
	return sum;
}

float wave_fct_dz(float time, Wave wx, Wave wz) {
	float sum = 0.0;
	for (int i = 0; i <= (num_sines-1); i++) {
		sum += (wz.f[i]) * (wx.a[i] * wz.a[i]) * cos(wx.pos * wx.f[i] + time * wx.p[i] + wz.pos * wz.f[i] + time * wz.p[i]);
	}
	return sum;
}

void vertex() {
	vec3 world_pos = vec3((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);	
	Wave water_wavex;
		water_wavex = wave_gen(water_wavex, VERTEX.x);
		water_wavex.pos = VERTEX.x;
	Wave water_wavez;
		water_wavez = wave_gen(water_wavez, VERTEX.z);
		water_wavez.pos = VERTEX.z;
	
	float wave_height = wave_fct(0.0, water_wavex, water_wavez);
	VERTEX.y = wave_height;	

	TANGENT = vec3(1.0, 0.0, wave_fct_dx(0.0, water_wavex, water_wavez));
	BINORMAL = vec3(0.0, 1.0, wave_fct_dz(0.0, water_wavex, water_wavez));
	NORMAL = normalize(cross(TANGENT, BINORMAL));
	VERTEX = vec3((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
//	NORMAL = MODEL_NORMAL_MATRIX * NORMAL;
	
	invViewMat = INV_VIEW_MATRIX;
}

// FIXME: NORMAL.xzy

void fragment() {
	ALBEDO = NORMAL.xzy;
//	METALLIC = 0.0;
//	ROUGHNESS = 0.0;
}

//void light() {
//	vec4 light = invViewMat * vec4(LIGHT, 0.0);
//	DIFFUSE_LIGHT += ALBEDO * dot(NORMAL.xzy, light.xyz);
//}
