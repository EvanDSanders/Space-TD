// https://godotshaders.com/snippet/fractal-brownian-motion-fbm/
float random(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

float noise(vec3 uv) {
    vec3 uv_index = floor(uv);
    vec3 uv_fract = fract(uv);

    // Eight corners of a 3D cell
    float a = random(uv_index);
    float b = random(uv_index + vec3(1.0, 0.0, 0.0));
    float c = random(uv_index + vec3(0.0, 1.0, 0.0));
    float d = random(uv_index + vec3(1.0, 1.0, 0.0));
    float e = random(uv_index + vec3(0.0, 0.0, 1.0));
    float f = random(uv_index + vec3(1.0, 0.0, 1.0));
    float g = random(uv_index + vec3(0.0, 1.0, 1.0));
    float h = random(uv_index + vec3(1.0, 1.0, 1.0));

    vec3 blur = smoothstep(0.0, 1.0, uv_fract);

    float i1 = mix(a, b, blur.x);
    float i2 = mix(c, d, blur.x);
    float i3 = mix(e, f, blur.x);
    float i4 = mix(g, h, blur.x);
    float j1 = mix(i1, i2, blur.y);
    float j2 = mix(i3, i4, blur.y);
    return mix(j1, j2, blur.z);
}

float fbm(vec3 uv) {
    int octaves = 9;
    float amplitude = .9;
    float frequency = 0.4;
	float value = 0.0;

    for(int i = 0; i < octaves; i++) {
        value += amplitude * noise(frequency * uv);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}
