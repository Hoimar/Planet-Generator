shader_type spatial;

render_mode specular_schlick_ggx, cull_disabled;

uniform vec4 albedo : hint_color;
uniform float proximity_fade_distance;
uniform float planet_radius;
uniform sampler2D texture_refraction;
uniform float refraction : hint_range(-16,16);
uniform vec4 refraction_texture_channel;
uniform sampler2D texture_normal : hint_normal;

varying vec3 cam_position;

void vertex() {
	UV = UV * 750.0 + vec2(TIME + sin(TIME * 3.0) * 0.07) * 0.1;
	cam_position = MODELVIEW_MATRIX[3].xyz;
}

void fragment() {
	vec2 base_uv = UV;
	ALBEDO = albedo.rgb;
	ROUGHNESS = 0.1;
	SPECULAR = 0.7;
	NORMALMAP = texture(texture_normal, base_uv).rgb;
	NORMALMAP_DEPTH = 0.15;
	// Refraction.
	vec3 ref_normal = normalize(mix(
			NORMAL,
			TANGENT * NORMALMAP.x + BINORMAL * NORMALMAP.y + NORMAL * NORMALMAP.z,
			NORMALMAP_DEPTH));
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * 
			dot(texture(texture_refraction, base_uv), vec4(1.0, 0.0, 0.0, 0.0)) * refraction;
	float ref_amount = 1.0 - albedo.a;
	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs, ROUGHNESS * 8.0).rgb * ref_amount;
	ALBEDO *= 1.0 - ref_amount;
	
	// Proximity fade.
	float depth_tex = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
	world_pos.xyz /= world_pos.w;
	ALPHA *= clamp(1.0 - smoothstep(world_pos.z + proximity_fade_distance, world_pos.z, VERTEX.z), 0.0, 1.0);
	
	// Fade out in the distance.
	ALPHA *= clamp(smoothstep(planet_radius*3.3, planet_radius*1.7, length(cam_position)), 0.0, 1.0);
}
