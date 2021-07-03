// cloudy skies shader
// inspired from shadertoy shader made by Drift (https://www.shadertoy.com/view/4tdSWr) 

shader_type spatial;

render_mode cull_disabled, vertex_lighting;
uniform float proximity_fade_distance = 0.1;
uniform float distance_fade = 0.5;

uniform float cloudscale = 1.1;
uniform float speed = 0.01;
uniform float clouddark = 0.5;
uniform float cloudlight = 0.3;
uniform float cloudcover = 0.2;
uniform float cloudalpha = 8.0;
uniform float skytint = 0.5;
uniform mat2 m = mat2(vec2(1.6,1.2),vec2(-1.2,1.6)); // changement

// functions

vec2 hash( vec2 p ) {
                p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
                return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p ) {
    float K1 = 0.366025404; // (sqrt(3)-1)/2;
    float K2 = 0.211324865; // (3-sqrt(3))/6;
                vec2 i = floor(p + (p.x+p.y)*K1); 
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0); //vec2 of = 0.5 + 0.5*vec2(sign(a.x-a.y), sign(a.y-a.x));
    vec2 b = a - o + K2;
                vec2 c = a - 1.0 + 2.0*K2;
    vec3 h = max(0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
                vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot(n, vec3(70.0));       
}

float fbm(vec2 n) {
                float total = 0.0, amplitude = 0.1;
                for (int i = 0; i < 7; i++) {
                               total += noise(n) * amplitude;
                               n = m * n;
                               amplitude *= 0.4;
                }
                return total;
}

uniform float adjust_distorsion = 100;
varying vec2 tex_position;
void vertex() {
	//tex_position = VERTEX.xy;
	tex_position = vec2(atan(  VERTEX.x / (( VERTEX.z))  ),VERTEX.y / (abs(VERTEX.z) + adjust_distorsion) );
	if (VERTEX.z < 0.0){
		tex_position.x *= -1.0;
	}
	
}



void fragment() {
	float dist = distance((CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz, CAMERA_MATRIX[3].xyz) * distance_fade;
	ALPHA *= clamp(dist ,0.0,1.0);
	
	
vec2 res = vec2(1,1); // SCREEN_PIXEL_SIZE;
vec2 p = tex_position; // changement
                vec2 uv = p*vec2(res.x/res.y,1.0);    // changement
    float time = TIME * speed ;
    float q = fbm(uv * cloudscale * 0.5);
    
    //ridged noise shape
                float r = 0.0;
                uv *= cloudscale;
    uv += q - time;
    float weight = 0.8;
    for (int i=0; i<8; i++){
                               r += abs(weight*noise( uv ));
        uv = m*uv + time;
                               weight *= 0.7;
    }
    
    //noise shape
                float f = 0.0;
    uv = p*vec2(res.x/res.y,1.0); // changement
                uv *= cloudscale;
    uv += q - time;
    weight = 0.7;
    for (int i=0; i<8; i++){
                               f += weight*noise( uv );
        uv = m*uv + time;
                               weight *= 0.6;
    }
    
    f *= r + f;
    
    //noise colour
    float c = 0.0;
    time = TIME * speed * 2.0;
    uv = p*vec2(res.x/res.y,1.0); // changement
                uv *= cloudscale*2.0;
    uv += q - time;
    weight = 0.4;
    for (int i=0; i<7; i++){
                               c += weight*noise( uv );
        uv = m*uv + time;
                               weight *= 0.6;
    }
    
    //noise ridge colour
    float c1 = 0.0;
    time = TIME * speed * 3.0;
    uv = p*vec2(res.x/res.y,1.0);
                uv *= cloudscale*3.0;
    uv += q - time;
    weight = 0.4;
    for (int i=0; i<7; i++){
                               c1 += abs(weight*noise( uv ));
        uv = m*uv + time;
                               weight *= 0.6;
    }
                
    c += c1;
    
    vec4 skycolour = vec4(1,1,1,0); //mix(skycolour2, skycolour1, p.y);
    vec4 cloudcolour = vec4(1.1, 1.1, 0.9,1) * clamp((clouddark + cloudlight*c), 0.0, 1.0);
   
    f = cloudcover + cloudalpha*f*r;
    
    vec4 result = mix(skycolour, clamp(skytint * skycolour + cloudcolour, 0.0, 1.0), clamp(f + c, 0.0, 1.0));
    
    ALBEDO = vec3(result.xyz); 
	ALPHA *= result.a;
	
	//Proximity fade
	if (dist < 200.0){
	float depth_tex = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex * 2.0 - 1.0, 1.0);
	world_pos.xyz /= world_pos.a;
	ALPHA *= clamp(1.0 - smoothstep(world_pos.z + proximity_fade_distance, world_pos.z, VERTEX.z), 0.0, 1.0);
	}
	
}
