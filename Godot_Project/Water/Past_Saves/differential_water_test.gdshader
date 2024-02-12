shader_type spatial;
render_mode skip_vertex_transform, unshaded;

uniform int num_sines;

varying mat4 invViewMat;

struct Wavex {
	vec4 v; // velocity
	float pos; // position
	vec4 f; // frequency
	vec4 w; // wavelength
	vec4 p; // phase
	vec4 a; // amplitude
};

struct Wavez {
	vec4 v; // velocity
	float pos; // position
	vec4 f; // frequency
	vec4 w; // wavelength
	vec4 p; // phase
	vec4 a; // amplitude
};

float wave_fct(float time, Wavex wx, Wavez wz) {
	float sum = 0.0;
	for (int i = 0; i <= (num_sines-1); i++) {
		sum += (wx.a[i] * wz.a[i]) * sin(wx.pos * wx.f[i] + time * wx.p[i] + wz.pos * wz.f[i] + time * wz.p[i]);
	}
	return sum;
}

float wave_fct_dx(float time, Wavex wx, Wavez wz) {
	float sum = 0.0;
	for (int i = 0; i <= (num_sines-1); i++) {
		sum += (wx.f[i]) * (wx.a[i] * wz.a[i]) * cos(wx.pos * wx.f[i] + time * wx.p[i] + wz.pos * wz.f[i] + time * wz.p[i]);
	}
	return sum;
}

float wave_fct_dz(float time, Wavex wx, Wavez wz) {
	float sum = 0.0;
	for (int i = 0; i <= (num_sines-1); i++) {
		sum += (wz.f[i]) * (wx.a[i] * wz.a[i]) * cos(wx.pos * wx.f[i] + time * wx.p[i] + wz.pos * wz.f[i] + time * wz.p[i]);
	}
	return sum;
}

void vertex() {
//	vec3 world_pos = vec3((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz);
	Wavex water_wavex;
		water_wavex.a = vec4(1.0, 2.0, 1.5, 3.0);
		water_wavex.f = vec4(1.0, 2.0, 1.5, 3.0);
		water_wavex.p = vec4(1.0, 2.0, 1.5, 3.0);
		water_wavex.pos = VERTEX.x;
	Wavez water_wavez;
		water_wavez.a = vec4(1.5, 0.2, 4.5, 2.0);
		water_wavez.f = vec4(1.5, 0.2, 4.5, 2.0);
		water_wavez.p = vec4(1.5, 0.2, 4.5, 2.0);
		water_wavez.pos = VERTEX.z;
	
	float wave_height = wave_fct(0.0, water_wavex, water_wavez);
	VERTEX.y = wave_height;	

	TANGENT = vec3(1.0, 0.0, wave_fct_dx(0.0, water_wavex, water_wavez));
	BINORMAL = vec3(0.0, 1.0, wave_fct_dz(0.0, water_wavex, water_wavez));
	NORMAL = cross(TANGENT, BINORMAL);
	VERTEX = vec3((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
//	NORMAL = MODEL_NORMAL_MATRIX * NORMAL;
	
	invViewMat = INV_VIEW_MATRIX;
}

void fragment() {
	ALBEDO = NORMAL.xzy;
}

//void light() {
////	vec3 light = vec3(0.0, 0.0, 0.0);
//	vec3 light = vec3((invViewMat * vec4(LIGHT, 0.0)).xyz);
//	DIFFUSE_LIGHT = ALBEDO * dot(NORMAL.xzy, light);
//}
