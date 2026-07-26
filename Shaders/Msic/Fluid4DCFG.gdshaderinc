//shader_type canvas_item;

/*
https://godotshaders.com/shader/planet-coffee/
Gerardo LCDF	December 16, 2025

This shader generates a dynamic planetary map using a sophisticated 
4D Smooth Noise algorithm. The primary advantage of this method is 
the creation of a perfect equirectangular texture, ensuring there 
are no visible seams or “pinching” at the poles when applied to a 
sphere or used as an environment map.

The visual effect is deeply inspired by fluid dynamics—resembling 
the organic movement of coffee mixing with milk—and utilizes Fractal 
Brownian Motion (FBM) combined with domain warping. The 4D noise 
llows the pattern to evolve fluidly over time without needing to 
physically shift coordinates, preserving the integrity of the 
spherical projection.
*/

//uniform vec3 colorA : source_color = vec3(0.2, 0.0, 0.1);
//uniform vec3 colorB : source_color = vec3(0.7, 0.3, 0.4);
//uniform vec3 colorC : source_color = vec3(1.0, 0.2, 0.4);

//uniform float noise_scale : hint_range(0.01, 20.0) = 5.0;
//uniform float noise_detail : hint_range(0.0, 15.0) = 10.0;
//uniform float noise_roughness : hint_range(0.0, 1.0) = 0.5;
//uniform float noise_distortion : hint_range(0.0, 20.0) = 5.0;

//uniform float W = 0.;

//#define iTime (TIME * speed)
//#define iTime (W)

float rand(vec4 p) {
    return fract(sin(p.x*1234. + p.y*2345. + p.z*3456. + p.w*4567.) * 5678.);
}

float smoothnoise(vec4 p) {
    const vec2 e = vec2(0.0, 1.0);
    vec4 i = floor(p);    // integer
    vec4 f = fract(p);    // fract
    
    f = f*f*(3. - 2.*f);
    
    return mix(mix(mix(mix(rand(i + e.xxxx),
                           rand(i + e.yxxx), f.x),
                       mix(rand(i + e.xyxx),
                           rand(i + e.yyxx), f.x), f.y),
                   mix(mix(rand(i + e.xxyx),
                           rand(i + e.yxyx), f.x),
                       mix(rand(i + e.xyyx),
                           rand(i + e.yyyx), f.x), f.y), f.z),
               mix(mix(mix(rand(i + e.xxxy),
                           rand(i + e.yxxy), f.x),
                       mix(rand(i + e.xyxy),
                           rand(i + e.yyxy), f.x), f.y),
                   mix(mix(rand(i + e.xxyy),
                           rand(i + e.yxyy), f.x),
                       mix(rand(i + e.xyyy),
                           rand(i + e.yyyy), f.x), f.y), f.z), f.w);
}

float fbm(vec3 x, float iTime, float detail, float roughness) {
    float v = 0.0;
    float a = 1.0;
    float norm = 0.0;
    vec3 shift = vec3(1.0);
    int octaves = clamp(int(ceil(detail)), 0, 15);
    for (int i = 0; i < octaves; ++i) {
        float weight = clamp(detail - float(i), 0.0, 1.0);
        v += a * weight * smoothnoise(vec4(x, cos(iTime * 0.002) * 200.0));
        norm += a * weight;
        x = x * 2.0 + shift;
        a *= roughness;
    }
    return norm > 0.0 ? v / norm : 0.0;
}

float max3 (vec3 v) {
  return max (max (v.x, v.y), v.z);
}

vec4 FluidNoise4D(vec3 pos, float iTime, vec3 colorA, vec3 colorB, vec3 colorC, float scale, float detail, float roughness, float distortion) {
    vec3 col_a = colorA;
    vec3 col_b = colorB;
    vec3 col_c = colorC;

    pos *= scale;

    pos.y += sin(iTime / 5.0);
    pos.x += cos(iTime / 5.0);
    pos.z += sin(iTime / 5.0);

    float fbmm = fbm(pos, iTime, detail, roughness);
    vec3 q = vec3(fbmm, sin(fbmm), cos(fbmm));
    vec3 r = vec3(fbmm, sin(fbmm), cos(fbmm));
    float v = fbm(pos + distortion * r + iTime * 0.005, iTime, detail, roughness);
    
    vec3 col_top = vec3(1.0);
    vec3 col_bot = vec3(0.0);
    
    vec3 res_color = mix(col_a, col_b, clamp(r, 0.0, 1.0));
    res_color = mix(res_color, col_c, clamp(q, 0.0, 1.0));
    
    float poss = v * 2.0 - 1.0;
    res_color = mix(res_color, col_top, clamp(poss, 0.0, 1.0));
    res_color = mix(res_color, col_bot, clamp(-poss, 0.0, 1.0));
    
    res_color = res_color / max(max3(res_color), 0.001);
    
    res_color = (clamp((0.4 * pow(v, 3.0) + pow(v, 2.0) + 0.5 * v), 0.0, 1.0) * 0.9 + 0.1) * res_color;

    return vec4(res_color, 1.0);
}