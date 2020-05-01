shader_type spatial;

uniform vec2 amplitude = vec2(0.01, 0.05);
uniform vec2 frequency = vec2(3.0, 2.5);
uniform vec2 time_factor = vec2(2.0, 3.0);

uniform sampler2D uv_offset_texture : hint_black;
uniform vec2 uv_offset_scale = vec2(0.2, 0.2);
uniform float uv_offset_time_scale = 0.01;
uniform float uv_offset_amplitude = 0.2;

uniform sampler2D texturemap : hint_albedo;
uniform vec2 texture_scale = vec2(8.0, 4.0);

uniform sampler2D normalmap : hint_normal;
uniform float refraction = 0.05;

uniform float beer_factor = 1.0;

float height(vec2 pos, float time) {
	return (amplitude.x * sin(pos.x * frequency.x + time * time_factor.x)) + (amplitude.y * sin(pos.y * frequency.y + time * time_factor.y));
}

void vertex() {
	VERTEX.y += height(VERTEX.xz, TIME); // sample the height at the location of our vertex
	TANGENT = normalize(vec3(0.0, height(VERTEX.xz + vec2(0.0, 0.2), TIME) - height(VERTEX.xz + vec2(0.0, -0.2), TIME), 0.4));
	BINORMAL = normalize(vec3(0.4, height(VERTEX.xz + vec2(0.2, 0.0), TIME) - height(VERTEX.xz + vec2(-0.2, 0.0), TIME ), 0.0));
	NORMAL = cross(TANGENT, BINORMAL);
}

void fragment() {
	vec2 base_uv_offset = UV * uv_offset_scale; // Determine the UV that we use to look up our DuDv
	base_uv_offset += TIME * uv_offset_time_scale;
	
	vec2 texture_based_offset = texture(uv_offset_texture, base_uv_offset).rg; // Get our offset
	texture_based_offset = texture_based_offset * 2.0 - 1.0; // Convert from 0.0 <=> 1.0 to -1.0 <=> 1.0
	
	vec2 texture_uv = UV * texture_scale;
	texture_uv += uv_offset_amplitude * texture_based_offset;
	ALBEDO = texture(texturemap, texture_uv).rgb * 0.5;
	METALLIC = 0.0;
	ROUGHNESS = 0.5;
	NORMALMAP = texture(normalmap, base_uv_offset).rgb;
	NORMALMAP_DEPTH = 0.2;
	
	if (ALBEDO.r > 0.9 && ALBEDO.g > 0.9 && ALBEDO.b > 0.9) {
		ALPHA = 0.9;
	} else {
		// sample our depth buffer
		float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
		
		// grab to values
		//depth = depth * 50.0 - 49.0;
		
		// unproject depth
		depth = depth * 2.0 - 1.0;
		float z = -PROJECTION_MATRIX[3][2] / (depth + PROJECTION_MATRIX[2][2]);
		// float x = (SCREEN_UV.x * 2.0 - 1.0) * z / PROJECTION_MATRIX[0][0];
		// float y = (SCREEN_UV.y * 2.0 - 1.0) * z / PROJECTION_MATRIX[1][1];
		float delta = -(z - VERTEX.z); // z is negative.
		// delta *= 0.1;
		
		// beers law
		float att = exp(-delta * beer_factor);
		
		ALPHA = clamp(1.0 - att, 0.0, 1.0);
	}
	
	vec3 ref_normal = normalize( mix(NORMAL,TANGENT * NORMALMAP.x + BINORMAL * NORMALMAP.y + NORMAL * NORMALMAP.z,NORMALMAP_DEPTH) );
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction;
	EMISSION += textureLod(SCREEN_TEXTURE,ref_ofs,ROUGHNESS * 2.0).rgb * (1.0 - ALPHA);
	
	ALBEDO *= ALPHA;
	ALPHA = 1.0;
}