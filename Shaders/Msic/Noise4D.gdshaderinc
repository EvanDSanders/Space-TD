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

Noise core rewritten to match Blender's Noise Texture node: real
gradient (Perlin) noise via the Jenkins lookup3 hash, quintic fade,
and fBM normalized the same way Cycles/EEVEE do it (lacunarity 2.0,
normalize = true), instead of hashed-value noise with ad-hoc weights.
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



uint rot_l(uint x, uint k) {
	return (x << k) | (x >> (32u - k));
}

// Jenkins lookup3 hash (http://burtleburtle.net/bob/c/lookup3.c), the same
// hash Blender's GPU/Cycles Perlin noise uses to seed lattice gradients.
uint hash_uint4(uint kx, uint ky, uint kz, uint kw) {
	uint a = 3735928559u + 29u; // 0xdeadbeef + (4 << 2) + 13
	uint b = a;
	uint c = a;

	a += kx; b += ky; c += kz;

	a -= c; a ^= rot_l(c, 4u);  c += b;
	b -= a; b ^= rot_l(a, 6u);  a += c;
	c -= b; c ^= rot_l(b, 8u);  b += a;
	a -= c; a ^= rot_l(c, 16u); c += b;
	b -= a; b ^= rot_l(a, 19u); a += c;
	c -= b; c ^= rot_l(b, 4u);  b += a;

	a += kw;

	c ^= b; c -= rot_l(b, 14u);
	a ^= c; a -= rot_l(c, 11u);
	b ^= a; b -= rot_l(a, 25u);
	c ^= b; c -= rot_l(b, 16u);
	a ^= c; a -= rot_l(c, 4u);
	b ^= a; b -= rot_l(a, 14u);
	c ^= b; c -= rot_l(b, 24u);

	return c;
}

uint hash_int4(int x, int y, int z, int w) {
	return hash_uint4(uint(x), uint(y), uint(z), uint(w));
}

float negate_if(float value, uint cond) {
	return cond != 0u ? -value : value;
}

// Same gradient-selection scheme as Blender's noise_grad() for 4D.
float noise_grad(uint hash, float x, float y, float z, float w) {
	uint h = hash & 31u;
	float u = h < 24u ? x : y;
	float v = h < 16u ? y : z;
	float s = h < 8u ? z : w;
	return negate_if(u, h & 1u) + negate_if(v, h & 2u) + negate_if(s, h & 4u);
}

float fade(float t) {
	return t*t*t*(t*(t*6.0 - 15.0) + 10.0);
}

void floorfrac(float x, out int i, out float f) {
	float fl = floor(x);
	i = int(fl);
	f = x - fl;
}

// Real (gradient) Perlin noise, quadrilinearly interpolated across the 16
// corners of the enclosing 4D cell. Same layout as Blender's noise_perlin(),
// range is approximately [-1, 1] before the fixed scale below.
float perlin4(vec4 p) {
	int X, Y, Z, W;
	float fx, fy, fz, fw;
	floorfrac(p.x, X, fx);
	floorfrac(p.y, Y, fy);
	floorfrac(p.z, Z, fz);
	floorfrac(p.w, W, fw);

	float u = fade(fx);
	float v = fade(fy);
	float t = fade(fz);
	float s = fade(fw);

	return mix(
		mix(
			mix(mix(noise_grad(hash_int4(X,   Y,   Z,   W), fx,     fy,     fz,     fw),
					noise_grad(hash_int4(X+1, Y,   Z,   W), fx-1.0, fy,     fz,     fw), u),
				mix(noise_grad(hash_int4(X,   Y+1, Z,   W), fx,     fy-1.0, fz,     fw),
					noise_grad(hash_int4(X+1, Y+1, Z,   W), fx-1.0, fy-1.0, fz,     fw), u), v),
			mix(
				mix(noise_grad(hash_int4(X,   Y,   Z+1, W), fx,     fy,     fz-1.0, fw),
					noise_grad(hash_int4(X+1, Y,   Z+1, W), fx-1.0, fy,     fz-1.0, fw), u),
				mix(noise_grad(hash_int4(X,   Y+1, Z+1, W), fx,     fy-1.0, fz-1.0, fw),
					noise_grad(hash_int4(X+1, Y+1, Z+1, W), fx-1.0, fy-1.0, fz-1.0, fw), u), v), t),
		mix(
			mix(
				mix(noise_grad(hash_int4(X,   Y,   Z,   W+1), fx,     fy,     fz,     fw-1.0),
					noise_grad(hash_int4(X+1, Y,   Z,   W+1), fx-1.0, fy,     fz,     fw-1.0), u),
				mix(noise_grad(hash_int4(X,   Y+1, Z,   W+1), fx,     fy-1.0, fz,     fw-1.0),
					noise_grad(hash_int4(X+1, Y+1, Z,   W+1), fx-1.0, fy-1.0, fz,     fw-1.0), u), v),
			mix(
				mix(noise_grad(hash_int4(X,   Y,   Z+1, W+1), fx,     fy,     fz-1.0, fw-1.0),
					noise_grad(hash_int4(X+1, Y,   Z+1, W+1), fx-1.0, fy,     fz-1.0, fw-1.0), u),
				mix(noise_grad(hash_int4(X,   Y+1, Z+1, W+1), fx,     fy-1.0, fz-1.0, fw-1.0),
					noise_grad(hash_int4(X+1, Y+1, Z+1, W+1), fx-1.0, fy-1.0, fz-1.0, fw-1.0), u), v), t),
		s);
}

// Signed noise remapped to [-1, 1]; 0.8344 is the same fixed rescale OSL/Blender
// use for their 4D Perlin so the amplitude matches across octaves.
float snoise4(vec4 p) {
	return 0.8344 * perlin4(p);
}

// Fractal Brownian Motion, matching Blender's Noise Texture node with its
// default Lacunarity (2.0) and Normalize (on): result lands in [0, 1].
float fbm(vec4 p, float detail, float roughness) {
	detail = clamp(detail, 0.0, 15.0);
	float sum = 0.0;
	float amp = 1.0;
	float maxamp = 0.0;

	for (int i = 0; i <= int(detail); ++i) {
		sum += snoise4(p) * amp;
		maxamp += amp;
		amp *= roughness;
		p *= 2.0;
	}

	float rmd = detail - floor(detail);
	if (rmd != 0.0) {
		float sum2 = sum + snoise4(p) * amp;
		return mix(0.5 * sum / maxamp + 0.5, 0.5 * sum2 / (maxamp + amp) + 0.5, rmd);
	}
	return 0.5 * sum / maxamp + 0.5;
}

// Float output, same as Blender Noise Texture node's "Fac". The W axis carries
// time so the pattern evolves without shifting X/Y/Z, same idea as Blender's
// own W socket on 4D noise.
float Noise4Df(vec3 pos, float iTime, float scale, float detail, float roughness, float distortion) {
	vec4 p = vec4(pos * scale, cos(iTime * 0.002) * 200.0);

	// Same pre-warp Blender's Noise Texture node applies before the fBM:
	// offset the sample point by noise instead of feeding fBM's own output
	// back into itself.
	if (distortion != 0.0) {
		p += distortion * vec4(snoise4(p + vec4(102.5, 138.2, 155.9, 191.3)),
								snoise4(p + vec4(112.8, 176.4, 121.6, 147.7)),
								snoise4(p + vec4(163.1, 109.6, 184.3, 132.9)),
								snoise4(p + vec4(127.4, 159.8, 143.5, 118.2)));
	}

	return fbm(p, detail, roughness);
}

// vec3 output, same idea as Blender Noise Texture node's "Color": each channel
// resamples the same (already distorted) field at a fixed offset, so the
// channels are decorrelated instead of just repeating Fac 3x.
vec3 Noise4Dc(vec3 pos, float iTime, float scale, float detail, float roughness, float distortion) {
	vec4 p = vec4(pos * scale, cos(iTime * 0.002) * 200.0);

	if (distortion != 0.0) {
		p += distortion * vec4(snoise4(p + vec4(102.5, 138.2, 155.9, 191.3)),
								snoise4(p + vec4(112.8, 176.4, 121.6, 147.7)),
								snoise4(p + vec4(163.1, 109.6, 184.3, 132.9)),
								snoise4(p + vec4(127.4, 159.8, 143.5, 118.2)));
	}

	float r = fbm(p, detail, roughness);
	float g = fbm(p + vec4(174.2, 125.7, 148.3, 162.1), detail, roughness);
	float b = fbm(p + vec4(136.9, 183.4, 117.5, 151.6), detail, roughness);

	return vec3(r, g, b);
}
