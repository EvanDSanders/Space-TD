//shader_type canvas_item;

/*
Musgrave (fractal noise) 3D, ported from Blender's GPU shader source:
source/blender/gpu/shaders/material/gpu_shader_material_fractal_noise.glsl
source/blender/gpu/shaders/material/gpu_shader_material_noise.glsl
source/blender/gpu/shaders/common/gpu_shader_common_hash.glsl

Blender's classic Musgrave Texture node was merged into the Noise Texture
node as a "Type" dropdown (Multifractal, fBM, Hybrid Multifractal, Ridged
Multifractal, Hetero Terrain) but the underlying math is unchanged. This
file reimplements the 3D case only, with all helper symbols namespaced
(mg_*) so it can be #included alongside Noise4D.gdshaderinc in the same
shader without symbol collisions.

Type indices match Blender's SHD_MUSGRAVE_* enum (DNA_node_types.h):
0 = Multifractal, 1 = fBM, 2 = Hybrid Multifractal,
3 = Ridged Multifractal, 4 = Hetero Terrain.

"normalize" is hardcoded on for fBM (matches the Noise Texture node's
default), same simplification Noise4D.gdshaderinc already makes.
*/

uint mg_rot_l(uint x, uint k) {
    return (x << k) | (x >> (32u - k));
}

// Jenkins lookup3 hash, 3-input case (no "mix" round, only "final").
uint mg_hash_uint3(uint kx, uint ky, uint kz) {
    uint a = 3735928559u + 12u + 13u; // 0xdeadbeef + (3 << 2) + 13
    uint b = a;
    uint c = a;

    a += kx; b += ky; c += kz;

    c ^= b; c -= mg_rot_l(b, 14u);
    a ^= c; a -= mg_rot_l(c, 11u);
    b ^= a; b -= mg_rot_l(a, 25u);
    c ^= b; c -= mg_rot_l(b, 16u);
    a ^= c; a -= mg_rot_l(c, 4u);
    b ^= a; b -= mg_rot_l(a, 14u);
    c ^= b; c -= mg_rot_l(b, 24u);

    return c;
}

uint mg_hash_int3(int x, int y, int z) {
    return mg_hash_uint3(uint(x), uint(y), uint(z));
}

float mg_negate_if(float value, uint cond) {
    return cond != 0u ? -value : value;
}

// Blender's noise_grad() for 3D — different bit layout than the 4D version.
float mg_noise_grad3(uint hash, float x, float y, float z) {
    uint h = hash & 15u;
    float u = h < 8u ? x : y;
    float vt = ((h == 12u) || (h == 14u)) ? x : z;
    float v = h < 4u ? y : vt;
    return mg_negate_if(u, h & 1u) + mg_negate_if(v, h & 2u);
}

float mg_fade(float t) {
    return t*t*t*(t*(t*6.0 - 15.0) + 10.0);
}

void mg_floorfrac(float x, out int i, out float f) {
    float fl = floor(x);
    i = int(fl);
    f = x - fl;
}

// Real (gradient) Perlin noise, trilinearly interpolated across the 8
// corners of the enclosing 3D cell. Range is approximately [-1, 1].
float mg_perlin3(vec3 p) {
    int X, Y, Z;
    float fx, fy, fz;
    mg_floorfrac(p.x, X, fx);
    mg_floorfrac(p.y, Y, fy);
    mg_floorfrac(p.z, Z, fz);

    float u = mg_fade(fx);
    float v = mg_fade(fy);
    float w = mg_fade(fz);

    return mix(
        mix(
            mix(mg_noise_grad3(mg_hash_int3(X,   Y,   Z),   fx,     fy,     fz),
                mg_noise_grad3(mg_hash_int3(X+1, Y,   Z),   fx-1.0, fy,     fz), u),
            mix(mg_noise_grad3(mg_hash_int3(X,   Y+1, Z),   fx,     fy-1.0, fz),
                mg_noise_grad3(mg_hash_int3(X+1, Y+1, Z),   fx-1.0, fy-1.0, fz), u), v),
        mix(
            mix(mg_noise_grad3(mg_hash_int3(X,   Y,   Z+1), fx,     fy,     fz-1.0),
                mg_noise_grad3(mg_hash_int3(X+1, Y,   Z+1), fx-1.0, fy,     fz-1.0), u),
            mix(mg_noise_grad3(mg_hash_int3(X,   Y+1, Z+1), fx,     fy-1.0, fz-1.0),
                mg_noise_grad3(mg_hash_int3(X+1, Y+1, Z+1), fx-1.0, fy-1.0, fz-1.0), u), v),
        w);
}

// Signed noise, rescaled by the same 0.9820 fixed factor OSL/Blender use
// for 3D Perlin (noise_scale3).
float mg_snoise3(vec3 p) {
    return 0.9820 * mg_perlin3(p);
}

float mg_fbm3(vec3 co, float detail, float roughness, float lacunarity, float offset, float gain) {
    vec3 p = co;
    float fscale = 1.0;
    float amp = 1.0;
    float maxamp = 0.0;
    float sum = 0.0;

    for (int i = 0; i <= int(detail); i++) {
        float t = mg_snoise3(fscale * p);
        sum += t * amp;
        maxamp += amp;
        amp *= roughness;
        fscale *= lacunarity;
    }
    float rmd = detail - floor(detail);
    if (rmd != 0.0) {
        float t = mg_snoise3(fscale * p);
        float sum2 = sum + t * amp;
        return mix(0.5 * sum / maxamp + 0.5, 0.5 * sum2 / (maxamp + amp) + 0.5, rmd);
    }
    return 0.5 * sum / maxamp + 0.5;
}

float mg_multi_fractal3(vec3 co, float detail, float roughness, float lacunarity, float offset, float gain) {
    vec3 p = co;
    float value = 1.0;
    float pwr = 1.0;

    for (int i = 0; i <= int(detail); i++) {
        value *= (pwr * mg_snoise3(p) + 1.0);
        pwr *= roughness;
        p *= lacunarity;
    }

    float rmd = detail - floor(detail);
    if (rmd != 0.0) {
        value *= (rmd * pwr * mg_snoise3(p) + 1.0);
    }

    return value;
}

float mg_hetero_terrain3(vec3 co, float detail, float roughness, float lacunarity, float offset, float gain) {
    vec3 p = co;
    float pwr = roughness;

    // First unscaled octave of function; later octaves are scaled.
    float value = offset + mg_snoise3(p);
    p *= lacunarity;

    for (int i = 1; i <= int(detail); i++) {
        float increment = (mg_snoise3(p) + offset) * pwr * value;
        value += increment;
        pwr *= roughness;
        p *= lacunarity;
    }

    float rmd = detail - floor(detail);
    if (rmd != 0.0) {
        float increment = (mg_snoise3(p) + offset) * pwr * value;
        value += rmd * increment;
    }

    return value;
}

float mg_hybrid_multi_fractal3(vec3 co, float detail, float roughness, float lacunarity, float offset, float gain) {
    vec3 p = co;
    float pwr = 1.0;
    float value = 0.0;
    float weight = 1.0;

    for (int i = 0; (weight > 0.001) && (i <= int(detail)); i++) {
        if (weight > 1.0) {
            weight = 1.0;
        }

        float signal = (mg_snoise3(p) + offset) * pwr;
        pwr *= roughness;
        value += weight * signal;
        weight *= gain * signal;
        p *= lacunarity;
    }

    float rmd = detail - floor(detail);
    if ((rmd != 0.0) && (weight > 0.001)) {
        if (weight > 1.0) {
            weight = 1.0;
        }
        float signal = (mg_snoise3(p) + offset) * pwr;
        value += rmd * weight * signal;
    }

    return value;
}

float mg_ridged_multi_fractal3(vec3 co, float detail, float roughness, float lacunarity, float offset, float gain) {
    vec3 p = co;
    float pwr = roughness;

    float signal = offset - abs(mg_snoise3(p));
    signal *= signal;
    float value = signal;
    float weight = 1.0;

    for (int i = 1; i <= int(detail); i++) {
        p *= lacunarity;
        weight = clamp(signal * gain, 0.0, 1.0);
        signal = offset - abs(mg_snoise3(p));
        signal *= signal;
        signal *= weight;
        value += signal * pwr;
        pwr *= roughness;
    }

    return value;
}

// Fac output, same idea as Blender's merged Noise Texture node with a
// Musgrave "Type" selected. Type indices match SHD_MUSGRAVE_* (see header).
float Musgrave3Df(vec3 pos, float type, float scale, float detail, float roughness, float lacunarity, float offset, float gain) {
    vec3 p = pos * scale;
    detail = clamp(detail, 0.0, 15.0);
    roughness = max(roughness, 0.0);

    int t = int(round(type));
    if (t == 1) {
        return mg_fbm3(p, detail, roughness, lacunarity, offset, gain);
    } else if (t == 2) {
        return mg_hybrid_multi_fractal3(p, detail, roughness, lacunarity, offset, gain);
    } else if (t == 3) {
        return mg_ridged_multi_fractal3(p, detail, roughness, lacunarity, offset, gain);
    } else if (t == 4) {
        return mg_hetero_terrain3(p, detail, roughness, lacunarity, offset, gain);
    }
    return mg_multi_fractal3(p, detail, roughness, lacunarity, offset, gain);
}
